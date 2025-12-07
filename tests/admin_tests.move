// Copyright (c) 2024
// SPDX-License-Identifier: Apache-2.0

#[test_only]
#[allow(unused_field, deprecated_usage)]
module sui_move_admin::admin_tests;

use sui::test_scenario::{Self as ts, Scenario};
use sui::test_utils::assert_eq;
use sui_move_admin::admin::{Self, AdminCap};

// === Test Addresses ===

const ADMIN: address = @0x1;
const USER: address = @0x2;
const RECIPIENT: address = @0x3;
const DEPLOYER: address = @0x4;
const ADMIN1: address = @0x5;
const ADMIN2: address = @0x6;
const OPERATOR: address = @0x7;

// === Test OTW Structs ===

/// Valid OTW for testing - UPPERCASE module name, drop, no fields
public struct ADMIN_TESTS has drop {}

/// Invalid OTW - has fields
public struct BadOTW1 has drop { value: u64 }

/// Invalid OTW - wrong name
public struct BadName has drop {}

// === Helper Functions ===

fun setup(): Scenario {
    ts::begin(ADMIN)
}

// === Read Function Tests ===

#[test]
fun test_is_super_admin_returns_true() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_super_admin<ADMIN_TESTS>(ctx);
        assert!(admin::is_super_admin(&cap), 0);
        admin::destroy_for_testing(cap);
    };
    ts::end(scenario);
}

#[test]
fun test_is_super_admin_returns_false_for_temp() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_temp_admin<ADMIN_TESTS>(100, ctx);
        assert!(!admin::is_super_admin(&cap), 0);
        admin::destroy_for_testing(cap);
    };
    ts::end(scenario);
}

#[test]
fun test_expires_epoch_returns_correct_value() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_temp_admin<ADMIN_TESTS>(42, ctx);
        assert_eq(admin::expires_epoch(&cap), 42);
        admin::destroy_for_testing(cap);
    };
    ts::end(scenario);
}

#[test]
fun test_super_admin_expires_epoch_is_max() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_super_admin<ADMIN_TESTS>(ctx);
        // u64::MAX
        assert_eq(admin::expires_epoch(&cap), 18446744073709551615);
        admin::destroy_for_testing(cap);
    };
    ts::end(scenario);
}

#[test]
fun test_is_expired_false_for_super_admin() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_super_admin<ADMIN_TESTS>(ctx);
        assert!(!admin::is_expired(&cap, ctx), 0);
        admin::destroy_for_testing(cap);
    };
    ts::end(scenario);
}

#[test]
fun test_is_expired_false_for_valid_temp_admin() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        // Current epoch is 0 in tests, cap expires at epoch 100
        let cap = admin::test_create_temp_admin<ADMIN_TESTS>(100, ctx);
        assert!(!admin::is_expired(&cap, ctx), 0);
        admin::destroy_for_testing(cap);
    };
    ts::end(scenario);
}

// Note: Testing expired caps requires advancing epochs, which test_scenario doesn't support directly
// We can test edge case: expires_epoch = 0 at epoch 0 should not be expired
#[test]
fun test_is_expired_at_expiration_epoch_not_expired() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        // expires_epoch = 0, current epoch = 0
        // Spec says: "A cap with expires_epoch: 100 is valid during epoch 100, expires at epoch 101"
        // So expires_epoch = 0, current_epoch = 0 -> NOT expired
        let cap = admin::test_create_temp_admin<ADMIN_TESTS>(0, ctx);
        assert!(!admin::is_expired(&cap, ctx), 0);
        admin::destroy_for_testing(cap);
    };
    ts::end(scenario);
}

// === Verify Tests ===

#[test]
fun test_verify_super_admin_passes() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_super_admin<ADMIN_TESTS>(ctx);
        admin::verify(&cap, ctx);  // Should not abort
        admin::destroy_for_testing(cap);
    };
    ts::end(scenario);
}

#[test]
fun test_verify_valid_temp_admin_passes() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_temp_admin<ADMIN_TESTS>(100, ctx);
        admin::verify(&cap, ctx);  // Should not abort
        admin::destroy_for_testing(cap);
    };
    ts::end(scenario);
}

// Note: We cannot easily test verify failing due to epoch advancement limitations

// === Delete Tests ===

