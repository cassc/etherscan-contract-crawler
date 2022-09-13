// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../../interfaces/common/IUniswapRouterETH.sol";
import "../../interfaces/curve/ICurveSwap.sol";
import "../../interfaces/goldfinch/IStakingGoldfinch.sol";
import "../../libraries/SafeCurveSwap.sol";
import "../../libraries/SafeUniswapRouter.sol";
import "../../managers/FeeManager.sol";
import "../../managers/SlippageManager.sol";
import "../../managers/StratManager.sol";
import "../../utils/AddressUtils.sol";

contract StrategyGoldfinchStaking is StratManager, FeeManager, SlippageManager, ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeCurveSwap for ICurveSwap;
    using SafeUniswapRouter for IUniswapRouterETH;

    // Tokens used
    address public want;
    address public native;
    address public output;
    address public preferredUnderlyingToken;

    // NFT token id obtained with first deposit
    uint256 tokenId;

    // Own contracts
    address public stakingReward;

    IStakingGoldfinch.StakedPositionType public immutable stakedPositionType;

    address public pool;
    uint public poolSize;
    uint public immutable preferredUnderlyingTokenIndex;

    bool public harvestOnDeposit;
    uint256 public lastHarvest;

    // Routes
    address[] public outputToNativeRoute;
    address[] public nativeToPreferredUnderlyingTokenRoute;

    mapping(address => bool) public underlyingTokenAndFlag;
    mapping(address => uint256) public underlyingTokenAndIndex;

    event Harvest(address indexed harvester, uint256 wantHarvested, uint256 tvl);
    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);
    event ChargeFees(uint256 harvestCallFeeAmount, uint256 strategistFeeAmount, uint256 performanceFeeAmount);
    event OwnerOperation(address indexed invoker, string method);

    constructor (
        address _want,
        address _stakingReward,
        IStakingGoldfinch.StakedPositionType _stakedPositionType,
        address _pool,
        uint _poolSize,
        address[] memory _outputToNativeRoute,
        address[] memory _nativeToPreferredUnderlyingTokenRoute,
        address _vault,
        address _unirouter,
        address _strategist,
        address _companyFeeRecipient,
        address _preferredUnderlyingToken
    ) StratManager(_strategist, _unirouter, _vault, _companyFeeRecipient) public {
        want = AddressUtils.validateOneAndReturn(_want);
        stakingReward = AddressUtils.validateOneAndReturn(_stakingReward);
        stakedPositionType = _stakedPositionType;

        pool = AddressUtils.validateOneAndReturn(_pool);
        poolSize = _poolSize;

        AddressUtils.validateManyAndReturn(_outputToNativeRoute);
        AddressUtils.validateManyAndReturn(_nativeToPreferredUnderlyingTokenRoute);

        output = _outputToNativeRoute[0];
        native = _outputToNativeRoute[_outputToNativeRoute.length - 1];
        outputToNativeRoute = _outputToNativeRoute;

        require(_nativeToPreferredUnderlyingTokenRoute[0] == native, '_nativeToPreferredUnderlyingTokenRoute[0] != native');
        nativeToPreferredUnderlyingTokenRoute = _nativeToPreferredUnderlyingTokenRoute;

        preferredUnderlyingToken = AddressUtils.validateOneAndReturn(_preferredUnderlyingToken);

        for (uint256 index = 0; index < poolSize; index++) {
            address tokenAddress = ICurveSwap(pool).coins(index);
            underlyingTokenAndFlag[tokenAddress] = true;
            underlyingTokenAndIndex[tokenAddress] = index;
        }

        preferredUnderlyingTokenIndex = underlyingTokenAndIndex[preferredUnderlyingToken];

        _giveAllowances();
    }

    // puts the funds to work
    function deposit() public whenNotPaused nonReentrant {
        uint256 wantBal = balanceOfWant();

        if (wantBal == 0) {
            return;
        }

        if (tokenId == 0) {
            tokenId = IStakingGoldfinch(stakingReward).stake(wantBal, stakedPositionType);
        } else {

            uint256 stakedBalance = IStakingGoldfinch(stakingReward).stakedBalanceOf(tokenId);

            IStakingGoldfinch(stakingReward).unstake(tokenId, stakedBalance);

            IStakingGoldfinch(stakingReward).getReward(tokenId);

            uint256 updatedWantBal = balanceOfWant();

            tokenId = IStakingGoldfinch(stakingReward).stake(updatedWantBal, stakedPositionType);
        }

        emit Deposit(balanceOf());
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(msg.sender == vault, "!vault");

        if (tx.origin != owner() && !paused()) {
            uint256 withdrawalFeeAmount = _amount.mul(withdrawalFee).div(FEE_DENOMINATOR);
            _amount = _amount.sub(withdrawalFeeAmount);
        }

        uint256 wantBal = balanceOfWant();
        if (wantBal < _amount) {
            IStakingGoldfinch(stakingReward).unstake(tokenId, _amount.sub(wantBal));
        }

        IERC20(want).safeTransfer(vault, _amount);

        emit Withdraw(balanceOf());
    }

    // Compounds earnings and charges fees.
    function harvest() public whenNotPaused {
        if (tokenId == 0) {
            return;
        }

        IStakingGoldfinch(stakingReward).getReward(tokenId);

        uint256 outputBal = IERC20(output).balanceOf(address(this));

        if (outputBal == 0) {
            return;
        }

        IUniswapRouterETH(unirouter).safeSwapExactTokensForTokens(slippage, outputBal, outputToNativeRoute, address(this), now);

        _chargeFees();
        _addLiquidity();
        uint256 wantHarvested = balanceOfWant();
        deposit();

        lastHarvest = block.timestamp;
        emit Harvest(msg.sender, wantHarvested, balanceOf());
    }

    function beforeDeposit() external override {
        if (harvestOnDeposit) {
            require(msg.sender == vault, "!vault");
            harvest();
        }
    }

    function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyOwner {
        harvestOnDeposit = _harvestOnDeposit;

        if (harvestOnDeposit) {
            setWithdrawalFee(0);
        } else {
            setWithdrawalFee(withdrawalFee);
        }

        emit OwnerOperation(msg.sender, "StrategyGoldfinchStaking.setHarvestOnDeposit");
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() external onlyOwner {
        pause();
        IStakingGoldfinch(stakingReward).unstake(tokenId, balanceOfPool());

        emit OwnerOperation(msg.sender, "StrategyGoldfinchStaking.panic");
    }

    function pause() public onlyOwner {
        _pause();

        _removeAllowances();

        emit OwnerOperation(msg.sender, "StrategyGoldfinchStaking.pause");
    }

    function unpause() external onlyOwner {
        _unpause();

        _giveAllowances();

        deposit();

        emit OwnerOperation(msg.sender, "StrategyGoldfinchStaking.unpause");
    }

    // calculate the total underlying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        return IStakingGoldfinch(stakingReward).stakedBalanceOf(tokenId);
    }

    function coins(uint256 _index) external view returns (address){
        return ICurveSwap(pool).coins(_index);
    }

    function underlyingToken(address _tokenAddress) external view returns (bool){
        return underlyingTokenAndFlag[_tokenAddress];
    }

    function underlyingTokenIndex(address _tokenAddress) external view returns (uint256){
        return underlyingTokenAndIndex[_tokenAddress];
    }

    // Uses optimisticClaimable as it accounts for claimableRewards plus earnedSinceLastCheckpoint
    function rewardsAvailable() external view returns (uint256) {
        return IStakingGoldfinch(stakingReward).optimisticClaimable(tokenId);
    }

    receive() external payable {}

    // Charge harvest call, strategy, and performance fees from profits earned.
    function _chargeFees() internal {
        uint256 nativeBal = IERC20(native).balanceOf(address(this));

        uint256 harvestCallFeeAmount;
        if (harvestCallFee > 0) {
            harvestCallFeeAmount = nativeBal.mul(harvestCallFee).div(FEE_DENOMINATOR);
            IERC20(native).safeTransfer(tx.origin, harvestCallFeeAmount);
        }

        uint256 strategistFeeAmount;
        if (strategistFee > 0 && strategist != address(0)) {
            strategistFeeAmount = nativeBal.mul(strategistFee).div(FEE_DENOMINATOR);
            IERC20(native).safeTransfer(strategist, strategistFeeAmount);
        }

        uint256 performanceFeeAmount = nativeBal.mul(performanceFee).div(FEE_DENOMINATOR);
        IERC20(native).safeTransfer(companyFeeRecipient, performanceFeeAmount);

        emit ChargeFees(harvestCallFeeAmount, strategistFeeAmount, performanceFeeAmount);
    }

    function _addLiquidity() internal {
        uint256 nativeBal = IERC20(native).balanceOf(address(this));

        IUniswapRouterETH(unirouter).safeSwapExactTokensForTokens(slippage, nativeBal, nativeToPreferredUnderlyingTokenRoute, address(this), now);

        uint256 preferredUnderlyingTokenBal = IERC20(preferredUnderlyingToken).balanceOf(address(this));

        uint256[2] memory amounts;
        amounts[preferredUnderlyingTokenIndex] = preferredUnderlyingTokenBal;
        ICurveSwap(pool).safeAddLiquidityUsingNoDepositSlippageCalculation(slippage, amounts);
    }

    function _giveAllowances() internal {
        IERC20(native).safeApprove(unirouter, type(uint).max);
        IERC20(output).safeApprove(unirouter, type(uint).max);
        IERC20(want).safeApprove(stakingReward, type(uint256).max);
        IERC20(preferredUnderlyingToken).safeApprove(pool, type(uint).max);
    }

    function _removeAllowances() internal {
        IERC20(native).safeApprove(unirouter, 0);
        IERC20(output).safeApprove(unirouter, 0);
        IERC20(want).safeApprove(stakingReward, 0);
        IERC20(preferredUnderlyingToken).safeApprove(pool, 0);
    }

}