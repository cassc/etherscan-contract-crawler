// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import {ERC4626Upgradeable, ERC20Upgradeable, IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

/// @title ERC4626UpgradeableSafe.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice ERC4626 Tokenized Vault abstract upgradeable implementation tweaking OZ's implementation to make it safer at initialization.
abstract contract ERC4626UpgradeableSafe is ERC4626Upgradeable {
    /// CONSTRUCTOR ///

    /// @notice Constructs the contract.
    /// @dev The contract automatically disables initializers when deployed so that nobody can highjack the implementation contract.
    constructor() {
        _disableInitializers();
    }

    /// INITIALIZER ///

    function __ERC4626UpgradeableSafe_init(
        IERC20MetadataUpgradeable _asset,
        uint256 _initialDeposit
    ) internal {
        __ERC4626_init(_asset);
        __ERC4626UpgradeableSafe_init_unchained(_initialDeposit);
    }

    function __ERC4626UpgradeableSafe_init_unchained(uint256 _initialDeposit) internal {
        // Sacrifice an initial seed of shares to ensure a healthy amount of precision in minting shares.
        // Set to 0 at your own risk.
        // Caller must have approved the asset to this contract's address.
        // See: https://github.com/Rari-Capital/solmate/issues/178
        if (_initialDeposit > 0) deposit(_initialDeposit, address(this));
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[50] private __gap;
}