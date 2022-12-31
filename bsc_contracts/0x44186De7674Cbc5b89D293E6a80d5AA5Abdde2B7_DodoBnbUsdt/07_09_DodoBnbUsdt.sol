// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Defii} from "../Defii.sol";

contract DodoBnbUsdt is Defii {
    IERC20 constant USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 constant DODO = IERC20(0x67ee3Cb086F8a16f34beE3ca72FAD36F7Db929e2);
    IERC20 constant USDT_DODO_LP =
        IERC20(0x56ce908EeBafea026ab047CEe99a3afF039B4a33);
    IDODO constant pool = IDODO(0xBe60d4c4250438344bEC816Ec2deC99925dEb4c7);
    IDODOMine constant mine =
        IDODOMine(0x01f9BfAC04E6184e90bD7eaFD51999CE430Cc750);

    function hasAllocation() external view override returns (bool) {
        return mine.getUserLpBalance(address(USDT_DODO_LP), address(this)) > 0;
    }

    function _enter() internal override {
        uint256 usdtAmount = USDT.balanceOf(address(this));
        USDT.approve(address(pool), usdtAmount);
        uint256 lpAmount = pool.depositQuote(usdtAmount);
        USDT_DODO_LP.approve(address(mine), lpAmount);
        mine.deposit(address(USDT_DODO_LP), lpAmount);
    }

    function _exit() internal override {
        mine.withdrawAll(address(USDT_DODO_LP));
        _claimIncentive(DODO);
        pool.withdrawAllQuote();
    }

    function _harvest() internal override {
        mine.claimAll();
        _claimIncentive(DODO);
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDT);
    }
}

interface IDODO {
    function depositQuote(uint256 amount) external returns (uint256);

    function withdrawAllQuote() external returns (uint256);
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