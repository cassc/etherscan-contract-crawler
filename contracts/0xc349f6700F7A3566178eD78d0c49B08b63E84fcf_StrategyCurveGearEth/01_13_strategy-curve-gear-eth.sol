// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "../../lib/erc20.sol";
import "../../lib/safe-math.sol";

import "../../interfaces/jar.sol";
import "../../interfaces/curve.sol";

import "../strategy-base.sol";

contract StrategyCurveGearEth is StrategyBase {
    // Curve
    IERC20 public gearEthLp = IERC20(0x5Be6C45e2d074fAa20700C49aDA3E88a1cc0025d);
    ICurveFi_2 public gearEthPool = ICurveFi_2(0x0E9B5B092caD6F1c5E6bc7f89Ffe1abb5c95F1C2);

    // curve dao
    ICurveGauge public gauge = ICurveGauge(0x37Efc3f05D659B30A83cf0B07522C9d08513Ca9d); // gear gauge
    ICurveMintr public mintr = ICurveMintr(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);

    // tokens we're farming
    IERC20 public constant crv = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    IERC20 public constant gear = IERC20(0xBa3335588D9403515223F109EdC4eB7269a9Ab5D);

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyBase(address(gearEthLp), _governance, _strategist, _controller, _timelock) {
        gearEthLp.approve(address(gauge), uint256(-1));
        gear.approve(address(gearEthPool), uint256(-1));
        crv.approve(address(univ2Router2), uint256(-1));
        IERC20(weth).approve(address(gearEthPool), uint256(-1));
    }

    // **** Getters ****

    function balanceOfPool() public view override returns (uint256) {
        return gauge.balanceOf(address(this));
    }

    function getName() external pure override returns (string memory) {
        return "StrategyCurveGearEth";
    }

    function getHarvestable() external returns (uint256, uint256) {
        uint256 _gear = gauge.claimable_reward(address(this), address(gear));
        uint256 _crv = gauge.claimable_tokens(address(this));

        return (_gear, _crv);
    }

    // **** State Mutations ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            gauge.deposit(_want);
        }
    }

    function _withdrawSome(uint256 _amount) internal override returns (uint256) {
        gauge.withdraw(_amount);
        return _amount;
    }

    function harvest() public override onlyBenevolent {
        gauge.claim_rewards();
        mintr.mint(address(gauge));

        uint256 _gear = gear.balanceOf(address(this));
        uint256 _crv = crv.balanceOf(address(this));

        if (_crv > 0) {
            _swapUniswap(address(crv), weth, _crv);
        }

        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_gear > 0 || _weth > 0) {
            uint256[2] memory liquidity;
            liquidity[0] = _gear;
            liquidity[1] = _weth;

            gearEthPool.add_liquidity(liquidity, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}