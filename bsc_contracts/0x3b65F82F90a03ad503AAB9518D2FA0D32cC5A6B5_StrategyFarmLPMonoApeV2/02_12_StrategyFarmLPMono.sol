// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IMasterChef.sol";
import "./UniswapInterfaces.sol";
import "./StratManager.sol";


contract StrategyFarmLPMono is StratManager {
    using SafeERC20 for IERC20;

    bytes32 public constant STRATEGY_TYPE = keccak256("FARM_LP_MONO");

    // Third party contracts
    address public masterchef;
    uint256 constant public poolId = 0;

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
    ) {
        require(output == want, 'invalid strategy type');
    }

    // initialize strategy
    function initialize(
        address _safeFarm,
        address _masterchef
    ) public onlyOwner {
        safeFarm = _safeFarm;
        masterchef = _masterchef;

        _giveAllowances();
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
        if (systemFeeAmount > 0) IERC20(want).safeTransfer(systemFeeRecipient, systemFeeAmount);
        if (treasuryFeeAmount > 0) IERC20(want).safeTransfer(treasuryFeeRecipient, treasuryFeeAmount);

        emit Withdraw(address(want), account, withdrawalAmount);
    }

    // safe withdraw the funds by oracle's request from safeFarm contract
    function safeSwap(
        address account, uint256 share, uint256 totalShares,
        uint256 feeAdd,
        address[] memory route
    ) external onlySafeFarm {
        require(route[0] == want, "invalid route");

        harvest();
        uint256 amount = calcSharesAmount(share, totalShares);
        uint256 wantBal = _getWantBalance(amount);

        _safeSwap(account, wantBal, route, feeAdd);
    }

    // compounds earnings and charges performance fee
    function harvest() public override whenNotPaused onlyEOA {
        _poolDeposit(0);

        uint256 toWant = _chargeFees();
        if (toWant > 0) {
            _poolDeposit(toWant);
        }

        emit StratHarvest(msg.sender);
    }


    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view override virtual returns (uint256) {
        (uint256 _amount, ) = IMasterChef(masterchef).userInfo(poolId, address(this));
        return _amount;
    }

    function pendingReward() public view override virtual returns (uint256 amount) {
        amount = IMasterChef(masterchef).pendingCake(poolId, address(this));
        return amount;
    }


// INTERNAL FUNCTIONS

    function _poolDeposit(uint256 _amount) internal override virtual {
        IMasterChef(masterchef).enterStaking(_amount);
    }

    function _poolWithdraw(uint256 amount) internal override virtual {
        IMasterChef(masterchef).leaveStaking(amount);
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
    }

    function _removeAllowances() internal override virtual {
        IERC20(want).safeApprove(masterchef, 0);
        IERC20(want).safeApprove(unirouter, 0);
    }
}