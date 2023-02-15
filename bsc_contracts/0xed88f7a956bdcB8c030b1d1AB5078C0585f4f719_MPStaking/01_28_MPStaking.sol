// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IMPStaking.sol";
import "./interfaces/IEscrow.sol";
import "./Escrow.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";


contract MPStaking is
    IMPStaking,
    Initializable,
    KeeperCompatible,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;

    IUniswapV2Router02 public swapV2Router;

    address public operationWallet;
    address public stakingPool;
    address public lio;

    address public escrowPool;

    /**
    * 10000 wei is equivalent to 100%
    * 1000 wei is equivalent to 10%
    * 100 wei is equivalent to 1%
    * 10 wei is equivalent to 0.1%
    * 1 wei is equivalent to 0.01%
    */

    uint256 public reintroducePercentOps;
    uint256 public reintroducePercentLIO;
    uint256 public reintroducePercentPool;

    uint256 public percentToppingUpPoolFromEscrow;

    uint256 public denominator;

    uint256 public distributeRewardsDuration;
    uint256 public lastTimeStamp;

    struct StakeInfo {
        address token;                                              // BEP Pegged Token to stake
        uint256 startTS;                                            // start time
        uint256 amount;                                             // staking amount
        mapping(address => uint256) rewards;                        // amount for rewards (availableToken => amount))
        bool unStaked;                                              // is unstaked?
    }

    address[] availableMirrorTokens;

    mapping(address => mapping(address => StakeInfo)) stakeInfos; // User wallet => (BEP Pegged Token => StakeInfo)
    mapping(address => mapping(address => bool)) isStakedToken; // User wallet => (BEP Pegged Token => bool)

    mapping(address => uint256) totalStakedAmount; // Token => amount
    mapping(address => uint256) totalFeeAmountOfStakingPool; // token => amount

    mapping(address => mapping(address => uint256)) userTotalRewardsPerToken; // User wallet => (Token => amount)

    mapping(address => address[]) tokenStakers; // token => user array
    // Index in array of staker (Prevents looping for gas savings) Not 0 indexed for existence check.
    mapping(address => mapping(address => uint256)) private stakerIndex;

    mapping (address => uint256) prevTotalRewards; // token => amount

    event Staked(
        address indexed from,
        uint256 amount,
        address token
    );
    event UnStaked(
        address indexed from,
        uint256 amount,
        address token
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize (
        address _escrowOwner,
        address _operationWallet,
        address _lio,
        address _router
    ) initializer external virtual {
        __MPStaking_init(_escrowOwner, _operationWallet, _lio, _router);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade (address newImplementation)
        internal
        override
        onlyOwner
    {}

    function __MPStaking_init (
        address _escrowOwner,
        address _operationWallet,
        address _lio,
        address _router
    ) internal {
        __Ownable_init();
        __MPStaking_init_unchained(_escrowOwner, _operationWallet, _lio, _router);
    }

    function __MPStaking_init_unchained (
        address _escrowOwner,
        address _operationWallet,
        address _lio,
        address _router
    ) internal {
        operationWallet = _operationWallet;
        lio = _lio;

        // deploy staking pool
        Escrow stakingEscrow = new Escrow(_escrowOwner);
        stakingPool = address(stakingEscrow);

        // deploy escrowPool
        Escrow rewardsEscrow = new Escrow(_escrowOwner);
        escrowPool = address(rewardsEscrow);

        distributeRewardsDuration = 1 days;

        denominator = 10000; // 100/10000 = 1%

        reintroducePercentLIO = 100; // 1%
        reintroducePercentOps = 100; // 1%
        reintroducePercentPool = 100; // 1%

        percentToppingUpPoolFromEscrow = 100; // 1%

        // BNB PCS mainnet router (pancake)   : 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // BNB PCS testnet router (pancake)   : 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        // BNB SFM mainnent router (safemoon) : 0x6AC68913d8FcCD52d196B09e6bC0205735A4be5f
        // ETH mainnet router (uniswap)       : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        // Goerli Testnet router (uniswap)    : 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        swapV2Router = IUniswapV2Router02(_router);

        lastTimeStamp = block.timestamp;
    }

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
        distributeRewardsDuration = _duration;
    }

    function setDenominator (uint256 _denominator) external onlyOwner {
        denominator = _denominator;
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

    function setPercentToppingUpPoolFromEscrow (uint256 _percentToppingUpPoolFromEscrow) external onlyOwner {
        require(
            _percentToppingUpPoolFromEscrow >= 0 &&  _percentToppingUpPoolFromEscrow < denominator,
            "Percentage range should be between 0% and 100%"
        );
        percentToppingUpPoolFromEscrow = _percentToppingUpPoolFromEscrow;
    }

    function setEscrowPool (address _escrowPool) external onlyOwner {
        escrowPool = _escrowPool;
    }

    // Update Router
    function updateRouter (address _router) external onlyOwner {
        swapV2Router = IUniswapV2Router02(_router);
    }

    function updateOperationsWallet (address _wallet) external onlyOwner {
        operationWallet = _wallet;
    }

    function updateStakingPool (address _stakingPool) external onlyOwner {
        stakingPool = _stakingPool;
    }

    function updateLIOContract (address _lio) external onlyOwner {
        lio = _lio;
    }

    function addToken (address _token) external virtual override onlyOwner {
        availableMirrorTokens.push(_token);
    }

    function removeToken (address _token) external virtual override onlyOwner {
        uint256 tokenCount = availableMirrorTokens.length;
        for(uint256 i = 0; i < tokenCount; ++i){
            if(availableMirrorTokens[i] == _token){
                availableMirrorTokens[i] = availableMirrorTokens[tokenCount - 1];
                availableMirrorTokens.pop();
                break;
            }
        }
    }

    function addTokens (address[] memory _tokens) external virtual override onlyOwner {
        for (uint idx = 0; idx < _tokens.length; idx ++) {
            availableMirrorTokens.push(_tokens[idx]);
        }
    }

    function getStakedTokenCount () internal view returns (uint256) {
        uint stakedTokenCount = 0;
        uint256 tokenCount = availableMirrorTokens.length;
        for(uint i = 0; i < tokenCount; i ++) {
            address token = availableMirrorTokens[i];
            if(getTotalStakedAmount(token) > 0) {
                stakedTokenCount++;
            }
        }
        return stakedTokenCount;
    }

    function distributeRewardsPerToken (address _stakedToken) internal {
        uint256 stakedTokenCount = getStakedTokenCount();
        address[] storage stakers = tokenStakers[_stakedToken];
        uint256 stakerCount = stakers.length;
        uint256 tokenCount = availableMirrorTokens.length;

        for(uint i = 0; i < tokenCount; i ++) {
            address token = availableMirrorTokens[i];
            uint256 currentRewardsBalance = IERC20Upgradeable(token).balanceOf(address(this));
            uint256 rewardsAmount = (currentRewardsBalance - prevTotalRewards[token]) / stakedTokenCount;

            if(rewardsAmount > 0) {
                for(uint j = 0; j < stakerCount; j ++) {
                    StakeInfo storage staker = stakeInfos[stakers[j]][_stakedToken];
                    uint256 percentOfStaked = staker.amount.mul(denominator).div(totalStakedAmount[_stakedToken]);
                    uint256 rewardsPerToken = rewardsAmount.mul(percentOfStaked).div(denominator);
                    staker.rewards[token] += rewardsPerToken;
                    userTotalRewardsPerToken[stakers[j]][token] += rewardsPerToken;
                }
            }
        }
    }

    function toppingUpPoolFromEscrowPool () internal {
        IEscrow basicRewardsEscrow = IEscrow(escrowPool);
        basicRewardsEscrow.transferMultiTokensToWithPercentage(
            availableMirrorTokens,
            address(this),
            percentToppingUpPoolFromEscrow,
            denominator
        );
    }

    function distributeRewardsAllTokens () internal {
        uint256 tokenCount = availableMirrorTokens.length;

        for(uint i = 0; i < tokenCount; i ++) {
            address token = availableMirrorTokens[i];
            if(getTotalStakedAmount(token) > 0) {
                distributeRewardsPerToken(token);
            }
        }

        // set current balance as prev

        for(uint i = 0; i < tokenCount; i ++) {
            address token = availableMirrorTokens[i];
            uint256 currentRewardsBalance = IERC20Upgradeable(token).balanceOf(address(this));

            prevTotalRewards[token] = currentRewardsBalance;
        }

        if(percentToppingUpPoolFromEscrow > 0) {
            toppingUpPoolFromEscrowPool();
        }
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
            lastTimeStamp = block.timestamp;
            distributeRewardsAllTokens();
        }
    }

    function addNewStaker (
        address _staker,
        address _token,
        uint256 _stakedAmount
    ) internal returns (bool) {
        StakeInfo storage stakeInfo = stakeInfos[_staker][_token];
        stakeInfo.startTS = block.timestamp;

        stakeInfo.token = _token;
        stakeInfo.amount = _stakedAmount;
        stakeInfo.unStaked = false;

        isStakedToken[_staker][_token] = true;
        tokenStakers[_token].push(_staker);
        stakerIndex[_token][_staker] = tokenStakers[_token].length; // Index after expanding array, index+1

        return true;
    }

    function removeStaker (
        address _staker,
        address _token
    ) internal returns (bool) {

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

        return true;
    }

    // rewards process.
    function reintroduceFee (
        address _token,
        uint256 _totalAmount
    ) internal returns (uint256) {

        uint256 totalFeeAmount = 0;

        // Send 1% to LIO
        uint256 swapFeeAmountForLIO = _totalAmount.mul(reintroducePercentLIO).div(denominator);
        if(swapFeeAmountForLIO > 0) {
            swapTokenToBNB(_token, swapFeeAmountForLIO, lio);
            totalFeeAmount += swapFeeAmountForLIO;
        }

        // Send 1% to Ops
        uint256 swapFeeAmountForOps = _totalAmount.mul(reintroducePercentOps).div(denominator);
        if(swapFeeAmountForOps > 0) {
            swapTokenToBNB(_token, swapFeeAmountForOps, operationWallet);
            totalFeeAmount += swapFeeAmountForOps;
        }

        // Send back 1% to rewards Pool
        uint256 amountForPool = _totalAmount.mul(reintroducePercentPool).div(denominator);
        // IERC20Upgradeable(_token).transfer(stakingPool, amountForPool);
        totalFeeAmount += amountForPool;

        //totalFeeAmountOfStakingPool[_token] += amountForPool;

        return totalFeeAmount;
    }

    function stakeToken (
        address _token,
        uint256 _stakeAmount
    ) external virtual override whenNotPaused nonReentrant {

        require(_stakeAmount > 0, "Stake amount should be correct");
        require(IERC20Upgradeable(_token).balanceOf(msg.sender) >= _stakeAmount, "Insufficient Balance");

        // add total amounts
        totalStakedAmount[_token] += _stakeAmount;

        if(isStakedToken[msg.sender][_token] == false) { // if the user didn't stake this token
            addNewStaker(msg.sender, _token, _stakeAmount);
        } else { // if the user staked this token already
            stakeInfos[msg.sender][_token].startTS = block.timestamp;
            stakeInfos[msg.sender][_token].amount += _stakeAmount;
        }

        // send token to staking pool
        IERC20Upgradeable(_token).transferFrom(msg.sender, stakingPool , _stakeAmount);

        emit Staked(msg.sender, _stakeAmount, _token);
    }

    function unStakeWithRewards (
        address _token,
        uint256 _unStakingPercent
    ) external virtual override whenNotPaused nonReentrant returns (bool) {

        require( isStakedToken[msg.sender][_token] == true,  "Already unstaked" );

        uint256 stakedAmount = stakeInfos[msg.sender][_token].amount;
        uint256 unStakingAmount = stakedAmount;

        if(_unStakingPercent < denominator) {
            unStakingAmount = stakedAmount.mul(_unStakingPercent).div(denominator);
        }

        // Getting rewards
        claimRewards(msg.sender, _token);

        IEscrow stakingEscrow = IEscrow(stakingPool);

        if(_unStakingPercent == denominator) {
            removeStaker(msg.sender, _token);
            isStakedToken[msg.sender][_token] = false;
            stakeInfos[msg.sender][_token].unStaked = true;
        }

        totalStakedAmount[_token] -= unStakingAmount;
        stakeInfos[msg.sender][_token].amount -= unStakingAmount;

        stakingEscrow.transferTokenTo(_token, msg.sender, unStakingAmount);

        emit UnStaked(msg.sender, unStakingAmount, _token);

        return true;
    }

    function claimRewards (
        address _staker,
        address _stakedToken
    ) internal {

        uint256 tokenCount = availableMirrorTokens.length;
        StakeInfo storage staker = stakeInfos[_staker][_stakedToken];

        for (uint idx = 0; idx < tokenCount; idx ++) {
            address token = availableMirrorTokens[idx];
            uint256 amount = staker.rewards[token];

            prevTotalRewards[token] -= amount;
            staker.rewards[token] -= amount;

            if(userTotalRewardsPerToken[_staker][token] >= amount) {
                userTotalRewardsPerToken[_staker][token] -= amount;
            }
            else {
                userTotalRewardsPerToken[_staker][token] = 0;
            }

            if(amount > 0) {
                uint256 feeAmount = reintroduceFee(token, amount);
                IERC20Upgradeable(token).transfer(_staker, amount - feeAmount);
            }
        }
    }

    // Withdraw rewards based on percentage
    function withdrawRewards (
        address _token,
        uint256 _withdrawPercent
    ) external virtual override whenNotPaused nonReentrant returns (bool) {

        address stakerAddr = msg.sender;
        uint256 rewardsAmount = userTotalRewardsPerToken[stakerAddr][_token];
        require(rewardsAmount > 0, "You have no rewards to withdraw!");

        uint256 withdrawAmount = rewardsAmount.mul(_withdrawPercent).div(denominator);

        uint256 tokenCount = availableMirrorTokens.length;
        for(uint idx = 0; idx < tokenCount; idx ++) {
            StakeInfo storage staker = stakeInfos[stakerAddr][availableMirrorTokens[idx]];
            uint256 amount = staker.rewards[_token];
            if(amount > 0) {
                staker.rewards[_token] -= amount.mul(_withdrawPercent).div(denominator);
            }
        }

        uint256 withdrawFeeAmount = reintroduceFee(_token, withdrawAmount);

        userTotalRewardsPerToken[stakerAddr][_token] -= withdrawAmount;
        prevTotalRewards[_token] -= withdrawAmount;

        IERC20Upgradeable(_token).transfer(stakerAddr, withdrawAmount - withdrawFeeAmount);
        return true;
    }

    // Compound whole rewards
    function compoundRewards (
        address _token,
        uint256 _compoundPercent
    ) external virtual override whenNotPaused nonReentrant returns (bool) {

        address stakerAddr = msg.sender;

        uint256 rewardsAmount = userTotalRewardsPerToken[stakerAddr][_token];

        require(rewardsAmount > 0, "You have no rewards to withdraw!");

        uint256 compoundAmount = rewardsAmount.mul(_compoundPercent).div(denominator);

        uint256 tokenCount = availableMirrorTokens.length;
        for(uint idx = 0; idx < tokenCount; idx ++) {
            StakeInfo storage staker = stakeInfos[stakerAddr][availableMirrorTokens[idx]];
            uint256 amount = staker.rewards[_token];
            if(amount > 0) {
                staker.rewards[_token] -= amount.mul(_compoundPercent).div(denominator);
            }
        }

        uint256 compoundFeeAmount = reintroduceFee(_token, compoundAmount);
        uint256 realCompoundAmount = compoundAmount - compoundFeeAmount;

        totalStakedAmount[_token] += realCompoundAmount;

        if(isStakedToken[stakerAddr][_token] == false) {
            addNewStaker(stakerAddr, _token, realCompoundAmount);
        } else {
            stakeInfos[stakerAddr][_token].amount += realCompoundAmount;
        }

        userTotalRewardsPerToken[stakerAddr][_token] -= compoundAmount;
        prevTotalRewards[_token] -= compoundAmount;

        IERC20Upgradeable(_token).transfer(stakingPool, realCompoundAmount);

        return true;
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
        return totalStakedAmount[_token];
    }

    function getTokenRewardsOfUser (address _wallet, address _token) public view returns (uint256) {
        return userTotalRewardsPerToken[_wallet][_token];
    }

    function getRemainingRewardsPool (address _token) public view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(this)) - prevTotalRewards[_token];
    }

    function getPreTotalRewards (address _token) public view returns (uint256) {
        return prevTotalRewards[_token];
    }

    function getAvailableTokens () public view returns(address[] memory) {
        return availableMirrorTokens;
    }

    function getBNBBalanceOfWallet (address _wallet) public view returns (uint256) {
        return _wallet.balance;
    }

    function getTokenBalanceOfStakingPool (address _token) public view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(stakingPool);
    }

    function getStakedTokenAmount (
        address _wallet,
        address _token
    ) external override view returns (uint256) {
        return stakeInfos[_wallet][_token].amount;
    }

    function pause () external onlyOwner {
        _pause();
    }

    function unpause () external onlyOwner {
        _unpause();
    }
}