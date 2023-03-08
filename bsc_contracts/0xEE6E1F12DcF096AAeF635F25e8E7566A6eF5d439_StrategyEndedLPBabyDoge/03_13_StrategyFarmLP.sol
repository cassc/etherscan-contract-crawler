// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./IMasterChef.sol";
import "./StratManager.sol";


contract StrategyFarmLP is StratManager {
    using SafeERC20 for IERC20;

    bytes32 public constant STRATEGY_TYPE = keccak256("FARM_LP");

    // Tokens used
    address public lpToken0;
    address public lpToken1;

    // Third party contracts
    address public masterchef;
    uint256 public poolId;

    // Routes
    address[] public outputToLp0Route;
    address[] public outputToLp1Route;

    constructor(
        address _unirouter,
        address _want,
        address _output,
        address _native,

        address _callFeeRecipient,
        address _frfiFeeRecipient,
        address _strategistFeeRecipient,

        address _safeFarmFeeRecipient,

        address _treasuryFeeRecipient,
        address _systemFeeRecipient
    ) StratManager(
        _unirouter,
        _want,
        _output,
        _native,

        _callFeeRecipient,
        _frfiFeeRecipient,
        _strategistFeeRecipient,

        _safeFarmFeeRecipient,

        _treasuryFeeRecipient,
        _systemFeeRecipient
    ) {}

    // initialize strategy
    function initialize(
        address _safeFarm,
        address _masterchef,
        uint256 _poolId
    ) public virtual onlyOwner {
        safeFarm = _safeFarm;
        masterchef = _masterchef;
        poolId = _poolId;

        lpToken0 = IUniswapV2Pair(want).token0();
        lpToken1 = IUniswapV2Pair(want).token1();

        if (output != lpToken0) {
            if (output == native || native == lpToken0) {
                outputToLp0Route = [output, lpToken0];
            }
            else {
                outputToLp0Route = [output, native, lpToken0];
            }
        }

        if (output != lpToken1) {
            if (output == native || native == lpToken1) {
                outputToLp1Route = [output, lpToken1];
            }
            else {
                outputToLp1Route = [output, native, lpToken1];
            }
        }

        _giveAllowances();
    }

    // set custom route
    function setHarvestRoutes(
        address[] memory route0,
        address[] memory route1
    ) public onlyOwner {
        _routeValidate(route0, output, lpToken0);
        _routeValidate(route1, output, lpToken1);

        outputToLp0Route = route0;
        outputToLp1Route = route1;
    }

    // withdraw the funds by account's request from safeFarm contract
    function withdraw(
        address account, uint256 share, uint256 totalShares
    ) external onlySafeFarm {
        harvest();
        uint256 amount = calcSharesAmount(share, totalShares);
        uint256 wantBal = _getWantBalance(amount);

        uint256 systemFeeAmount = wantBal * systemFee / 100;
        uint256 treasuryFeeAmount = wantBal * treasuryFee / 100;
        uint256 withdrawalAmount = wantBal - systemFeeAmount - treasuryFeeAmount;

        IERC20(want).safeTransfer(account, withdrawalAmount);

        uint256 feeAmount = systemFeeAmount + treasuryFeeAmount;
        if (feeAmount > 0) {
            (uint256 amountToken0, uint256 amountToken1) = _removeLiquidity(feeAmount);

            uint256 systemFeeAmountToken0 = amountToken0 * systemFeeAmount / (feeAmount);
            IERC20(lpToken0).safeTransfer(systemFeeRecipient, systemFeeAmountToken0);
            IERC20(lpToken0).safeTransfer(treasuryFeeRecipient, amountToken0 - systemFeeAmountToken0);

            uint256 systemFeeAmountToken1 = amountToken1 * systemFeeAmount / (feeAmount);
            IERC20(lpToken1).safeTransfer(systemFeeRecipient, systemFeeAmountToken1);
            IERC20(lpToken1).safeTransfer(treasuryFeeRecipient, amountToken1 - systemFeeAmountToken1);
        }

        emit Withdraw(address(want), account, withdrawalAmount);
    }

    // safe withdraw the funds by oracle's request from safeFarm contract
    function safeSwap(
        address account, uint256 share, uint256 totalShares,
        uint256 feeAdd,
        address[] memory route0, address[] memory route1
    ) external onlySafeFarm {
        require(route0[0] == lpToken0, "invalid route0");
        require(route1[0] == lpToken1, "invalid route1");

        harvest();
        uint256 amount = calcSharesAmount(share, totalShares);
        uint256 wantBal = _getWantBalance(amount);

        (uint256 amountToken0, uint256 amountToken1) = _removeLiquidity(wantBal);
        _safeSwap(account, amountToken0, route0, feeAdd);
        _safeSwap(account, amountToken1, route1, 0);
    }


    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view override virtual returns (uint256) {
        (uint256 _amount, ) = IMasterChef(masterchef).userInfo(poolId, address(this));
        return _amount;
    }

    function pendingReward() public view override virtual returns (uint256 amount) {
        amount = IMasterChef(masterchef).pendingCake(poolId, address(this));
        return amount * (MAX_FEE - poolFee) / MAX_FEE;
    }


// INTERNAL FUNCTIONS

    // compounds earnings and charges performance fee
    function _harvest(uint256 _txFee) internal override {
        _poolDeposit(0);

        uint256 toWant = _chargeFees(_txFee);
        if (toWant > 0) {
            _addOutputToLiquidity(toWant);
            deposit();
        }

        emit StratHarvest(msg.sender);
    }

    function _poolDeposit(uint256 _amount) internal override virtual {
        IMasterChef(masterchef).deposit(poolId, _amount);
    }

    function _poolWithdraw(uint256 _amount) internal override virtual {
        IMasterChef(masterchef).withdraw(poolId, _amount);
    }

    function _emergencyWithdraw() internal override virtual {
        uint256 poolBal = balanceOfPool();
        if (poolBal > 0) {
            IMasterChef(masterchef).emergencyWithdraw(poolId);
        }
    }

    function _giveAllowances() internal override virtual {
        IERC20(want).safeApprove(masterchef, 0);
        IERC20(want).safeApprove(masterchef, type(uint256).max);

        IERC20(want).safeApprove(unirouter, 0);
        IERC20(want).safeApprove(unirouter, type(uint256).max);

        IERC20(output).safeApprove(unirouter, 0);
        IERC20(output).safeApprove(unirouter, type(uint256).max);

        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, type(uint256).max);

        IERC20(lpToken1).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, type(uint256).max);
    }

    function _removeAllowances() internal override virtual {
        IERC20(want).safeApprove(masterchef, 0);
        IERC20(want).safeApprove(unirouter, 0);
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function _addOutputToLiquidity(uint256 toWant) internal {
        uint256 outputHalf = toWant / 2;

        if (lpToken0 != output) {
            _swapToken(outputHalf, outputToLp0Route, address(this));
        }

        if (lpToken1 != output) {
            _swapToken(toWant - outputHalf, outputToLp1Route, address(this));
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        _addLiquidity( lp0Bal, lp1Bal);
    }

    function _addLiquidity(uint256 amountToken0, uint256 amountToken1) internal virtual {
        IUniswapRouterETH(unirouter).addLiquidity(
            lpToken0,
            lpToken1,
            amountToken0,
            amountToken1,
            1,
            1,
            address(this),
            block.timestamp
        );
    }

    function _removeLiquidity(uint256 amount) internal virtual returns (
        uint256 amountToken0, uint256 amountToken1
    ) {
        return IUniswapRouterETH(unirouter).removeLiquidity(
            lpToken0,
            lpToken1,
            amount,
            1,
            1,
            address(this),
            block.timestamp
        );
    }
}