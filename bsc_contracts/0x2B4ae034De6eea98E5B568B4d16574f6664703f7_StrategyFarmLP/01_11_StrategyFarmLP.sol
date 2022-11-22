// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IMasterChef.sol";
import "./UniswapInterfaces.sol";
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

    // Events
    event Deposit(uint256 amount);
    event Withdraw(address tokenAddress, address account, uint256 amount);

    constructor(
        address _unirouter,
        address _want,
        address _output,
        address _wbnb,

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
        _wbnb,

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
    ) public onlyOwner {
        safeFarm = _safeFarm;
        masterchef = _masterchef;
        poolId = _poolId;

        lpToken0 = IUniswapV2Pair(want).token0();
        lpToken1 = IUniswapV2Pair(want).token1();

        if (lpToken0 == wbnb) {
            outputToLp0Route = [output, wbnb];
        } else if (lpToken0 != output) {
            outputToLp0Route = [output, wbnb, lpToken0];
        }

        if (lpToken1 == wbnb) {
            outputToLp1Route = [output, wbnb];
        } else if (lpToken1 != output) {
            outputToLp1Route = [output, wbnb, lpToken1];
        }

        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public override whenNotPaused {
        uint256 wantBal = balanceOfWant();

        if (wantBal > 0) {
            IMasterChef(masterchef).deposit(poolId, wantBal);

            emit Deposit(wantBal);
        }
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

    // compounds earnings and charges performance fee
    function harvest() public virtual whenNotPaused onlyEOA {
        IMasterChef(masterchef).deposit(poolId, 0);
        uint256 toWant = _chargeFees();
        _addLiquidity(toWant);
        deposit();

        emit StratHarvest(msg.sender);
    }


    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view override returns (uint256) {
        (uint256 _amount, ) = IMasterChef(masterchef).userInfo(poolId, address(this));
        return _amount;
    }

    function pendingReward() public view override virtual returns (uint256 amount) {
        amount = IMasterChef(masterchef).pendingCake(poolId, address(this));
        return amount * (MAX_FEE - poolFee) / MAX_FEE;
    }

    // called as part of strat migration. Sends all the available funds back to the SafeFarm.
    function retireStrat() external onlySafeFarm {
        uint256 poolBal = balanceOfPool();
        if (poolBal > 0) {
            IMasterChef(masterchef).emergencyWithdraw(poolId);
        }

        uint256 wantBal = balanceOfWant();
        if (wantBal > 0) {
            IERC20(want).transfer(safeFarm, wantBal);
        }
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyOwner {
        pause();
        IMasterChef(masterchef).emergencyWithdraw(poolId);
    }


// INTERNAL FUNCTIONS

    function _removeLiquidity(uint256 amount) internal returns (uint256 amountToken0, uint256 amountToken1) {
        return IUniswapRouterETH(unirouter).removeLiquidity(
            lpToken0,
            lpToken1,
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function _addLiquidity(uint256 toWant) internal {
        uint256 outputHalf = toWant / 2;

        if (lpToken0 != output) {
            IUniswapRouterETH(unirouter).swapExactTokensForTokens(
                outputHalf,
                0,
                outputToLp0Route,
                address(this),
                block.timestamp
            );
        }

        if (lpToken1 != output) {
            IUniswapRouterETH(unirouter).swapExactTokensForTokens(
                outputHalf,
                0,
                outputToLp1Route,
                address(this),
                block.timestamp
            );
        }

        uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        IUniswapRouterETH(unirouter).addLiquidity(
            lpToken0,
            lpToken1,
            lp0Bal,
            lp1Bal,
            1,
            1,
            address(this),
            block.timestamp
        );
    }

    function _withdrawAmountOfWant(uint256 amount) internal override {
        IMasterChef(masterchef).withdraw(poolId, amount);
    }

    function _giveAllowances() internal override {
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

    function _removeAllowances() internal override {
        IERC20(want).safeApprove(masterchef, 0);
        IERC20(want).safeApprove(unirouter, 0);
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(lpToken0).safeApprove(unirouter, 0);
        IERC20(lpToken1).safeApprove(unirouter, 0);
    }
}