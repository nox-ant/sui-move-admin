// Copyright (c) 2024
// SPDX-License-Identifier: MIT

/// Generic admin capability module for Sui Move.
/// Uses phantom generics with OTW to ensure package-level isolation.
module sui_move_admin::admin;

use sui::types;
use sui::event;
use std::type_name::{Self, TypeName};

// === Error Codes ===

/// Invalid OTW passed to create_super_admin
const ENotOneTimeWitness: u64 = 1;

/// Non-super admin attempted promotion  
const ENotSuperAdmin: u64 = 2;

/// Cap expired, cannot verify
const EAdminCapExpired: u64 = 3;

/// Amount < 1 in create_super_admin
const EInvalidAmount: u64 = 4;

/// Cannot delete super admin with delete()
const ECannotDeleteSuperAdmin: u64 = 5;

// === Constants ===

/// Super admin expires_epoch value (never expires)
const SUPER_ADMIN_EXPIRES: u64 = 18446744073709551615; // u64::MAX

// === Structs ===

/// Admin capability with phantom generic for package isolation.
/// `key` only (no `store`) - prevents generic `public_transfer`.
public struct AdminCap<phantom T> has key {
    id: UID,
    expires_epoch: u64,  // u64::MAX = super admin (never expires)
}

/// Emitted when a temp admin is promoted.
public struct AdminPromoted has copy, drop {
    cap_id: ID,
    package_type: TypeName,
    expires_epoch: u64,
}

// === Read Functions ===

/// Returns true if expires_epoch == u64::MAX.
public fun is_super_admin<T>(cap: &AdminCap<T>): bool {
    cap.expires_epoch == SUPER_ADMIN_EXPIRES
}

/// Returns the expiration epoch.
public fun expires_epoch<T>(cap: &AdminCap<T>): u64 {
    cap.expires_epoch
}

/// Returns true if cap is expired.
public fun is_expired<T>(cap: &AdminCap<T>, ctx: &TxContext): bool {
    ctx.epoch() > cap.expires_epoch
}

// === Creation ===

/// Creates super admin caps validated by OTW.
/// Returns vector for caller to distribute via transfer_admin().
public fun create_super_admin<T: drop>(
    otw: T, 
    amount: u16, 
    ctx: &mut TxContext
): vector<AdminCap<T>> {
    assert!(types::is_one_time_witness(&otw), ENotOneTimeWitness);
    assert!(amount >= 1, EInvalidAmount);
    
    let mut caps = vector::empty<AdminCap<T>>();
    let mut i: u16 = 0;
    while (i < amount) {
        caps.push_back(AdminCap<T> {
            id: object::new(ctx),
            expires_epoch: SUPER_ADMIN_EXPIRES,
        });
        i = i + 1;
    };
    caps
}

// === Transfer ===

/// Transfers cap to specified address.
/// Only owner can call (enforced by Move ownership).
public fun transfer_admin<T>(cap: AdminCap<T>, recipient: address) {
    transfer::transfer(cap, recipient);
}

// === Verification ===

/// Aborts with EAdminCapExpired if expired.
/// No-op if valid (including super admins).
public fun verify<T>(cap: &AdminCap<T>, ctx: &TxContext) {
    assert!(!is_expired(cap, ctx), EAdminCapExpired);
}

// === Promotion ===

/// Super admin promotes new temp admin.
/// epochs_valid: 0 = expires end of current epoch, 1 = end of next, etc.
public fun promote<T>(
    super_admin: &AdminCap<T>, 
    recipient: address,
    epochs_valid: u64,
    ctx: &mut TxContext
) {
    assert!(is_super_admin(super_admin), ENotSuperAdmin);
    
    let expires_epoch = ctx.epoch() + epochs_valid;
    let cap = AdminCap<T> {
        id: object::new(ctx),
        expires_epoch,
    };
    
    event::emit(AdminPromoted {
        cap_id: object::id(&cap),
        package_type: type_name::with_original_ids<T>(),
        expires_epoch,
    });
    
    transfer::transfer(cap, recipient);
}

// === Deletion ===

/// Delete any non-super-admin cap for storage reclaim.
public fun delete<T>(cap: AdminCap<T>) {
    assert!(!is_super_admin(&cap), ECannotDeleteSuperAdmin);
    let AdminCap { id, expires_epoch: _ } = cap;
    object::delete(id);
}

/// Super admins can voluntarily burn themselves.
public fun burn_super_admin<T>(cap: AdminCap<T>) {
    assert!(is_super_admin(&cap), ENotSuperAdmin);
    let AdminCap { id, expires_epoch: _ } = cap;
    object::delete(id);
}

// === Test Utilities ===

#[test_only]
public fun test_create_super_admin<T>(ctx: &mut TxContext): AdminCap<T> {
    AdminCap<T> {
        id: object::new(ctx),
        expires_epoch: SUPER_ADMIN_EXPIRES,
    }
}

#[test_only]
public fun test_create_temp_admin<T>(expires_epoch: u64, ctx: &mut TxContext): AdminCap<T> {
    AdminCap<T> {
        id: object::new(ctx),
        expires_epoch,
    }
}

#[test_only]
public fun destroy_for_testing<T>(cap: AdminCap<T>) {
    let AdminCap { id, expires_epoch: _ } = cap;
    object::delete(id);
}
