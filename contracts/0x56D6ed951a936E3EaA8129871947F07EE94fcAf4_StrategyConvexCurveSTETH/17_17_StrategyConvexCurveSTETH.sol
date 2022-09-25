// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { StrategyConvexFarmBase } from "../StrategyConvexFarmBase.sol";
import { ICurveFi_2 } from "../../../interfaces/ICurve.sol";
import { IBaseRewardPool } from "../../../interfaces/IConvexFarm.sol";

contract StrategyConvexCurveSTETH is StrategyConvexFarmBase {
    using SafeERC20 for IERC20;

    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant STE_CRV = 0x06325440D014e39736583c165C2963BA99fAf14E;
    address public constant CURVE_POOL = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
    address public constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

    constructor(address _governance, address _controller)
        StrategyConvexFarmBase(
            STE_CRV, // want
            CURVE_POOL, // curvePool
            25, // convexPoolId
            _governance,
            _controller
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyConvexCurveSTETH";
    }

    function harvest() public override {
        address self = address(this);
        IERC20 cvxIERC20 = IERC20(cvx);
        IERC20 crvIERC20 = IERC20(crv);
        IERC20 ldoIERC20 = IERC20(LDO);

        IBaseRewardPool(getCrvRewardContract()).getReward(self, true);

        // Check rewards
        uint256 _cvx = cvxIERC20.balanceOf(self);
        emit RewardToken(cvx, _cvx);

        uint256 _crv = crvIERC20.balanceOf(self);
        emit RewardToken(crv, _crv);

        uint256 _ldo = ldoIERC20.balanceOf(self);
        emit RewardToken(LDO, _ldo);

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

        if (_ldo > 0) {
            ldoIERC20.safeApprove(univ2Router2, 0);
            ldoIERC20.safeApprove(univ2Router2, _ldo);
            _swapUniswapExactTokensForETH(LDO, _ldo);
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