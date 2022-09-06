// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract TokenRecover {
    using SafeERC20 for IERC20;

    event RecoverERC20(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    function _recoverERC20(
        address token,
        address to,
        uint256 amount
    ) internal virtual {
        emit RecoverERC20(token, to, amount);
        IERC20(token).safeTransfer(to, amount);
    }
}