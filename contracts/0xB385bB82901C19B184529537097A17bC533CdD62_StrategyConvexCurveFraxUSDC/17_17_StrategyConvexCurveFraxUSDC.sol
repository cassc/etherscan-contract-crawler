// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { StrategyConvexFarmBase } from "../StrategyConvexFarmBase.sol";
import { ICurveFi_2_256 } from "../../../interfaces/ICurve.sol";
import { IBaseRewardPool } from "../../../interfaces/IConvexFarm.sol";

contract StrategyConvexCurveFraxUSDC is StrategyConvexFarmBase {
    using SafeERC20 for IERC20;

    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    constructor(address _governance, address _controller)
        StrategyConvexFarmBase(
            0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC, //curve token
            0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2, //curve pool
            100, // convex pool id
            _governance,
            _controller
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyConvexCurveFraxUSDC";
    }

    function harvest() public override {
        address self = address(this);
        IERC20 cvxIERC20 = IERC20(cvx);
        IERC20 crvIERC20 = IERC20(crv);

        IBaseRewardPool(getCrvRewardContract()).getReward(self, true);

        // Check rewards
        uint256 _cvx = cvxIERC20.balanceOf(self);
        emit RewardToken(cvx, _cvx);

        uint256 _crv = crvIERC20.balanceOf(self);
        emit RewardToken(crv, _crv);

        if (_cvx > 0) {
            cvxIERC20.safeApprove(sushiRouter, 0);
            cvxIERC20.safeApprove(sushiRouter, _cvx);
            _swapSushiswap(cvx, crv, _cvx);
        }

        _crv = crvIERC20.balanceOf(self);

        (address to, uint256 toIndex) = getMostPremium();

        if (_crv > 0) {
            crvIERC20.safeApprove(univ2Router2, 0);
            crvIERC20.safeApprove(univ2Router2, _crv);
            _swapUniswap(crv, to, _crv);
        }

        uint256 _to = IERC20(to).balanceOf(self);
        if (_to > 0) {
            IERC20(to).safeApprove(curvePool, 0);
            IERC20(to).safeApprove(curvePool, _to);
            uint256[2] memory liquidity;
            liquidity[toIndex] = _to;
            ICurveFi_2_256(curvePool).add_liquidity(liquidity, 0);
        }
        emit Harvest();
        deposit();
    }

    function getMostPremium() internal view returns (address, uint256) {
        ICurveFi_2_256 curve = ICurveFi_2_256(curvePool);

        uint256[2] memory balances = [
            curve.balances(0), // frax
            curve.balances(1) * 1e12 // usdc
        ];

        if (balances[0] < balances[1]) {
            return (FRAX, 0);
        }

        return (USDC, 1);
    }
}