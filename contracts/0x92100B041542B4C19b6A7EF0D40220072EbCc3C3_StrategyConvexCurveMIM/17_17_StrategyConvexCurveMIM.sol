// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { StrategyConvexFarmBase } from "../StrategyConvexFarmBase.sol";
import { ICurveFi_2 } from "../../../interfaces/ICurve.sol";
import { IBaseRewardPool } from "../../../interfaces/IConvexFarm.sol";

contract StrategyConvexCurveMIM is StrategyConvexFarmBase {
    using SafeERC20 for IERC20;

    address public constant MIM = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;
    address public constant SPELL = 0x090185f2135308BaD17527004364eBcC2D37e5F6;

    constructor(address _governance, address _controller)
        StrategyConvexFarmBase(
            0x5a6A4D54456819380173272A5E8E9B9904BdF41B, //mim3crv
            0x5a6A4D54456819380173272A5E8E9B9904BdF41B, //curvePool
            40, // convexPoolId
            _governance,
            _controller
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyConvexCurveMim";
    }

    function harvest() public override {
        address self = address(this);
        IERC20 cvxIERC20 = IERC20(cvx);
        IERC20 crvIERC20 = IERC20(crv);
        IERC20 spellIERC20 = IERC20(SPELL);
        IERC20 mimIERC20 = IERC20(MIM);

        IBaseRewardPool(getCrvRewardContract()).getReward(self, true);

        // Check rewards
        uint256 _cvx = cvxIERC20.balanceOf(self);
        emit RewardToken(cvx, _cvx);

        uint256 _crv = crvIERC20.balanceOf(self);
        emit RewardToken(crv, _crv);

        uint256 _spell = spellIERC20.balanceOf(self);
        emit RewardToken(SPELL, _spell);

        // Swap cvx to crv
        if (_cvx > 0) {
            cvxIERC20.safeApprove(sushiRouter, 0);
            cvxIERC20.safeApprove(sushiRouter, _cvx);
            _swapSushiswap(cvx, crv, _cvx);
        }

        // Swap fxs to crv
        if (_spell > 0) {
            spellIERC20.safeApprove(sushiRouter, 0);
            spellIERC20.safeApprove(sushiRouter, _spell);
            _swapSushiswap(SPELL, crv, _spell);
        }

        _crv = crvIERC20.balanceOf(self);

        if (_crv > 0) {
            crvIERC20.safeApprove(univ2Router2, 0);
            crvIERC20.safeApprove(univ2Router2, _crv);
            _swapUniswap(crv, MIM, _crv);
        }

        uint256 mimBalance = mimIERC20.balanceOf(self);

        if (mimBalance > 0) {
            mimIERC20.safeApprove(curvePool, 0);
            mimIERC20.safeApprove(curvePool, mimBalance);
            uint256[2] memory liquidity;
            liquidity[0] = mimBalance;
            ICurveFi_2(curvePool).add_liquidity(liquidity, 0);
        }
        emit Harvest();
        deposit();
    }
}