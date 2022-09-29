// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

abstract contract ERC20TokenRecoverable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function recover(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) external {
        _authorizeRecover(token, to, amount);
        token.safeTransfer(to, amount);
    }

    function _authorizeRecover(
        IERC20Upgradeable token,
        address to,
        uint256 amount
    ) internal virtual;
}