<p align="center">
  <img src="assets/banner.jpg" alt="sui-move-admin banner" width="100%">
</p>
<h1 align="center">sui-move-admin</h1>
<p align="center">
  <img src="https://img.shields.io/badge/Sui-4DA2FF?style=for-the-badge&logo=sui&logoColor=white" />
  <img src="https://img.shields.io/badge/Move-8B5CF6?style=for-the-badge&logo=move&logoColor=white" />
  <img src="https://img.shields.io/badge/Apache--2.0-D22128?style=for-the-badge&logo=apache&logoColor=white" />
</p>

---

```toml
# Move.toml
[dependencies]
SuiMoveAdmin = { git = "https://github.com/nox-ant/sui-move-admin.git", rev = "main" }
```

```move
use sui_move_admin::admin::{Self, AdminCap};
```

*Generic admin capability module for Sui Move. Deploy once, import anywhere.*

## Features

- 🛡️ Phantom generics with OTW for package-level isolation
- ⏰ Epoch-based expiration for temp admins
- 🔄 Super admins can promote temp admins
- 🔐 Owner-controlled transfers (no `store` ability)
- 🧹 Self-delete for storage reclaim

## Quick Start

```move
module my_package::my_module;

use sui_move_admin::admin::{Self, AdminCap};

/// OTW must be UPPERCASE module name with `drop` ability
public struct MY_MODULE has drop {}

fun init(otw: MY_MODULE, ctx: &mut TxContext) {
    // Create 2 super admins for redundancy
    let mut caps = admin::create_super_admin(otw, 2, ctx);
    
    admin::transfer_admin(caps.pop_back(), @0xADMIN_WALLET_1);
    admin::transfer_admin(caps.pop_back(), @0xADMIN_WALLET_2);
    caps.destroy_empty();
}

/// Gate any function with admin verification
public fun admin_action(cap: &AdminCap<MY_MODULE>, ctx: &TxContext) {
    admin::verify(cap, ctx);  // Aborts if expired
    // ... privileged logic
}

/// Super admins can grant temporary access
public fun grant_temp_access(
    super_cap: &AdminCap<MY_MODULE>,
    recipient: address,
    ctx: &mut TxContext
) {
    admin::verify(super_cap, ctx);
    admin::promote(super_cap, recipient, 30, ctx); // Valid for 30 epochs
}
```

## API

| Function | Description |
|----------|-------------|
| `create_super_admin<T>(otw, amount, ctx)` | Create super admin caps (requires valid OTW) |
| `transfer_admin<T>(cap, recipient)` | Transfer cap to address |
| `promote<T>(super_cap, recipient, epochs_valid, ctx)` | Create temp admin |
| `verify<T>(cap, ctx)` | Abort if cap expired |
| `delete<T>(cap)` | Delete temp admin cap |
| `burn_super_admin<T>(cap)` | Permanently burn super admin |
| `is_super_admin<T>(cap)` | Check if cap is super admin |
| `is_expired<T>(cap, ctx)` | Check if cap is expired |
| `expires_epoch<T>(cap)` | Get expiration epoch |

## Type Safety

```
AdminCap<0xabc::foo::FOO> ≠ AdminCap<0xdef::foo::FOO>
```

Package address is part of type identity. Collision impossible.

## Error Codes

| Code | Constant | Trigger |
|------|----------|---------|
| 1 | `ENotOneTimeWitness` | Invalid OTW |
| 2 | `ENotSuperAdmin` | Temp admin tried to promote |
| 3 | `EAdminCapExpired` | Cap expired on verify |
| 4 | `EInvalidAmount` | Amount < 1 |
| 5 | `ECannotDeleteSuperAdmin` | Used `delete()` on super admin |

## Testing

```bash
sui move test
sui move test --coverage
```

> [!WARNING]
> If all super admin caps are lost/burned, admin access is **permanently lost**. Create multiple super admins and distribute to different wallets/multisigs.

## License

[Apache-2.0](LICENSE)
