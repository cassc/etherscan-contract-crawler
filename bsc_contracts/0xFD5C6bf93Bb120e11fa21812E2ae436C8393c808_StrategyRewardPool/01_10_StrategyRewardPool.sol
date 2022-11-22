// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./UniswapInterfaces.sol";
import "./StratManager.sol";


contract StrategyRewardPool is StratManager {
    using SafeERC20 for IERC20;

    bytes32 public constant STRATEGY_TYPE = keccak256("REWARD_POOL");

    // Third party contracts
    address public rewardPool;

    // Routes
    address[] public outputToWantRoute;

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
        address _rewardPool
    ) public onlyOwner {
        safeFarm = _safeFarm;
        rewardPool = _rewardPool;

        if (output != want) {
            if (output != wbnb) {
                outputToWantRoute = [output, wbnb, want];
            } else {
                outputToWantRoute = [wbnb, want];
            }
        }

        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public override whenNotPaused {
        uint256 wantBal = balanceOfWant();

        if (wantBal > 0) {
            IRewardPool(rewardPool).deposit(wantBal);

            emit Deposit(wantBal);
        }
    }

    // called as part of withdrawing the funds by account's request from safeFarm contract
    function withdraw(
        address account, uint256 share, uint256 totalShares
    ) external onlySafeFarm {
        uint256 amount = calcSharesAmount(share, totalShares);
        uint256 wantBal = _getWantBalance(amount);

        uint256 systemFeeAmount = wantBal * systemFee / 100;
        uint256 treasuryFeeAmount = wantBal * treasuryFee / 100;
        uint256 withdrawalAmount = wantBal - systemFeeAmount - treasuryFeeAmount;

        IERC20(want).safeTransfer(account, withdrawalAmount);
        if (systemFeeAmount > 0) IERC20(want).safeTransfer(systemFeeRecipient, systemFeeAmount);
        if (treasuryFeeAmount > 0) IERC20(want).safeTransfer(treasuryFeeRecipient, treasuryFeeAmount);

        emit Withdraw(address(want), account, withdrawalAmount);
    }

    // called as part of safe withdrawing the funds by oracle's request from safeFarm contract
    function safeSwap(
        address account, uint256 share, uint256 totalShares,
        uint256 feeAdd,
        address[] memory route
    ) external onlySafeFarm {
        require(route[0] == want, "invalid route");

        uint256 amount = calcSharesAmount(share, totalShares);
        uint256 wantBal = _getWantBalance(amount);

        _safeSwap(account, wantBal, route, feeAdd);
    }

    // compounds earnings and charges performance fee
    function harvest() external whenNotPaused onlyEOA {
        _withdrawAmountOfWant(0);
        uint256 toWant = _chargeFees();
        _swapRewards(toWant);
        deposit();

        emit StratHarvest(msg.sender);
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        require(_token != want, "!safe");
        require(_token != output, "!safe");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    // it calculates how much {want} the strategy has allocated in the {targetRewardPool}
    function balanceOfPool() public view override returns (uint256) {
        (uint256 _amount) = IRewardPool(rewardPool).userInfo(address(this));
        return _amount;
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function pendingReward() public view override returns (uint256 amount) {
        amount = IRewardPool(rewardPool).pendingReward(address(this));
        return amount;
    }

    // called as part of strat migration. Sends all the available funds back to the SafeFarm.
    function retireStrat() external onlySafeFarm {
        uint256 poolBal = balanceOfPool();
        if (poolBal > 0) {
            _withdrawAmountOfWant(poolBal);
        }

        uint256 wantBal = balanceOfWant();
        if (wantBal > 0) {
            IERC20(want).transfer(safeFarm, wantBal);
        }
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() external onlyOwner {
        _withdrawAmountOfWant(balanceOfPool());
        pause();
    }


// INTERNAL FUNCTIONS

    // optionally swaps rewards if output != want.
    function _swapRewards(uint256 toWant) internal {
        if (output != want) {
            // uint256 toWant = IERC20(output).balanceOf(address(this));
            IUniswapRouterETH(unirouter).swapExactTokensForTokens(
                toWant,
                0,
                outputToWantRoute,
                address(this),
                block.timestamp
            );
        }
    }

    function _withdrawAmountOfWant(uint256 amount) internal override {
        IRewardPool(rewardPool).withdraw(amount);
    }

    function _giveAllowances() internal override {
        IERC20(want).safeApprove(rewardPool, type(uint256).max);
        IERC20(want).safeApprove(unirouter, type(uint256).max);
        IERC20(output).safeApprove(unirouter, type(uint256).max);
    }

    function _removeAllowances() internal override {
        IERC20(want).safeApprove(rewardPool, 0);
        IERC20(want).safeApprove(unirouter, 0);
        IERC20(output).safeApprove(unirouter, 0);
    }

}


interface IRewardPool {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function userInfo(address _user) external view returns (uint256);
    function pendingReward(address _user) external view returns (uint256);
}