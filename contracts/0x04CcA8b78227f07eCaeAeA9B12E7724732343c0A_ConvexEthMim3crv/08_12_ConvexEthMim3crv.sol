// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Defii} from "../Defii.sol";
import {DefiiWithCustomEnter} from "../DefiiWithCustomEnter.sol";
import {DefiiWithCustomExit} from "../DefiiWithCustomExit.sol";

interface IBasePool {
    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) external;

    function calc_withdraw_one_coin(
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);

    function remove_liquidity(
        uint256 _amount,
        uint256[3] memory min_amounts
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}

interface IMetaPool {
    function add_liquidity(
        uint256[2] memory _amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);

    function approve(address _spender, uint256 _amount) external;

    function balanceOf(address account) external view returns (uint256);

    function calc_withdraw_one_coin(
        uint256 _burn_amount,
        int128 i
    ) external returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function remove_liquidity(
        uint256 _burn_amount,
        uint256[2] memory _min_amounts
    ) external returns (uint256[2] memory);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external returns (uint256);
}

interface IBooster {
    function depositAll(uint256 _pid, bool _stake) external returns (bool);
}

interface IBaseRewardPool {
    function withdrawAllAndUnwrap(bool claim) external;

    function getReward(
        address _account,
        bool _claimExtras
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract ConvexEthMim3crv is DefiiWithCustomEnter, DefiiWithCustomExit {
    using SafeERC20 for IERC20;

    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant LP3CRV = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    IERC20 constant CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 constant CVX = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    IBasePool constant basePool =
        IBasePool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    IMetaPool constant metaPool =
        IMetaPool(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);
    IBooster constant booster =
        IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IBaseRewardPool constant rewardPool =
        IBaseRewardPool(0xFd5AbF66b003881b88567EB9Ed9c651F14Dc4771);

    uint256 constant FARMING_PID = 40;

    function enterParams(
        uint256 slippage
    ) external view returns (bytes memory) {
        require(slippage > 800, "Slippage must be >800, (>80%)");
        require(slippage < 1200, "Slippage must be <1200, (<120%)");

        uint256 virtualPrice = metaPool.get_virtual_price();
        uint256 minPrice = (virtualPrice * slippage) / 1000;

        return abi.encode(minPrice);
    }

    function exitParams(
        int128 index,
        uint256 slippage
    ) external view returns (bytes memory) {
        require(slippage > 800, "Slippage must be >800, (>80%)");
        require(slippage < 1200, "Slippage must be <1200, (<120%)");
        require(
            index >= 0 && index <= 3,
            "Token index must be 1 for DAI, 2 for USDC, 3 for USDT or 0 for most profitable"
        );
        uint256 tokenPerLp = 0;
        if (index == 0) {
            for (int128 t = 0; t < 3; t++) {
                uint256 a = basePool.calc_withdraw_one_coin(1e18, t);
                if (tokenPerLp < a) {
                    tokenPerLp = a;
                    index = t + 1;
                }
            }
        } else {
            tokenPerLp = basePool.calc_withdraw_one_coin(1e18, index - 1);
        }

        return abi.encode(index, (tokenPerLp * slippage) / 1000);
    }

    function hasAllocation() external view override returns (bool) {
        return rewardPool.balanceOf(address(this)) > 0;
    }

    function _enterWithParams(bytes memory params) internal override {
        uint256 minPrice = abi.decode(params, (uint256));

        uint256 usdcAmount = USDC.balanceOf(address(this));
        USDC.safeApprove(address(basePool), usdcAmount);
        basePool.add_liquidity([0, usdcAmount, 0], 0);
        uint256 lp3crvAmount = LP3CRV.balanceOf(address(this));
        LP3CRV.safeApprove(address(metaPool), lp3crvAmount);
        uint256 lpAmount = metaPool.add_liquidity(
            [0, lp3crvAmount],
            ((usdcAmount * 1e12) / minPrice)
        );
        metaPool.approve(address(booster), lpAmount);
        booster.depositAll(FARMING_PID, true);
    }

    function _commonExit() internal returns (uint256) {
        _harvest();
        rewardPool.withdrawAllAndUnwrap(false);
        uint256 lpAmount = metaPool.balanceOf(address(this));

        return lpAmount;
    }

    function _exit() internal override(Defii, DefiiWithCustomExit) {
        uint256 lpAmount = _commonExit();
        uint256[2] memory metaReceived = metaPool.remove_liquidity(
            lpAmount,
            [uint256(0), uint256(0)]
        );
        basePool.remove_liquidity(
            metaReceived[1],
            [uint256(0), uint256(0), uint256(0)]
        );
    }

    function _exitWithParams(bytes memory params) internal override {
        (int128 index, uint256 tokenPerLp) = abi.decode(
            params,
            (int128, uint256)
        );

        uint256 lpAmount = _commonExit();
        uint256 lp3crvAmount = metaPool.remove_liquidity_one_coin(
            lpAmount,
            1,
            0
        );
        basePool.remove_liquidity_one_coin(
            lp3crvAmount,
            index - 1,
            (lp3crvAmount * tokenPerLp) / 1e18
        );
    }

    function _harvest() internal override {
        rewardPool.getReward(address(this), true);
        _claimIncentive(CRV);
        _claimIncentive(CVX);
    }

    function _withdrawFunds() internal override {
        withdrawERC20(DAI);
        withdrawERC20(USDC);
        withdrawERC20(USDT);
    }
}