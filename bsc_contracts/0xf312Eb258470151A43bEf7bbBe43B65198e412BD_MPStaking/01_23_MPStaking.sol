// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IMPStaking.sol";
import "./interfaces/IEscrow.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

import "hardhat/console.sol";

contract MPStaking is
    IMPStaking,
    Initializable,
    KeeperCompatible,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct StakeInfo {
        uint256 startTS;                                            // start time
        uint256 amount;                                             // staking amount
        uint256 totalRewards;
        bool unStaked;                                              // is unstaked?
        mapping(address => uint256) totalExcluded;
    }

    EnumerableSetUpgradeable.AddressSet rewardTokens;
    EnumerableSetUpgradeable.AddressSet stakingTokens;

    IUniswapV2Router02 public swapV2Router;

    IEscrow public stakingPool;
    IEscrow public rewardsPool;
    IEscrow public escrowPool;

    mapping(address => mapping(address => StakeInfo)) holderStakeInfo; // User wallet => (BEP Pegged Token => StakeInfo)
    mapping(address => mapping(address => bool)) isStakedToken; // User wallet => (BEP Pegged Token => bool)
    mapping(address => mapping(address => uint256)) public rewardsPerStake;  // Staked token => rewards token => rps

    mapping(address => EnumerableSetUpgradeable.AddressSet) tokenStakers; // token => user array

    address public operationWallet;
    address public lio;

    uint256 public reintroducePercentOps;
    uint256 public reintroducePercentLIO;
    uint256 public reintroducePercentPool;

    uint256 public escrowBonusPercentage;

    uint256 public denominator;

    uint256 public distributeRewardsDuration;
    uint256 public lastTimeStamp;

    uint256 private accuracyFactor;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize (
        address _contractOwner,
        address _operationWallet,
        address _lio,
        address _router,
        address _stakingPool,
        address _rewardsPool,
        address _escrowPool,
        address[] memory _stakeTokens,
        address[] memory _rewardsTokens) initializer external virtual {
        __MPStaking_init(_operationWallet, _lio, _router, _stakingPool, _rewardsPool, _escrowPool, _stakeTokens, _rewardsTokens);
        __UUPSUpgradeable_init();
        transferOwnership(_contractOwner);
    }

    function _authorizeUpgrade (address newImplementation) internal override onlyOwner {}

    function __MPStaking_init (
        address _operationWallet,
        address _lio,
        address _router,
        address _stakingPool,
        address _rewardsPool,
        address _escrowPool,
        address[] memory _stakeTokens,
        address[] memory _rewardsTokens
    ) internal {
        __Ownable_init();
        __MPStaking_init_unchained(_operationWallet, _lio, _router, _stakingPool, _rewardsPool, _escrowPool, _stakeTokens, _rewardsTokens);
    }

    function __MPStaking_init_unchained (
        address _operationWallet,
        address _lio,
        address _router,
        address _stakingPool,
        address _rewardsPool,
        address _escrowPool,
        address[] memory _stakeTokens,
        address[] memory _rewardsTokens
    ) internal {
        operationWallet = _operationWallet;
        lio = _lio;

        stakingPool = IEscrow(_stakingPool);
        rewardsPool = IEscrow(_rewardsPool);
        escrowPool = IEscrow(_escrowPool);

        accuracyFactor = 10 ** 36;

        distributeRewardsDuration = 1 days;

        denominator = 10000; // 100/10000 = 1%

        reintroducePercentLIO = 100; // 1%
        reintroducePercentOps = 100; // 1%
        reintroducePercentPool = 100; // 1%

        escrowBonusPercentage = 100; // 1%

        // BNB PCS mainnet router (pancake)   : 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // BNB PCS testnet router (pancake)   : 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        // BNB SFM mainnent router (safemoon) : 0x6AC68913d8FcCD52d196B09e6bC0205735A4be5f
        // ETH mainnet router (uniswap)       : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        // Goerli Testnet router (uniswap)    : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        swapV2Router = IUniswapV2Router02(_router);

        for(uint256 i = 0; i < _stakeTokens.length; ++i){
            addStakingToken(_stakeTokens[i]);
        }

        for(uint256 i = 0; i < _rewardsTokens.length; ++i){
            addRewardToken(_rewardsTokens[i]);
        }

        lastTimeStamp = block.timestamp;
    }

    receive() external payable {}

    function emergencyWithdrawBNB (address _to) external virtual override onlyOwner {
        (bool success, ) = payable(_to).call{value: address(this).balance}("");
        if(!success){
            revert("Transfer Failed");
        }
    }

    function emergencyWithdrawToken (
        address _tokenAddress,
        address _to
    ) external virtual override onlyOwner {
        IERC20Upgradeable(_tokenAddress).transfer(_to, IERC20Upgradeable(_tokenAddress).balanceOf(address(this)));
    }

    function setDistributeRewardsDuration (uint256 _duration) external onlyOwner {
        require(_duration > 0, "Duration should be more than 0");
        distributeRewardsDuration = _duration;
    }

    // Set fee for every option (Ops, LIO, Pool)
    function updateFees (
        uint256 _reintroducedPercentOps,
        uint256 _reintroducedPercentLIO,
        uint256 _reintroducedPercentPool,
        uint256 _denominator
    ) external onlyOwner {
        if(
            _denominator == 0 || _reintroducedPercentOps > denominator || _reintroducedPercentLIO > denominator ||  _reintroducedPercentPool > denominator){
                revert("Percentage range should be between 0% and 100%");
        }

        reintroducePercentOps = _reintroducedPercentOps;
        reintroducePercentLIO = _reintroducedPercentLIO;
        reintroducePercentPool = _reintroducedPercentPool;

        denominator = _denominator;
    }

    function setEscrowBonusPercentage (uint256 _escrowBonusPercentage) external onlyOwner {
        require(
            _escrowBonusPercentage >= 0 &&  _escrowBonusPercentage <= denominator,
            "Percentage range should be between 0% and 100%"
        );
        escrowBonusPercentage = _escrowBonusPercentage;
    }

    function setEscrowPool (address _escrowPool) external onlyOwner {
        require (_escrowPool != address(0), "Escrow Pool shouldn't be zero!");
        escrowPool = IEscrow(_escrowPool);
    }

    function setRewardsPool (address _rewardsPool) external onlyOwner {
        require (_rewardsPool != address(0), "Rewards Pool shouldn't be zero!");
        rewardsPool = IEscrow(_rewardsPool);
    }

    function setStakingPool (address _stakingPool) external onlyOwner {
        require (_stakingPool != address(0), "Staking Pool shouldn't be zero!");
        stakingPool = IEscrow(_stakingPool);
    }

    // Update Router
    function updateRouter (address _router) external onlyOwner {
        require (_router != address(0), "Router shouldn't be zero!");
        swapV2Router = IUniswapV2Router02(_router);
    }

    function updateOperationsWallet (address _wallet) external onlyOwner {
        require (_wallet != address(0), "Operation Wallet shouldn't be zero!");
        operationWallet = _wallet;
    }

    function updateLIOContract (address _lio) external onlyOwner {
        require (_lio != address(0), "LIO shouldn't be zero!");
        lio = _lio;
    }

    function addRewardToken (address _token) public virtual override onlyOwner {
        require (_token != address(0), "Token address shouldn't be zero!");
        rewardTokens.add(_token);
    }

    function addStakingToken (address _token) public virtual override onlyOwner {
        require (_token != address(0), "Token address shouldn't be zero!");
        stakingTokens.add(_token);
    }

    function removeRewardToken (address _token) external virtual override onlyOwner {
        rewardTokens.remove(_token);
        address[] memory currentStakingTokens = stakingTokens.values();
        for(uint256 i = 0; i < currentStakingTokens.length; ++i){
            rewardsPerStake[currentStakingTokens[i]][_token] = 0;
        }
    }

    function removeStakingToken (address _token) external virtual override onlyOwner {
        stakingTokens.remove(_token);
        address[] memory currentRewardsTokens = rewardTokens.values();
        for(uint256 i = 0; i < currentRewardsTokens.length; ++i){
            rewardsPerStake[_token][currentRewardsTokens[i]] = 0;
        }
    }

    function updateStakingRewards() private {
        addBonusRewardsFromEscrow();

        address[] memory stakingTokenAddresses = stakingTokens.values();
        address[] memory rewardsTokenAddresses = rewardTokens.values();

        uint256 arrayLength = stakingTokenAddresses.length;
        uint256[] memory totalStake = new uint256[](arrayLength);

        arrayLength = rewardsTokenAddresses.length;
        uint256[] memory totalNewRewards = new uint256[](arrayLength);

        uint256 stakingTokenCount = stakingTokenAddresses.length;

        for(uint256 i = 0; i < stakingTokenAddresses.length; ++i){
            uint256 balance = IERC20Upgradeable(stakingTokenAddresses[i]).balanceOf(address(stakingPool));
            totalStake[i] = balance;
            if(balance == 0){
                stakingTokenCount--;
            }
        }

        if(stakingTokenCount == 0){
            return;
        }

        for(uint256 i = 0; i < rewardsTokenAddresses.length; ++i){
            uint256 balance = IERC20Upgradeable(rewardsTokenAddresses[i]).balanceOf(address(rewardsPool));
            totalNewRewards[i] = balance;
            rewardsPool.transferTokenTo(rewardsTokenAddresses[i], address(this), balance);
        }

        for(uint256 i = 0; i < stakingTokenAddresses.length; ++i){
            for(uint256 j = 0; j < rewardsTokenAddresses.length; ++j){
                if(totalStake[i] != 0 && totalNewRewards[j] != 0){
                    rewardsPerStake[stakingTokenAddresses[i]][rewardsTokenAddresses[j]] +=
                        (totalNewRewards[j] * accuracyFactor / stakingTokenCount / totalStake[i]);
                }
            }
        }
    }

    function addBonusRewardsFromEscrow() internal {
        IEscrow basicRewardsEscrow = IEscrow(escrowPool);
        basicRewardsEscrow.transferMultiTokensToWithPercentage(
            rewardTokens.values(),
            address(rewardsPool),
            escrowBonusPercentage,
            denominator
        );
    }

    function setLastTime () external onlyOwner {
        lastTimeStamp = block.timestamp;
    }

    // chainlink checkKeepUp...
    function checkUpkeep (
        bytes calldata checkData
    ) external view override returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > distributeRewardsDuration;
        performData = checkData;

        return (upkeepNeeded, performData);
    }

    function performUpkeep (bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        require((block.timestamp - lastTimeStamp) > distributeRewardsDuration, "KeepUp requirement is not met!");

        if ((block.timestamp - lastTimeStamp) > distributeRewardsDuration) {
            updateStakingRewards();
        }
        lastTimeStamp = block.timestamp;
    }

    function addNewStaker (
        address _staker,
        address _token,
        uint256 _stakedAmount
    ) internal returns (bool) {
        StakeInfo storage stakeInfo = holderStakeInfo[_staker][_token];
        stakeInfo.startTS = block.timestamp;

        stakeInfo.amount = _stakedAmount;
        stakeInfo.unStaked = false;

        isStakedToken[_staker][_token] = true;

        updateStakerExclusions(stakeInfo, _token, _stakedAmount);
        return tokenStakers[_token].add(_staker);
    }

    function removeStaker (
        address _staker,
        address _token
    ) internal returns (bool) {

        isStakedToken[_staker][_token] = false;
        return tokenStakers[_token].remove(_staker);
    }

    // rewards process.
    function reintroduceFee (
        address _token,
        uint256 _totalAmount
    ) internal returns (uint256) {

        uint256 totalFeeAmount = 0;

        // Send 1% to LIO
        uint256 swapFeeAmountForLIO = _totalAmount * (reintroducePercentLIO) / (denominator);

        // Send 1% to Ops
        uint256 swapFeeAmountForOps = _totalAmount * (reintroducePercentOps) / (denominator);

        if((swapFeeAmountForOps + swapFeeAmountForLIO) > 0) {
            swapTokenToBNB(_token, swapFeeAmountForOps + swapFeeAmountForLIO, address(this));
        }

        // Send back 1% to rewards Pool
        uint256 amountForPool = _totalAmount * (reintroducePercentPool) / (denominator);
        IERC20Upgradeable(_token).transfer(address(rewardsPool), amountForPool);
        totalFeeAmount += (swapFeeAmountForOps + swapFeeAmountForLIO + amountForPool);

        return totalFeeAmount;
    }

    function stakeToken (
        address _token,
        uint256 _stakeAmount
    ) public {
        if(!stakingTokens.contains(_token)){
            revert("Not a staking token");
        }
        require(_stakeAmount > 0, "Stake amount should be correct");
        require(IERC20Upgradeable(_token).balanceOf(msg.sender) >= _stakeAmount, "Insufficient Balance");

        if(isStakedToken[msg.sender][_token] == false) { // if the user didn't stake this token
            addNewStaker(msg.sender, _token, _stakeAmount);
        } else { // if the user staked this token already
            StakeInfo storage stakeInfo = holderStakeInfo[msg.sender][_token];
            stakeInfo.startTS = block.timestamp;
            stakeInfo.amount += _stakeAmount;
            updateStakerExclusions(stakeInfo, _token, _stakeAmount);
        }

        // send token to staking pool
        IERC20Upgradeable(_token).transferFrom(msg.sender, address(stakingPool) , _stakeAmount);
    }

    function batchStakeTokens (
        address[] memory _tokens,
        uint256[] memory _stakeAmounts
    ) external virtual override whenNotPaused nonReentrant {
        for(uint256 i = 0; i < _tokens.length; ++i){
            stakeToken(_tokens[i], _stakeAmounts[i]);
        }
    }

    function unStakeWithRewards (
        address _token,
        uint256 _unStakingPercent
    ) external virtual override whenNotPaused nonReentrant returns (bool) {

        require( isStakedToken[msg.sender][_token] == true,  "Already unstaked" );

        uint256 stakedAmount = holderStakeInfo[msg.sender][_token].amount;
        uint256 unStakingAmount = stakedAmount;

        StakeInfo storage stakeInfo = holderStakeInfo[msg.sender][_token];

        if(_unStakingPercent < denominator) {
            unStakingAmount = stakedAmount * _unStakingPercent / denominator;
        }

        // Getting rewards
        claimRewards(msg.sender, _token);

        stakeInfo.amount -= unStakingAmount;

        if(_unStakingPercent == denominator) {
            removeStaker(msg.sender, _token);
            isStakedToken[msg.sender][_token] = false;
            stakeInfo.unStaked = true;
            stakeInfo.startTS = 0;
        } 
        
        _resetStakerExclusions(stakeInfo, _token);
        
        stakingPool.transferTokenTo(_token, msg.sender, unStakingAmount);

        return true;
    }

    function updateStakerExclusions(StakeInfo storage stakeInfo, address _token, uint256 _stakedAmount) private {
        address[] memory rewardsTokenAddresses = rewardTokens.values();

        for(uint256 i = 0; i < rewardsTokenAddresses.length; ++i){
            stakeInfo.totalExcluded[rewardsTokenAddresses[i]] += _stakedAmount * rewardsPerStake[_token][rewardsTokenAddresses[i]];
        }
    }

    function _resetStakerExclusions(StakeInfo storage stakeInfo, address _token) private {
        address[] memory rewardsTokenAddresses = rewardTokens.values();

        for(uint256 i = 0; i < rewardsTokenAddresses.length; ++i){
            stakeInfo.totalExcluded[rewardsTokenAddresses[i]] = stakeInfo.amount * rewardsPerStake[_token][rewardsTokenAddresses[i]];
        }
    }

    function _calculateRewardsForStake(StakeInfo storage _staker, address _stakedToken, address _rewardToken, bool _andClaim) private returns(uint256 amount){
        amount = _staker.amount * rewardsPerStake[_stakedToken][_rewardToken] - _staker.totalExcluded[_rewardToken];

        if(amount/accuracyFactor > 0){
            if(_andClaim) {
                _staker.totalExcluded[_rewardToken] += amount;
            }
            amount /= accuracyFactor;
        } else {
            amount = 0;
        }
    }

    function calculateRewardsForToken(address _stakerAddress, address _rewardToken) private view returns(uint256 amount){
        amount = 0;
        address[] memory stakeTokenAddress = stakingTokens.values();

        for(uint256 i = 0; i < stakeTokenAddress.length; ++i){
            StakeInfo storage stakeInfo =  holderStakeInfo[_stakerAddress][stakeTokenAddress[i]];
            uint256 pendingBalance = stakeInfo.amount * rewardsPerStake[stakeTokenAddress[i]][_rewardToken] - stakeInfo.totalExcluded[_rewardToken];
            if(pendingBalance > 0){
                amount += pendingBalance;
            }
        }
    }

    function _calculatePercentageRewardsForToken(address _stakerAddress, address _rewardToken, bool _andClaim, uint256 _claimPercentage, uint256 _denominator) private returns(uint256 amount){
        amount = 0;

        address[] memory stakeTokenAddress = stakingTokens.values();

        for(uint256 i = 0; i < stakeTokenAddress.length; ++i){
            StakeInfo storage stakeInfo =  holderStakeInfo[_stakerAddress][stakeTokenAddress[i]];
            uint256 pendingBalance = stakeInfo.amount * rewardsPerStake[stakeTokenAddress[i]][_rewardToken] - stakeInfo.totalExcluded[_rewardToken];
            if(pendingBalance / accuracyFactor > 0){
                if(_andClaim) {
                    stakeInfo.totalExcluded[_rewardToken] += pendingBalance * _claimPercentage / _denominator;
                }
                amount += pendingBalance * _claimPercentage / _denominator / accuracyFactor;
            }
        }
    }

    function claimRewards (
        address _staker,
        address _stakedToken
    ) internal {

        uint256 tokenCount = rewardTokens.length();
        StakeInfo storage staker = holderStakeInfo[_staker][_stakedToken];

        for (uint i = 0; i < tokenCount; ++i) {
            address token = rewardTokens.at(i);
            uint256 amount = _calculateRewardsForStake(staker, _stakedToken, token, true);

            if(amount > 0) {
                uint256 feeAmount = reintroduceFee(token, amount);
                IERC20Upgradeable(token).transfer(_staker, amount - feeAmount);
            }
        }

        sendFees();
    }

    // Withdraw rewards based on percentage
    function withdrawRewards (
        address _token,
        uint256 _withdrawPercent
    ) external virtual override whenNotPaused nonReentrant returns (bool) {
        address stakerAddr = msg.sender;
        uint256 withdrawAmount = _calculatePercentageRewardsForToken(stakerAddr, _token, true, _withdrawPercent, denominator);

        require(withdrawAmount > 0, "You have no rewards to withdraw!");

        uint256 withdrawFeeAmount = reintroduceFee(_token, withdrawAmount);

        sendFees();

        IERC20Upgradeable(_token).transfer(stakerAddr, withdrawAmount - withdrawFeeAmount);
        return true;
    }

    // Compound whole rewards
    function compoundRewards (
        address _token,
        uint256 _compoundPercent
    ) external virtual override whenNotPaused nonReentrant returns (bool) {

        address stakerAddr = msg.sender;
        uint256 compoundAmount = _calculatePercentageRewardsForToken(stakerAddr, _token, true, _compoundPercent, denominator);
        require(compoundAmount > 0, "You have no rewards to compound!");

        uint256 compoundFeeAmount = reintroduceFee(_token, compoundAmount);
        uint256 realCompoundAmount = compoundAmount - compoundFeeAmount;

        if(isStakedToken[stakerAddr][_token] == false) {
            addNewStaker(stakerAddr, _token, realCompoundAmount);
        } else {
            StakeInfo storage stakeInfo = holderStakeInfo[stakerAddr][_token];
            stakeInfo.startTS = block.timestamp;
            stakeInfo.amount += realCompoundAmount;
            updateStakerExclusions(stakeInfo, _token, realCompoundAmount);
        }

        sendFees();

        IERC20Upgradeable(_token).transfer(address(stakingPool), realCompoundAmount);

        return true;
    }

    function sendFees() internal virtual {
        uint256 totalTaxFees = reintroducePercentLIO + reintroducePercentOps;

        if(totalTaxFees > 0){
            uint256 amount = address(this).balance * (reintroducePercentOps) / (totalTaxFees);
            if(amount > 0){
                (bool success, ) = payable(operationWallet).call{value: amount}("");
                if(!success) {
                    revert("Transaction failure");
                }
            }

            amount = address(this).balance;
            if(amount > 0){
                (bool success, ) = payable(lio).call{value: amount}("");
                if(!success) {
                    revert("Transaction failure");
                }
            }
        }
    }

    function swapTokenToBNB (
        address _token,
        uint256 _amount,
        address _destination
    ) internal returns (bool) {

        uint deadline = block.timestamp + 4;
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = swapV2Router.WETH(); // testnet BNB: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd

        IERC20Upgradeable(_token).approve(address(swapV2Router), _amount);
        swapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_amount, 0, path, _destination, deadline);
        return true;
    }

    function getTotalStakedAmount (address _token) public view returns(uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(stakingPool));
    }

    function getTokenRewardsOfUser (address _wallet, address _token) public view returns (uint256) {
        return calculateRewardsForToken(_wallet, _token) / accuracyFactor;
    }

    function getTokenRewardsOfUserWithDecimals (address _wallet, address _token) public view returns (uint256) {
        return calculateRewardsForToken(_wallet, _token);
    }

    function getRemainingRewardsPool (address _token) public view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(this));
    }

    function getAvailableRewardTokens () public view returns(address[] memory) {
        return rewardTokens.values();
    }

    function getAvailableStakingTokens () public view returns(address[] memory) {
        return stakingTokens.values();
    }

    function getBNBBalanceOfWallet (address _wallet) public view returns (uint256) {
        return _wallet.balance;
    }

    function getTokenBalanceOfStakingPool (address _token) public view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(stakingPool));
    }

     function getTokenBalanceOfRewardsPool (address _token) public view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(rewardsPool));
    }

    function getStakedTokenAmount (
        address _wallet,
        address _token
    ) external override view returns (uint256) {
        return holderStakeInfo[_wallet][_token].amount;
    }

    function pause () external onlyOwner {
        _pause();
    }

    function unpause () external onlyOwner {
        _unpause();
    }

    function getTokenStakerCount (address _token) external view returns (uint256) {
        return tokenStakers[_token].length();
    }
}