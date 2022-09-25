// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { StrategyConvexFarmBase } from "../StrategyConvexFarmBase.sol";
import { ICurveFi_3_int128 } from "../../../interfaces/ICurve.sol";
import { IBaseRewardPool } from "../../../interfaces/IConvexFarm.sol";

contract StrategyConvexCurveSBTC is StrategyConvexFarmBase {
    using SafeERC20 for IERC20;

    address internal constant RENBTC = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant SBTC = 0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6;

    constructor(address _governance, address _controller)
        StrategyConvexFarmBase(
            0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3, // want = 3crv lp-token
            0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714, // curvePool = 3crv pool
            7, // convexPoolId
            _governance,
            _controller
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyConvexCurveSBTC";
    }

    function harvest() public override {
        IBaseRewardPool(getCrvRewardContract()).getReward(address(this), true);

        // Check rewards
        uint256 _cvx = IERC20(cvx).balanceOf(address(this));
        emit RewardToken(cvx, _cvx);

        uint256 _crv = IERC20(crv).balanceOf(address(this));
        emit RewardToken(crv, _crv);

        // Swap cvx to crv
        if (_cvx > 0) {
            IERC20(cvx).safeApprove(sushiRouter, 0);
            IERC20(cvx).safeApprove(sushiRouter, _cvx);
            _swapSushiswap(cvx, crv, _cvx);
        }

        // Swap crv to stable coins
        (address to, uint256 toIndex) = getMostPremium();

        _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            IERC20(crv).safeApprove(univ2Router2, 0);
            IERC20(crv).safeApprove(univ2Router2, _crv);
            _swapUniswap(crv, to, _crv);
        }

        // reinvestment
        uint256 _to = IERC20(to).balanceOf(address(this));
        if (_to > 0) {
            IERC20(to).safeApprove(curvePool, 0);
            IERC20(to).safeApprove(curvePool, _to);
            uint256[3] memory liquidity;
            liquidity[toIndex] = _to;
            ICurveFi_3_int128(curvePool).add_liquidity(liquidity, 0);
        }
        emit Harvest();
        deposit();
    }

    function getMostPremium() internal view returns (address, uint256) {
        ICurveFi_3_int128 curve = ICurveFi_3_int128(curvePool);
        uint256[3] memory balances = [curve.balances(0) * 1e10, curve.balances(1) * 1e10, curve.balances(2)];

        // USDC
        if (balances[0] < balances[1] && balances[0] < balances[2]) {
            return (RENBTC, 0);
        }

        // USDT
        if (balances[1] < balances[0] && balances[1] < balances[2]) {
            return (WBTC, 1);
        }

        return (SBTC, 2);
    }
}