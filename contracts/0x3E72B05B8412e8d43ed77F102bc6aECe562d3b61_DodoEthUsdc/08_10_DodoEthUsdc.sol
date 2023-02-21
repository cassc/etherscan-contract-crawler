// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Defii} from "../Defii.sol";

contract DodoEthUsdc is Defii {
    using SafeERC20 for IERC20;

    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant DODO = IERC20(0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd);
    IERC20 constant USDC_DODO_LP =
        IERC20(0x05a54b466F01510E92c02d3a180BaE83A64BAab8);
    IDODO constant pool = IDODO(0xC9f93163c99695c6526b799EbcA2207Fdf7D61aD);
    IDODOMine constant mine =
        IDODOMine(0xaeD7384F03844Af886b830862FF0a7AFce0a632C);

    function hasAllocation() public view override returns (bool) {
        return mine.getUserLpBalance(address(USDC_DODO_LP), address(this)) > 0;
    }

    function _enter() internal override {
        uint256 usdcAmount = USDC.balanceOf(address(this));
        USDC.safeApprove(address(pool), usdcAmount);
        uint256 lpAmount = pool.depositQuote(usdcAmount);
        USDC_DODO_LP.safeApprove(address(mine), lpAmount);
        mine.deposit(address(USDC_DODO_LP), lpAmount);
    }

    function _exit() internal override {
        mine.withdrawAll(address(USDC_DODO_LP));
        _claimIncentive(DODO);
        pool.withdrawAllQuote();
    }

    function _harvest() internal override {
        mine.claimAll();
        _claimIncentive(DODO);
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDC);
    }
}

interface IDODO {
    function depositQuote(uint256 amount) external returns (uint256);

    function withdrawAllQuote() external returns (uint256);
}

interface IDODOMine {
    function claimAll() external;

    function deposit(address _lpToken, uint256 _amount) external;

    function getUserLpBalance(address _lpToken, address _user)
        external
        view
        returns (uint256);

    function withdrawAll(address _lpToken) external;
}