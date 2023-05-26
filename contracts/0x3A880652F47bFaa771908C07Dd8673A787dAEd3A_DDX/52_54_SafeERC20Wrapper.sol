// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { Context } from "openzeppelin-solidity/contracts/GSN/Context.sol";
import { IERC20 } from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

contract SafeERC20Wrapper is Context {
    using SafeERC20 for IERC20;

    IERC20 private _token;

    constructor(IERC20 token) public {
        _token = token;
    }

    function transfer(address recipient, uint256 amount) public {
        _token.safeTransfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public {
        _token.safeTransferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public {
        _token.safeApprove(spender, amount);
    }

    function increaseAllowance(address spender, uint256 amount) public {
        _token.safeIncreaseAllowance(spender, amount);
    }

    function decreaseAllowance(address spender, uint256 amount) public {
        _token.safeDecreaseAllowance(spender, amount);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _token.allowance(owner, spender);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _token.balanceOf(account);
    }
}