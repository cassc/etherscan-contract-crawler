// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin-4/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin-4/contracts/token/ERC20/utils/SafeERC20.sol";

import {ISolidlyRouter} from "../../interfaces/common/ISolidlyRouter.sol";
import {IRewardPool} from "../../interfaces/common/IRewardPool.sol";
import {IUniswapRouterV3WithDeadline} from "../../interfaces/common/IUniswapRouterV3WithDeadline.sol";
import {IFeeConfig, StratFeeManager} from "../Common/StratFeeManager.sol";
import {GasFeeThrottler} from "../../utils/GasFeeThrottler.sol";

// Valid for Thena on BNB Chain only
contract StrategyThenaBTCBmultiBTCRewardPoolLP is StratFeeManager, GasFeeThrottler {
    using SafeERC20 for IERC20;

    // Tokens used
    address public constant native       = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB
    address public constant output       = 0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11; // THE
    address public constant want         = 0x2475FF2A7C81da27eA2e08e0d3B0Ad01e16225eC; // sAMM-BTCB/multiBTC
    address public constant lpToken0     = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c; // BTCB
    address public constant lpToken1     = 0xD9907fcDa91aC644F70477B8fC1607ad15b2D7A8; // multiBTC

    // Third party contracts
    address public constant rewardPool   = 0x66B34c7578B513600a31A3f79C47e10546830efF; // GaugeV2
    address public constant fusionRouter = 0x327Dd3208f0bCF590A66110aCB6e5e6941A4EfA0; // FusionRouter

    bool public constant stable = true;
    bool public harvestOnDeposit;
    uint256 public lastHarvest;
    
    bytes public outputToNativeRoute;
    bytes public outputToLp0Route;
    ISolidlyRouter.Routes[] public lp0ToLp1Route;
    address[] public rewards;

    event StratHarvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);
    event ChargedFees(uint256 callFees, uint256 beefyFees, uint256 strategistFees);

    constructor(CommonAddresses memory _commonAddresses) 
        StratFeeManager(_commonAddresses) {

        // Set output to native route
        outputToNativeRoute = abi.encodePacked(output, native);

        // Set output to Lp0 route
        outputToLp0Route = abi.encodePacked(output, native, lpToken0);

        // Set Lp0 to Lp1 route
        lp0ToLp1Route.push(ISolidlyRouter.Routes(lpToken0, lpToken1, true));

        rewards.push(output);
        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public whenNotPaused {
        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > 0) {
            IRewardPool(rewardPool).deposit(wantBal);
            emit Deposit(balanceOf());
        }
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal < _amount) {
            IRewardPool(rewardPool).withdraw(_amount - wantBal);
            wantBal = IERC20(want).balanceOf(address(this));
        }

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        if (tx.origin != owner() && !paused()) {
            uint256 withdrawalFeeAmount = wantBal * withdrawalFee / WITHDRAWAL_MAX;
            wantBal = wantBal - withdrawalFeeAmount;
        }

        IERC20(want).safeTransfer(vault, wantBal);

        emit Withdraw(balanceOf());
    }

    function beforeDeposit() external virtual override {
        if (harvestOnDeposit) {
            require(msg.sender == vault, "!vault");
            _harvest(tx.origin);
        }
    }

    function harvest() external gasThrottle virtual {
        _harvest(tx.origin);
    }

    function harvest(address callFeeRecipient) external gasThrottle virtual {
        _harvest(callFeeRecipient);
    }

    // compounds earnings and charges performance fee
    function _harvest(address callFeeRecipient) internal whenNotPaused {
        IRewardPool(rewardPool).getReward();
        uint256 outputBal = IERC20(output).balanceOf(address(this));
        if (outputBal > 0) {
            chargeFees(callFeeRecipient);
            addLiquidity();
            uint256 wantHarvested = balanceOfWant();
            deposit();

            lastHarvest = block.timestamp;
            emit StratHarvest(msg.sender, wantHarvested, balanceOf());
        }
    }

    // performance fees
    function chargeFees(address callFeeRecipient) internal {
        IFeeConfig.FeeCategory memory fees = getFees();
        uint256 toNative = IERC20(output).balanceOf(address(this)) * fees.total / DIVISOR;
        IUniswapRouterV3WithDeadline(fusionRouter).exactInput(
            IUniswapRouterV3WithDeadline.ExactInputParams(
                outputToNativeRoute, address(this), block.timestamp, toNative, 0
        ));

        uint256 nativeBal = IERC20(native).balanceOf(address(this));

        uint256 callFeeAmount = nativeBal * fees.call / DIVISOR;
        IERC20(native).safeTransfer(callFeeRecipient, callFeeAmount);

        uint256 beefyFeeAmount = nativeBal * fees.beefy / DIVISOR;
        IERC20(native).safeTransfer(beefyFeeRecipient, beefyFeeAmount);

        uint256 strategistFeeAmount = nativeBal * fees.strategist / DIVISOR;
        IERC20(native).safeTransfer(strategist, strategistFeeAmount);

        emit ChargedFees(callFeeAmount, beefyFeeAmount, strategistFeeAmount);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 outputBal = IERC20(output).balanceOf(address(this));

        // Swap all output to lpToken0
        IUniswapRouterV3WithDeadline(fusionRouter).exactInput(
            IUniswapRouterV3WithDeadline.ExactInputParams(
                outputToLp0Route, address(this), block.timestamp, outputBal, 0)
        );

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp0Amt = lp0Bal / 2;
        uint256 lp1Amt = lp0Bal - lp0Amt;

        // Stable logic
        uint256 lp0Decimals = 10**18;
        uint256 lp1Decimals = 10**8;
        uint256 out1 = ISolidlyRouter(unirouter).getAmountsOut(lp1Amt, lp0ToLp1Route)[lp0ToLp1Route.length] * 1e18 / lp1Decimals;
        (uint256 amountA, uint256 amountB,) = ISolidlyRouter(unirouter).quoteAddLiquidity(lpToken0, lpToken1, stable, lp0Amt, out1);
        amountA = amountA * 1e18 / lp0Decimals;
        amountB = amountB * 1e18 / lp1Decimals;
        uint256 ratio = lp0Amt * 1e18 / out1 * amountB / amountA;
        lp0Amt = lp0Bal * 1e18 / (ratio + 1e18);
        lp1Amt = lp0Bal - lp0Amt;

        // Swap part of lpToken0 to lpToken1
        ISolidlyRouter(unirouter).swapExactTokensForTokens(lp1Amt, 0, lp0ToLp1Route, address(this), block.timestamp);

        // Deposit liquidity to want pool
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        ISolidlyRouter(unirouter).addLiquidity(lpToken0, lpToken1, stable, lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp);
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        return IRewardPool(rewardPool).balanceOf(address(this));
    }

    // returns rewards unharvested
    function rewardsAvailable() public view returns (uint256) {
        return IRewardPool(rewardPool).earned(address(this));
    }

    // native reward amount for calling harvest
    function callReward() public pure returns (uint256) {
        // Not implemented for Fusion Router
        return 0;
    }

    function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyManager {
        harvestOnDeposit = _harvestOnDeposit;

        if (harvestOnDeposit) {
            setWithdrawalFee(0);
        } else {
            setWithdrawalFee(10);
        }
    }

    function setShouldGasThrottle(bool _shouldGasThrottle) external onlyManager {
        shouldGasThrottle = _shouldGasThrottle;
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "!vault");

        if (IRewardPool(rewardPool).emergency()) IRewardPool(rewardPool).emergencyWithdraw();
        else IRewardPool(rewardPool).withdraw(balanceOfPool());

        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        if (IRewardPool(rewardPool).emergency()) IRewardPool(rewardPool).emergencyWithdraw();
        else IRewardPool(rewardPool).withdraw(balanceOfPool());
    }

    function pause() public onlyManager {
        _pause();

        _removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(rewardPool, type(uint).max);
        IERC20(output).safeApprove(fusionRouter, type(uint).max);

        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, type(uint).max);

        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, type(uint).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(rewardPool, 0);
        IERC20(output).safeApprove(fusionRouter, 0);

        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
    }

    function _solidlyToRoute(ISolidlyRouter.Routes[] memory _route) internal pure returns (address[] memory) {
        address[] memory route = new address[](_route.length + 1);
        route[0] = _route[0].from;
        for (uint i; i < _route.length; ++i) {
            route[i + 1] = _route[i].to;
        }
        return route;
    }

    function _fusionToRoute(bytes memory _route) internal pure returns (address[] memory) {
        address[] memory route = abi.decode(_route, (address[]));
        return route;
    }

    function outputToNative() external view returns (address[] memory) {
        bytes memory _route = outputToNativeRoute;
        return _fusionToRoute(_route);
    }

    function lp0ToLp1() external view returns (address[] memory) {
        ISolidlyRouter.Routes[] memory _route = lp0ToLp1Route;
        return _solidlyToRoute(_route);
    }

    function outputToLp0() external view returns (address[] memory) {
        bytes memory _route = outputToLp0Route;
        return _fusionToRoute(_route);
    }
}