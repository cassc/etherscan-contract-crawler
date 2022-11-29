// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Defii} from "../Defii.sol";

uint256 constant N_COINS = 2;

contract HelioBscHayBusd is Defii {
    IERC20 constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 constant HAY = IERC20(0x0782b6d8c4551B9760e74c0545a9bCD90bdc41E5);
    IERC20 constant lpToken =
        IERC20(0xB6040A9F294477dDAdf5543a24E5463B8F2423Ae);

    IStableSwap constant stableSwap =
        IStableSwap(0x49079D07ef47449aF808A4f36c2a8dEC975594eC);
    IFarming constant farming =
        IFarming(0xf0fA2307392e3b0bD742437C6f80C6C56Fd8A37f);
    uint256 constant FARMING_PID = 1;

    function hasAllocation() external view override returns (bool) {
        (uint256 shares, , ) = farming.userInfo(FARMING_PID, address(this));
        return shares > 0;
    }

    function _enter() internal override {
        uint256 busdAmount = BUSD.balanceOf(address(this));
        BUSD.approve(address(stableSwap), busdAmount);
        uint256[N_COINS] memory amounts = [0, busdAmount];
        stableSwap.add_liquidity(amounts, 0);

        uint256 lpAmount = lpToken.balanceOf(address(this));
        lpToken.approve(address(farming), lpAmount);
        farming.deposit(1, lpAmount, false, address(this));
    }

    function _exit() internal override {
        farming.withdrawAll(FARMING_PID, true);
        uint256[N_COINS] memory amounts = [uint256(0), 0];
        stableSwap.remove_liquidity(lpToken.balanceOf(address(this)), amounts);

        uint256 hayAmount = HAY.balanceOf(address(this));
        HAY.approve(address(stableSwap), hayAmount);
        stableSwap.exchange(0, 1, hayAmount, (hayAmount * 999) / 1000);
    }

    function _harvest() internal override {
        uint256[] memory pids = new uint256[](1);
        pids[0] = FARMING_PID;
        uint256 hayAmount = farming.claim(address(this), pids);
        HAY.approve(address(stableSwap), hayAmount);
        stableSwap.exchange(0, 1, hayAmount, (hayAmount * 999) / 1000);
        withdrawERC20(BUSD);
    }

    function _withdrawFunds() internal override {
        withdrawERC20(BUSD);
    }
}

interface IStableSwap {
    function add_liquidity(
        uint256[N_COINS] memory amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity(
        uint256 _amount,
        uint256[N_COINS] memory min_amounts
    ) external;

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external;
}

interface IFarming {
    function deposit(
        uint256 _pid,
        uint256 _wantAmt,
        bool _claimRewards,
        address _userAddress
    ) external;

    function withdrawAll(uint256 _pid, bool _claimRewards)
        external
        returns (uint256);

    function claim(address _user, uint256[] calldata _pids)
        external
        returns (uint256);

    function userInfo(uint256 pid, address wallet)
        external
        view
        returns (
            uint256 shares,
            uint256 rewardDebt,
            uint256 claimable
        );
}