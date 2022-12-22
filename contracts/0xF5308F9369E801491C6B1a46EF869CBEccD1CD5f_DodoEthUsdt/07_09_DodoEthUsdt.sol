// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Defii} from "../Defii.sol";

contract DodoEthUsdt is Defii {
    using SafeERC20 for IERC20;

    IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant DODO = IERC20(0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd);
    IERC20 constant USDT_DODO_LP =
        IERC20(0x50b11247bF14eE5116C855CDe9963fa376FceC86);
    IDODO constant pool = IDODO(0xC9f93163c99695c6526b799EbcA2207Fdf7D61aD);
    IDODOMine constant mine =
        IDODOMine(0xaeD7384F03844Af886b830862FF0a7AFce0a632C);

    function hasAllocation() external view override returns (bool) {
        return mine.getUserLpBalance(address(USDT_DODO_LP), address(this)) > 0;
    }

    function _enter() internal override {
        uint256 usdtAmount = USDT.balanceOf(address(this));
        USDT.safeApprove(address(pool), usdtAmount);
        uint256 lpAmount = pool.depositBase(usdtAmount);
        USDT_DODO_LP.safeApprove(address(mine), lpAmount);
        mine.deposit(address(USDT_DODO_LP), lpAmount);
    }

    function _exit() internal override {
        mine.withdrawAll(address(USDT_DODO_LP));
        withdrawERC20(DODO);
        pool.withdrawAllBase();
    }

    function _harvest() internal override {
        mine.claimAll();
        withdrawERC20(DODO);
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDT);
    }
}

interface IDODO {
    function depositBase(uint256 amount) external returns (uint256);

    function withdrawAllBase() external returns (uint256);
}

interface IDODOMine {
    function claimAll() external;

    function deposit(address _lpToken, uint256 _amount) external;

    function getUserLpBalance(
        address _lpToken,
        address _user
    ) external view returns (uint256);

    function withdrawAll(address _lpToken) external;
}