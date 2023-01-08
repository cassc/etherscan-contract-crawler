// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import "./interfaces/IUniswapV2Router02.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// dev
import "hardhat/console.sol";
import "./utils/DummyPool.sol";


contract MPStaking is Initializable, KeeperCompatible, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    using SafeMathUpgradeable for uint256;

    IUniswapV2Router02 public swapV2Router;

    address public operationWallet;
    address public stakingPool;
    address public escrowRewardsPool;

    /**
    * 10000 wei is equivalent to 100%
    * 1000 wei is equivalent to 10%
    * 100 wei is equivalent to 1%
    * 10 wei is equivalent to 0.1%
    * 1 wei is equivalent to 0.01%
    */

    uint256 public reintroducePercent;
    uint256 public reintroducePercentDenominator;

    uint256 public distributeRewardsDuration;
    uint256 public lastTimeStamp;

//    // 30 Days (30 * 24 * 60 * 60)
//    uint256 public stakingDuration30 = 2592000;
//    uint256 public stakingFeePercentbefore30days;
//
//    // 60 Days (30 * 24 * 60 * 60)
//    uint256 public stakingDuration60 = 5184000;
//    uint256 public stakingFeePercentbefore60days;
//
//    // 90 Days (30 * 24 * 60 * 60)
//    uint256 public stakingDuration90 = 7776000;
//    uint256 public stakingFeePercentbefore90days;

    struct StakeInfo {
        address token;                                              // BEP Pegged Token to stake
        uint256 startTS;                                            // start time
        uint256 amount;                                             // staking amount
        mapping(address => uint256) rewards;   // amount for rewards (stakedToken => (availableToken => amount))
        bool unStaked;                                              // is unstaked?
    }

    // Stake fees bust be created in order of duration, if a new duration lies between 2 existing durations all longer
    // durations should be removed and re-added.
    struct StakeFees {
        uint256 duration;
        uint256 feePercentage;
        uint256 stakeDenominator;
    }

    StakeFees[] public feeTiers;

    address[] public availableRewardsTokens;

    mapping(address => mapping(address => StakeInfo)) stakeInfos; // User wallet => (BEP Pegged Token => StakeInfo)
    mapping(address => mapping(address => bool)) isStakedToken; // User wallet => (BEP Pegged Token => bool)

    mapping(address => uint256) totalStakedAmount; // Token => amount
    mapping(address => uint256) totalFeeAmountOfStakingPool; // token => amount

    mapping(address => address[]) tokenStakers; // token => user array
    // Index in array of staker (Prevents looping for gas savings) Not 0 indexed for existence check.
    mapping(address => mapping(address => uint256)) private stakerIndex;

    mapping (address => uint256) prevTotalRewards; // token => amount

    event Staked(address indexed from, uint256 amount, address token);
    event UnStaked(address indexed from, uint256 amount, address token);


    /* TODO: Testing functionality only, remove before deployment */
    /**************************************************************/
    mapping(address => bool) public testingAuthorized;
    modifier authorized(){
        require(testingAuthorized[_msgSender()] || owner() == _msgSender());
        _;
    }
    function updateAuthorized(address wallet, bool isAuthorized) external authorized {
        testingAuthorized[wallet] = isAuthorized;
    }
    /**************************************************************/
    /* TODO: Testing functionality only, remove before deployment */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _operationWallet, address _router) initializer external virtual {
        __MPStaking_init(_operationWallet, _router);
    }

    function __MPStaking_init(address _operationWallet, address _router) internal {
        __Ownable_init();
        __MPStaking_init_unchained(_operationWallet, _router);
    }

    function __MPStaking_init_unchained(address _operationWallet, address _router) internal {
        escrowRewardsPool = address(new DummyPool(_msgSender()));
        stakingPool = address(new DummyPool(_msgSender()));
        operationWallet = _operationWallet;
//        stakingPool = _stakingPool;
        reintroducePercent = 100; // 1%
        reintroducePercentDenominator = 10000; // 100/10000 = 1%
        distributeRewardsDuration = 1 days;

        feeTiers.push(StakeFees({
            duration: 30 days,
            feePercentage: 6,
            stakeDenominator: 100
        }));
        feeTiers.push(StakeFees({
            duration: 60 days,
            feePercentage: 4,
            stakeDenominator: 100
        }));
        feeTiers.push(StakeFees({
            duration: 90 days,
            feePercentage: 2,
            stakeDenominator: 100
        }));

        // BNB mainnet router (pancake) : 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // BNB testnet router (pancake) : 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        // ETH mainnet router (uinswap) : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        swapV2Router = IUniswapV2Router02(_router);

        lastTimeStamp = block.timestamp;
    }

    /**
     * Restricted to daily_operator only modifier to add to functions
    */
    modifier onlyOperation() {
        require(msg.sender == operationWallet, 'You are not an Operater.');
        _;
    }

    function setDistributeRewardsDuration(uint256 _duration) external authorized {
        distributeRewardsDuration = _duration;
    }

    function setReintroducedPercent (uint256 _reintroducedPercent, uint256 _reintroduceDenominator) external authorized {
        reintroducePercent = _reintroducedPercent;
        reintroducePercentDenominator = _reintroduceDenominator;
    }

