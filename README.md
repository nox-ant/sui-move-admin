<p align="center">
  <img src="assets/banner.jpg" alt="sui-move-admin banner" width="100%">
</p>

<h1 align="center">sui-move-admin</h1>

<p align="center">
  <strong>Generic admin capability module for Sui Move. Deploy once, import anywhere.</strong>
</p>

---

## Quick Start

**1. Add dependency:**
```toml
# Move.toml
[dependencies]
SuiMoveAdmin = { git = "https://github.com/nox-ant/sui-move-admin.git", rev = "main" }
```

**2. Use in your module:**
```move
module my_package::my_module;

use sui_move_admin::admin::{Self, AdminCap};

public struct MY_MODULE has drop {}

fun init(otw: MY_MODULE, ctx: &mut TxContext) {
    let mut super_admins = admin::create_super_admin(otw, 2, ctx);
    
    admin::transfer_admin(super_admins.pop_back(), @cold_wallet);
    admin::transfer_admin(super_admins.pop_back(), @hot_wallet);
    super_admins.destroy_empty();
}

public fun admin_only(cap: &AdminCap<MY_MODULE>, ctx: &TxContext) {
    admin::verify(cap, ctx);  // Aborts if expired
    // ... privileged logic
}
```

---

## Why sui-move-admin?

| Feature | Benefit |
|---------|---------|
| **Phantom generics** | Your `AdminCap<MY_MODULE>` is distinct from everyone else's |
| **Epoch-based expiration** | Temp admins auto-expire, no cleanup needed |
| **No `store` ability** | Caps can't be transferred by arbitrary contracts |
| **Import, don't deploy** | One audited module for the ecosystem |

---

## Core API

### Create Super Admins
```move
public fun create_super_admin<T: drop>(
    otw: T, 
    amount: u16, 
    ctx: &mut TxContext
): vector<AdminCap<T>>
```
Call in `init()` with your OTW. Returns super admins that never expire.

### Transfer
```move
public fun transfer_admin<T>(cap: AdminCap<T>, recipient: address)
```
Owner-controlled transfer. Works for both super and temp admins.

### Promote Temp Admins
```move
public fun promote<T>(
    super_admin: &AdminCap<T>, 
    recipient: address,
    epochs_valid: u64,
    ctx: &mut TxContext
)
```
Super admins can create time-limited temp admins.

### Verify
```move
public fun verify<T>(cap: &AdminCap<T>, ctx: &TxContext)
```
Aborts if cap is expired. Call before privileged operations.

### Delete
```move
public fun delete<T>(cap: AdminCap<T>)           // Temp admins
public fun burn_super_admin<T>(cap: AdminCap<T>) // Super admins (irreversible)
```

### Query
```move
public fun is_expired<T>(cap: &AdminCap<T>, ctx: &TxContext): bool
public fun is_super_admin<T>(cap: &AdminCap<T>): bool
public fun expires_epoch<T>(cap: &AdminCap<T>): u64
```

---

## Error Codes

| Code | Name | Cause |
|------|------|-------|
| 1 | `ENotOneTimeWitness` | Invalid OTW in `create_super_admin` |
| 2 | `ENotSuperAdmin` | Temp admin tried to promote |
| 3 | `EAdminCapExpired` | `verify()` called on expired cap |
| 4 | `EInvalidAmount` | `amount < 1` in `create_super_admin` |

---

## Advanced Usage

### Multi-Sig Setup
```move
fun init(otw: MY_MODULE, ctx: &mut TxContext) {
    let mut admins = admin::create_super_admin(otw, 3, ctx);
    
    // Distribute to multisig participants
    admin::transfer_admin(admins.pop_back(), @multisig_1);
    admin::transfer_admin(admins.pop_back(), @multisig_2);
    admin::transfer_admin(admins.pop_back(), @multisig_3);
    admins.destroy_empty();
}
```

### Temporary Access
```move
public fun grant_temp_access(
    super: &AdminCap<MY_MODULE>,
    contractor: address,
    ctx: &mut TxContext
) {
    admin::verify(super, ctx);
    admin::promote(super, contractor, 30, ctx);  // 30 epochs
}
```

### Key Rotation
```move
public fun rotate_key(
    old_cap: AdminCap<MY_MODULE>,
    new_wallet: address,
    ctx: &TxContext
) {
    admin::verify(&old_cap, ctx);
    admin::transfer_admin(old_cap, new_wallet);
}
```

---

## Test Utilities

```move
#[test_only]
public fun test_create_super_admin<T>(ctx: &mut TxContext): AdminCap<T>

#[test_only]  
public fun test_create_temp_admin<T>(expires_epoch: u64, ctx: &mut TxContext): AdminCap<T>
```

---

## Design Philosophy

- **Immutable deployment** — Publish without `UpgradeCap` for maximum trust
- **No recovery** — Lost keys = lost access. Use multisig.
- **Minimal events** — Only `AdminPromoted`. Use Sui's object lifecycle for the rest.
- **No global freeze** — Implement freeze logic in your module if needed.

---

## License

Apache-2.0
