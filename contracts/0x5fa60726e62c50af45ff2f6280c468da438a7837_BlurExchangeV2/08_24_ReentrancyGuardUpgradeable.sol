// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/// @notice Upgradeable gas optimized reentrancy protection for smart contracts.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract ReentrancyGuardUpgradeable {
    uint256 private locked;

    function __Reentrancy_init() internal {
        locked = 1;
    }

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }

    uint256[49] private __gap;
}