//    function setFeePercentBefore30days (uint256 _percent) external onlyOperation {
//        stakingFeePercentbefore30days = _percent;
//    }
//
//    function setFeePercentBefore60days (uint256 _percent) external onlyOperation {
//        stakingFeePercentbefore60days = _percent;
//    }
//
//    function setFeePercentBefore90days (uint256 _percent) external onlyOperation {
//        stakingFeePercentbefore90days = _percent;
//    }

//    function setFeePercents (
//        uint256 _percentBefore30days,
//        uint256 _percentBefore60days,
//        uint256 _percentBefore90days) external onlyOperation {
//
//        stakingFeePercentbefore30days = _percentBefore30days;
//        stakingFeePercentbefore60days = _percentBefore60days;
//        stakingFeePercentbefore90days = _percentBefore90days;
//    }

    function addTokens(address[] memory _tokens) external authorized {
        for (uint idx = 0; idx < _tokens.length; idx ++) {
            availableRewardsTokens.push(_tokens[idx]);
        }
    }

    function removeToken(address _token) external authorized {
        for (uint idx = 0; idx < availableRewardsTokens.length; idx ++) {
            if(availableRewardsTokens[idx] == _token){
                availableRewardsTokens[idx] = availableRewardsTokens[availableRewardsTokens.length - 1];
                availableRewardsTokens.pop();
                break;
            }
        }
    }

    function getTotalStakedAmount(address _token) external view returns(uint256) {
        return totalStakedAmount[_token];
    }

    function getStakedTokenCount() internal view returns (uint256) {
        uint stakedTokenCount = 0;
        uint256 tokenCount = availableRewardsTokens.length;
        for(uint i = 0; i < tokenCount; i ++) {
            address token = availableRewardsTokens[i];
            if(IERC20Upgradeable(token).balanceOf(stakingPool) > totalFeeAmountOfStakingPool[token]) {
                stakedTokenCount++;
            }
        }
        return stakedTokenCount;
    }

    function distributeRewardsPerToken(address _stakedToken) internal {
        uint256 stakedTokenCount = getStakedTokenCount();
        address[] storage stakers = tokenStakers[_stakedToken];
        uint256 stakerCount = stakers.length;
        uint256 tokenCount = availableRewardsTokens.length;

        for(uint i = 0; i < tokenCount; i ++) {
            address token = availableRewardsTokens[i];
            uint256 currentRewardsBalance = IERC20Upgradeable(token).balanceOf(address(this));
            uint256 rewardsAmount = (currentRewardsBalance - prevTotalRewards[token]) / stakedTokenCount;

            if(rewardsAmount > 0) {
                for(uint j = 0; j < stakerCount; j ++) {
                    StakeInfo storage staker = stakeInfos[stakers[j]][_stakedToken];
                    uint256 percentOfStaked = staker.amount.mul(10000).div(totalStakedAmount[_stakedToken]);
                    staker.rewards[token] += rewardsAmount.mul(percentOfStaked).div(10000);
                }
            }
        }
    }

    function distributeRewardsAllTokens () internal {
        uint256 tokenCount = availableRewardsTokens.length;
        for(uint i = 0; i < tokenCount; i ++) {
            address token = availableRewardsTokens[i];
            if(IERC20Upgradeable(token).balanceOf(stakingPool) > totalFeeAmountOfStakingPool[token] ) {
                distributeRewardsPerToken(token);
            }
        }

        // set current blance as prev
        for(uint i = 0; i < tokenCount; i ++) {
            address token = availableRewardsTokens[i];
            uint256 currentRewardsBalance = IERC20Upgradeable(token).balanceOf(address(this));
            prevTotalRewards[token] = currentRewardsBalance;
        }
    }

    function setlastTime() external authorized {
        lastTimeStamp = block.timestamp;
    }

    // chainlink checkKeepUp...
    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > distributeRewardsDuration;
        performData = checkData;

        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata /* performData */) external authorized override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > distributeRewardsDuration) {
            lastTimeStamp = block.timestamp;
            distributeRewardsAllTokens();
        }
    }

    function stakeToken(address _token, uint256 _stakeAmount) external authorized {

        require(_stakeAmount > 0, "Stake amount should be correct");
        require(IERC20Upgradeable(_token).balanceOf(msg.sender) >= _stakeAmount, "Insufficient Balance");

        // send token to staking pool
        IERC20Upgradeable(_token).transferFrom(msg.sender, address(this), _stakeAmount);
//        IERC20Upgradeable(_token).approve(stakingPool, _stakeAmount);
        IERC20Upgradeable(_token).transfer(stakingPool, _stakeAmount);

        // add total amounts
        totalStakedAmount[_token] += _stakeAmount;

        if(isStakedToken[msg.sender][_token] == false) { // if the user didn't stake this token

            StakeInfo storage stakeInfo = stakeInfos[msg.sender][_token];
            stakeInfo.startTS = block.timestamp;
            stakeInfo.token = _token;
            stakeInfo.amount = _stakeAmount;
            stakeInfo.unStaked = false;

            isStakedToken[msg.sender][_token] = true;
            tokenStakers[_token].push(msg.sender);
            stakerIndex[_token][msg.sender] = tokenStakers[_token].length; // Index after expanding array, index+1

        } else { // if the user staked this token already
            stakeInfos[msg.sender][_token].startTS = block.timestamp;
            stakeInfos[msg.sender][_token].amount += _stakeAmount;
        }

        emit Staked(msg.sender, _stakeAmount, _token);
    }

    function removeStaker(address _staker, address _token) internal {
        address[] storage stakers = tokenStakers[_token];
        uint stakerCount = stakers.length;
        address lastStakerInArray = stakers[stakerCount - 1];
        uint256 stakerCurrentIndex = stakerIndex[_token][_staker];
        stakerIndex[_token][lastStakerInArray] = _staker == lastStakerInArray ? 0 : stakerCurrentIndex;

        if(stakerIndex[_token][_staker] != 0){
            stakers[stakerCurrentIndex - 1] = lastStakerInArray;
        }

        stakerIndex[_token][_staker] = 0;

        stakers.pop();
//        for(uint idx = 0; idx < stakerCount; idx ++) {
//
//            if(stakers[idx] == _staker) {
//                stakers[idx] = stakers[stakers.length - 1];
//                stakers.pop();
//                break;
//            }
//        }
    }

    function unStakeWithRewards(address _token, uint256 _unstakeAmount) external authorized returns (bool) {
        // TODO: Allow partial unstaking -- CHECK MATHS
        require(isStakedToken[msg.sender][_token] == true,  "Already unstaked" );

        uint256 stakedAmount = stakeInfos[msg.sender][_token].amount;
        require(_unstakeAmount <= stakedAmount, "Insufficient stake holdings");

        uint256 stakedTime = block.timestamp - stakeInfos[msg.sender][_token].startTS;

        uint256 feePercent = 0;
        uint256 feeDenominator = 100;

        for(uint256 i = 0; i < feeTiers.length; i++){
            if(stakedTime < feeTiers[i].duration){
                feePercent = feeTiers[i].feePercentage;
                feeDenominator = feeTiers[i].stakeDenominator;
                break;
            }
        }

        // Getting rewards
        claimRewards(msg.sender, _token, feePercent, feeDenominator);

        IERC20Upgradeable(_token).transferFrom(stakingPool, address(this), _unstakeAmount);

//        IERC20Upgradeable(_token).approve(msg.sender, stakedAmount);
        IERC20Upgradeable(_token).transfer(msg.sender, _unstakeAmount);

        if(_unstakeAmount == stakedAmount){
            removeStaker(msg.sender, _token);
            isStakedToken[msg.sender][_token] = false;
            stakeInfos[msg.sender][_token].unStaked = true;
        } else {
            stakeInfos[msg.sender][_token].amount -= _unstakeAmount;
        }

        emit UnStaked(msg.sender, _unstakeAmount, _token);

        return true;
    }

    function claimRewards(address _staker, address _stakedToken, uint256 _feePercent, uint256 _feeDenominator) internal {
        uint256 tokenCount = availableRewardsTokens.length;
        StakeInfo storage staker = stakeInfos[_staker][_stakedToken];

        for (uint idx = 0; idx < tokenCount; idx ++) {
            address token = availableRewardsTokens[idx];
            uint256 amount = staker.rewards[token];

            if(amount > 0) {
                uint256 feeAmount = amount.mul(_feePercent).div(_feeDenominator);
//                IERC20Upgradeable(token).approve(_staker, amount - feeAmount);
                IERC20Upgradeable(token).transfer(_staker, amount - feeAmount);

                uint256 swapAmount = amount.mul(reintroducePercent).div(reintroducePercentDenominator);
                if(swapAmount > 0) {
                    swapTokenToBNB(token, swapAmount);
                }

//                IERC20Upgradeable(token).approve(stakingPool, feeAmount - swapAmount);
                IERC20Upgradeable(token).transfer(stakingPool, feeAmount - swapAmount);

                totalFeeAmountOfStakingPool[token] += (feeAmount - swapAmount);
            }
        }
    }
    function swapTokenToBNB(address _token, uint256 _amount) internal returns (bool) {
        uint deadline = block.timestamp + 4;
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = swapV2Router.WETH(); // testnet BNB: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd

        IERC20Upgradeable(_token).approve(address(swapV2Router), _amount);
        swapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_amount, 0, path, operationWallet, deadline);
        return true;
    }

    function getTotalFee(address _token) public view returns (uint256) {
        return totalFeeAmountOfStakingPool[_token];
    }

    function getBNBBalanceOfContract() public view returns(uint256) {
        return address(this).balance;
    }

    function getTokenBalanceOfContract (address _token) public view returns(uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(this));
    }

    function getBNBBalanceOfStakingPool () public view returns(uint256) {
        return stakingPool.balance;
    }

    function getTokenBalanceOfStakingPool (address _token) public view returns(uint256) {
        return IERC20Upgradeable(_token).balanceOf(stakingPool);
    }

    function getWETH () public view returns (address) {
        return swapV2Router.WETH();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addFeeTier(uint256 _durationHours, uint256 _fee, uint256 _feeDenominator) external onlyOwner {
        uint256 _durationInHours = _durationHours * 1 hours;
        if(feeTiers.length > 0){
            if(_durationInHours < feeTiers[feeTiers.length -1].duration) {
                revert("New tier duration must be longer than previos tier");
            }
        }
        feeTiers.push(StakeFees({
            duration: _durationInHours,
            feePercentage: _fee,
            stakeDenominator: _feeDenominator
        }));
    }

    function updateFeeTierAtIndex(uint256 _index, uint256 _durationHours, uint256 _fee, uint256 _feeDenominator) external onlyOwner {
        if(_index >= feeTiers.length) {
            revert("Invalid index");
        }

        uint256 _durationInHours = _durationHours * 1 hours;

        if(_index > 0){
            if(_durationInHours < feeTiers[0].duration) {
                revert("New tier duration must be longer than previos tier");
            }
        }

        if(_index < feeTiers.length - 1){
            if(_durationInHours > feeTiers[_index + 1].duration) {
                revert("New tier duration must be shorter than the following tier");
            }
        }

        feeTiers[_index] = StakeFees({
            duration: _durationInHours,
            feePercentage: _fee,
            stakeDenominator: _feeDenominator
        });
    }

    function removeTopFeeTier() external authorized {
        if(feeTiers.length > 0){
            feeTiers.pop();
        } else {
            revert("No fees present");
        }
    }

    function updateRouter(address _router) external authorized {
        swapV2Router = IUniswapV2Router02(_router);
    }

    function updateOperationsWallet(address _wallet) external authorized {
        operationWallet = _wallet;
    }

    function updateStakingPool(address _pool) external authorized {
        stakingPool = _pool;
    }

    function reclaimBNB() external authorized {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function reclaimToken(address _tokenAddress) external authorized {
        IERC20Upgradeable(_tokenAddress).transfer(_msgSender(), IERC20Upgradeable(_tokenAddress).balanceOf(address(this)));
    }
}