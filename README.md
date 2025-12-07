# sui-move-admin

Generic admin capability module for Sui Move. Deploy once, import anywhere.

## Overview

A deployed module on mainnet/testnet that any project can import to add scoped admin capabilities. Uses phantom generics with OTW to ensure package-level isolation.

**Type Safety**: Package address is part of the type identity. `AdminCap<0xabc::foo::FOO>` and `AdminCap<0xdef::foo::FOO>` are completely distinct types, making collision impossible.

## Installation

```toml
# Move.toml
[dependencies]
SuiMoveAdmin = { git = "https://github.com/nox-ant/sui-move-admin.git", rev = "main" }
```

## Usage Example

```move
module my_package::my_module;

use sui_move_admin::admin::{Self, AdminCap};

public struct MY_MODULE has drop {}

fun init(otw: MY_MODULE, ctx: &mut TxContext) {
    let mut super_admins = admin::create_super_admin(otw, 2, ctx);
    
    // Distribute to different wallets for redundancy
    admin::transfer_admin(super_admins.pop_back(), @wallet_1);
    admin::transfer_admin(super_admins.pop_back(), @wallet_2);
    super_admins.destroy_empty();
}

public fun admin_only_action(cap: &AdminCap<MY_MODULE>, ctx: &TxContext) {
    admin::verify(cap, ctx);
    // ... privileged logic
}
```

## API

### Creation

```move
public fun create_super_admin<T: drop>(
    otw: T, 
    amount: u16, 
    ctx: &mut TxContext
): vector<AdminCap<T>>
```

### Transfer

```move
public fun transfer_admin<T>(cap: AdminCap<T>, recipient: address)
```

### Promotion

```move
public fun promote<T>(
    super_admin: &AdminCap<T>, 
    recipient: address,
    epochs_valid: u64,
    ctx: &mut TxContext
)
```

### Verification

```move
public fun verify<T>(cap: &AdminCap<T>, ctx: &TxContext)
```

### Deletion

```move
public fun delete<T>(cap: AdminCap<T>)
public fun burn_super_admin<T>(cap: AdminCap<T>)
```

### Read Functions

```move
public fun is_expired<T>(cap: &AdminCap<T>, ctx: &TxContext): bool
public fun is_super_admin<T>(cap: &AdminCap<T>): bool
public fun expires_epoch<T>(cap: &AdminCap<T>): u64
```

## Error Codes

| Code | Name | Description |
|------|------|-------------|
| 1 | `ENotOneTimeWitness` | Invalid OTW passed to create_super_admin |
| 2 | `ENotSuperAdmin` | Non-super admin attempted promotion |
| 3 | `EAdminCapExpired` | Cap expired, cannot verify |
| 4 | `EInvalidAmount` | Amount < 1 in create_super_admin |

## Testing

```bash
sui move test
sui move test --coverage
```

## License

Apache-2.0