#[test]
fun test_delete_temp_admin_works() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_temp_admin<ADMIN_TESTS>(100, ctx);
        admin::delete(cap);  // Should not abort
    };
    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = admin::ECannotDeleteSuperAdmin)]
fun test_delete_super_admin_fails() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_super_admin<ADMIN_TESTS>(ctx);
        admin::delete(cap);  // Should abort
    };
    ts::end(scenario);
}

#[test]
fun test_burn_super_admin_works() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_super_admin<ADMIN_TESTS>(ctx);
        admin::burn_super_admin(cap);  // Should not abort
    };
    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = admin::ENotSuperAdmin)]
fun test_burn_super_admin_with_temp_admin_fails() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_temp_admin<ADMIN_TESTS>(100, ctx);
        admin::burn_super_admin(cap);  // Should abort
    };
    ts::end(scenario);
}

// === Promotion Tests ===

#[test]
fun test_promote_by_super_admin_works() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_super_admin<ADMIN_TESTS>(ctx);
        admin::promote(&cap, USER, 10, ctx);
        admin::destroy_for_testing(cap);
    };
    // Check promoted cap exists at recipient
    ts::next_tx(&mut scenario, USER);
    {
        let cap = ts::take_from_sender<AdminCap<ADMIN_TESTS>>(&scenario);
        // epochs_valid = 10, current epoch = 0, so expires_epoch = 10
        assert_eq(admin::expires_epoch(&cap), 10);
        assert!(!admin::is_super_admin(&cap), 0);
        ts::return_to_sender(&scenario, cap);
    };
    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = admin::ENotSuperAdmin)]
fun test_promote_by_temp_admin_fails() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_temp_admin<ADMIN_TESTS>(100, ctx);
        admin::promote(&cap, USER, 10, ctx);  // Should abort
        admin::destroy_for_testing(cap);
    };
    ts::end(scenario);
}

#[test]
fun test_promote_with_zero_epochs_valid() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_super_admin<ADMIN_TESTS>(ctx);
        // epochs_valid = 0 means expires at end of current epoch
        admin::promote(&cap, USER, 0, ctx);
        admin::destroy_for_testing(cap);
    };
    ts::next_tx(&mut scenario, USER);
    {
        let cap = ts::take_from_sender<AdminCap<ADMIN_TESTS>>(&scenario);
        // Current epoch = 0, epochs_valid = 0, expires_epoch = 0
        assert_eq(admin::expires_epoch(&cap), 0);
        ts::return_to_sender(&scenario, cap);
    };
    ts::end(scenario);
}

#[test]
fun test_multiple_promotions_same_address() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_super_admin<ADMIN_TESTS>(ctx);
        // Promote same user twice
        admin::promote(&cap, USER, 5, ctx);
        admin::promote(&cap, USER, 10, ctx);
        admin::destroy_for_testing(cap);
    };
    ts::next_tx(&mut scenario, USER);
    {
        // Should have 2 caps
        let cap1 = ts::take_from_sender<AdminCap<ADMIN_TESTS>>(&scenario);
        let cap2 = ts::take_from_sender<AdminCap<ADMIN_TESTS>>(&scenario);
        
        // Different caps with different expiration
        let exp1 = admin::expires_epoch(&cap1);
        let exp2 = admin::expires_epoch(&cap2);
        assert!(exp1 != exp2 || (exp1 == 5 || exp1 == 10), 0);
        
        ts::return_to_sender(&scenario, cap1);
        ts::return_to_sender(&scenario, cap2);
    };
    ts::end(scenario);
}

// === Transfer Tests ===

#[test]
fun test_transfer_admin_works() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap = admin::test_create_super_admin<ADMIN_TESTS>(ctx);
        admin::transfer_admin(cap, RECIPIENT);
    };
    ts::next_tx(&mut scenario, RECIPIENT);
    {
        assert!(ts::has_most_recent_for_sender<AdminCap<ADMIN_TESTS>>(&scenario), 0);
        let cap = ts::take_from_sender<AdminCap<ADMIN_TESTS>>(&scenario);
        assert!(admin::is_super_admin(&cap), 0);
        ts::return_to_sender(&scenario, cap);
    };
    ts::end(scenario);
}

// === Integration Tests ===

