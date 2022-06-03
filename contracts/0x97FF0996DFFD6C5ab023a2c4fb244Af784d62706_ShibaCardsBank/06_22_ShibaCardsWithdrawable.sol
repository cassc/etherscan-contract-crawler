// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ShibaCardsAccessible.sol";

abstract contract ShibaCardsWithdrawable is ShibaCardsAccessible {
    function withdrawERC20(address token) public onlyAdmin {
        SafeERC20.safeTransferFrom(IERC20(token), address(this), _msgSender(), IERC20(token).balanceOf(address(this)));
    }
}