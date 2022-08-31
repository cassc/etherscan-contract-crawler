// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.9;

import "../token/T.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @notice A wrapper around OpenZeppelin's `SafeERC20Upgradeable` but specific
///         to the T token. Use this library in upgradeable contracts. If your
///         contract is non-upgradeable, then the traditional `SafeERC20` works.
///         The motivation is to prevent upgradeable contracts that use T from
///         depending on the `Address` library, which can be problematic since
///         it uses `delegatecall`, which is discouraged by OpenZeppelin for use
///         in upgradeable contracts.
/// @dev This implementation force-casts T to `IERC20Upgradeable` to make it
///      work with `SafeERC20Upgradeable`.
library SafeTUpgradeable {
    function safeTransfer(
        T token,
        address to,
        uint256 value
    ) internal {
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(address(token)),
            to,
            value
        );
    }

    function safeTransferFrom(
        T token,
        address from,
        address to,
        uint256 value
    ) internal {
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(address(token)),
            from,
            to,
            value
        );
    }
}