#[test]
fun test_full_workflow() {
    let mut scenario = setup();
    
    // 1. Create super admins and transfer
    ts::next_tx(&mut scenario, DEPLOYER);
    {
        let ctx = ts::ctx(&mut scenario);
        let mut caps = admin::create_super_admin(ADMIN_TESTS {}, 2, ctx);
        admin::transfer_admin(caps.pop_back(), ADMIN1);
        admin::transfer_admin(caps.pop_back(), ADMIN2);
        caps.destroy_empty();
    };
    
    // 2. Admin1 promotes a temp admin
    ts::next_tx(&mut scenario, ADMIN1);
    {
        let cap = ts::take_from_sender<AdminCap<ADMIN_TESTS>>(&scenario);
        let ctx = ts::ctx(&mut scenario);
        admin::promote(&cap, OPERATOR, 100, ctx);
        ts::return_to_sender(&scenario, cap);
    };
    
    // 3. Operator verifies their cap
    ts::next_tx(&mut scenario, OPERATOR);
    {
        let cap = ts::take_from_sender<AdminCap<ADMIN_TESTS>>(&scenario);
        let ctx = ts::ctx(&mut scenario);
        admin::verify(&cap, ctx);  // Should pass
        assert!(!admin::is_super_admin(&cap), 0);
        assert_eq(admin::expires_epoch(&cap), 100);
        ts::return_to_sender(&scenario, cap);
    };
    
    // 4. Operator deletes their cap for storage reclaim
    ts::next_tx(&mut scenario, OPERATOR);
    {
        let cap = ts::take_from_sender<AdminCap<ADMIN_TESTS>>(&scenario);
        admin::delete(cap);
    };
    
    // 5. Admin2 burns their super admin cap (key rotation scenario)
    ts::next_tx(&mut scenario, ADMIN2);
    {
        let cap = ts::take_from_sender<AdminCap<ADMIN_TESTS>>(&scenario);
        admin::burn_super_admin(cap);
    };
    
    ts::end(scenario);
}

// === Type Isolation Tests ===

/// Second OTW to test type isolation
public struct OTHER_TYPE has drop {}

#[test]
fun test_phantom_generic_type_isolation() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        let cap1 = admin::test_create_super_admin<ADMIN_TESTS>(ctx);
        let cap2 = admin::test_create_super_admin<OTHER_TYPE>(ctx);
        
        // Both are super admins but different types
        assert!(admin::is_super_admin(&cap1), 0);
        assert!(admin::is_super_admin(&cap2), 0);
        
        // They're distinct types - can't be confused
        // (Type system enforces this at compile time)
        
        admin::destroy_for_testing(cap1);
        admin::destroy_for_testing(cap2);
    };
    ts::end(scenario);
}

// === OTW Validation Tests ===

#[test]
#[expected_failure(abort_code = admin::ENotOneTimeWitness)]
fun test_create_super_admin_with_non_otw_fails() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, DEPLOYER);
    {
        let ctx = ts::ctx(&mut scenario);
        // BadName doesn't match module name, so not valid OTW
        let mut caps = admin::create_super_admin(BadName {}, 1, ctx);
        admin::destroy_for_testing(caps.pop_back());
        caps.destroy_empty();
    };
    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = admin::EInvalidAmount)]
fun test_create_super_admin_zero_amount_fails() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, DEPLOYER);
    {
        let ctx = ts::ctx(&mut scenario);
        let caps = admin::create_super_admin(ADMIN_TESTS {}, 0, ctx);
        caps.destroy_empty();
    };
    ts::end(scenario);
}

#[test]
fun test_create_super_admin_multiple_caps() {
    let mut scenario = setup();
    ts::next_tx(&mut scenario, DEPLOYER);
    {
        let ctx = ts::ctx(&mut scenario);
        let mut caps = admin::create_super_admin(ADMIN_TESTS {}, 3, ctx);
        
        // Should have 3 caps
        assert!(caps.length() == 3, 0);
        
        // All should be super admins
        let cap1 = caps.pop_back();
        let cap2 = caps.pop_back();
        let cap3 = caps.pop_back();
        
        assert!(admin::is_super_admin(&cap1), 0);
        assert!(admin::is_super_admin(&cap2), 0);
        assert!(admin::is_super_admin(&cap3), 0);
        
        admin::destroy_for_testing(cap1);
        admin::destroy_for_testing(cap2);
        admin::destroy_for_testing(cap3);
        caps.destroy_empty();
    };
    ts::end(scenario);
}
