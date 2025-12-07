<p align="center">
  <img src="assets/banner.jpg" alt="sui-move-admin banner" width="100%">
</p>

<h1 align="center">sui-move-admin</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Sui-4DA2FF?style=for-the-badge&logo=sui&logoColor=white" />
  <img src="https://img.shields.io/badge/Move-7B42BC?style=for-the-badge&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" />
</p>

---

## Deployment

| Network | PackageID | UpgradeCap | Version | Date |
|---------|-----------|------------|---------|------|
| testnet | `0xc42e20749aeb3df5a5fc3af0fc008ab7b17a7537aefda9291a8ed725ee95c024` | `0x1de91b08f8b91e05f334d903c5649005b59430a88ee557edb4ed711397467ca4` | 1 | 2025-12-07 |

---

```toml
# Move.toml
[dependencies]
SuiMoveAdmin = { git = "https://github.com/nox-ant/sui-move-admin.git", rev = "testnet" }
```

```move
use sui_move_admin::admin::{Self, AdminCap};

fun init(otw: MY_MODULE, ctx: &mut TxContext) {
    let mut admins = admin::create_super_admin(otw, 2, ctx);
    admin::transfer_admin(admins.pop_back(), @wallet_1);
    admin::transfer_admin(admins.pop_back(), @wallet_2);
    admins.destroy_empty();
}

public fun admin_only(cap: &AdminCap<MY_MODULE>, ctx: &TxContext) {
    admin::verify(cap, ctx);
    // ... privileged logic
}
```

*Generic admin capability module for Sui Move. Deploy once, import anywhere.*

## Features

- **Phantom generics** — Your `AdminCap<MY_MODULE>` is distinct from others
- **Epoch-based expiration** — Temp admins auto-expire
- **No `store` ability** — Caps can't be transferred by arbitrary contracts
- **Import, don't deploy** — One audited module for the ecosystem

---

## Testnet

| Type | ID | Version | Date |
|---------|-----------|------------|---------|
| PackageID | `0xc42e20749aeb3df5a5fc3af0fc008ab7b17a7537aefda9291a8ed725ee95c024`  | 1 | 07/12/2025 |
| UpgradeCap | `0x1de91b08f8b91e05f334d903c5649005b59430a88ee557edb4ed711397467ca4` | 1 | 07/12/2025 |

---

## API

### Create Super Admins
```move
public fun create_super_admin<T: drop>(otw: T, amount: u16, ctx: &mut TxContext): vector<AdminCap<T>>
```

### Transfer
```move
public fun transfer_admin<T>(cap: AdminCap<T>, recipient: address)
```

### Promote Temp Admins
```move
public fun promote<T>(super_admin: &AdminCap<T>, recipient: address, epochs_valid: u64, ctx: &mut TxContext)
```

### Verify
```move
public fun verify<T>(cap: &AdminCap<T>, ctx: &TxContext)
```

### Delete
```move
public fun delete<T>(cap: AdminCap<T>)           // Temp admins only
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
| 5 | `ECannotDeleteSuperAdmin` | `delete()` called on super admin |

---

## Examples

### Multi-Sig Setup
```move
fun init(otw: MY_MODULE, ctx: &mut TxContext) {
    let mut admins = admin::create_super_admin(otw, 3, ctx);
    admin::transfer_admin(admins.pop_back(), @multisig_1);
    admin::transfer_admin(admins.pop_back(), @multisig_2);
    admin::transfer_admin(admins.pop_back(), @multisig_3);
    admins.destroy_empty();
}
```

### Temporary Access
```move
public fun grant_temp_access(super: &AdminCap<MY_MODULE>, contractor: address, ctx: &mut TxContext) {
    admin::verify(super, ctx);
    admin::promote(super, contractor, 30, ctx);  // 30 epochs
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

> [!WARNING]
> **No recovery mechanism.** If all super admin caps are lost/burned, admin access is permanently lost. Use multisig and distribute caps across wallets.

---

## License

MIT
