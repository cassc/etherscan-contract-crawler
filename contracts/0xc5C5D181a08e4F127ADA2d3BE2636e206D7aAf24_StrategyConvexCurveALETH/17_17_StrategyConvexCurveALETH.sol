// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { StrategyConvexFarmBase } from "../StrategyConvexFarmBase.sol";
import { ICurveFi_2 } from "../../../interfaces/ICurve.sol";
import { IBaseRewardPool } from "../../../interfaces/IConvexFarm.sol";

contract StrategyConvexCurveALETH is StrategyConvexFarmBase {
    using SafeERC20 for IERC20;

    address public constant ALETH = 0x0100546F2cD4C9D97f798fFC9755E47865FF7Ee6;
    address public constant ALETH_ETH = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;
    address public constant CURVE_POOL = 0xC4C319E2D4d66CcA4464C0c2B32c9Bd23ebe784e;

    constructor(address _governance, address _controller)
        StrategyConvexFarmBase(
            ALETH_ETH, // want
            CURVE_POOL, // curvePool
            49, // convexPoolId
            _governance,
            _controller
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyConvexCurveALETH";
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
            cvxIERC20.safeApprove(univ2Router2, 0);
            cvxIERC20.safeApprove(univ2Router2, _cvx);
            _swapUniswapExactTokensForETH(cvx, _cvx);
        }

        if (_crv > 0) {
            crvIERC20.safeApprove(univ2Router2, 0);
            crvIERC20.safeApprove(univ2Router2, _crv);
            _swapUniswapExactTokensForETH(crv, _crv);
        }

        // reinvestment
        uint256 _to = self.balance;
        if (_to > 0) {
            uint256[2] memory liquidity;
            liquidity[0] = _to;
            ICurveFi_2(curvePool).add_liquidity{ value: _to }(liquidity, 0);
        }
        emit Harvest();
        deposit();
    }
}