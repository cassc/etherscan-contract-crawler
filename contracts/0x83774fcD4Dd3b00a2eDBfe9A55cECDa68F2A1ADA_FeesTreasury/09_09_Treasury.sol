// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


abstract contract Treasury {
    
    event TokenWithdrawn(string reason, address token, uint256 amount, address to);
    event NativeWithdrawn(string reason, uint256 amount, address to);

    receive() external payable {}

    function _withdraw(
        string calldata reason,
        address token,
        uint256 amount,
        address to
    ) internal {
        if (token == address(0)) {
            (bool sent, ) = to.call{ value: amount }("");
            require(sent, "Treasury: Failed to send Ether");
            emit NativeWithdrawn(reason, amount, to);
        } else {
            SafeERC20.safeTransfer(IERC20(token), to, amount);
            emit TokenWithdrawn(reason, token, amount, to);
        }
    }
}