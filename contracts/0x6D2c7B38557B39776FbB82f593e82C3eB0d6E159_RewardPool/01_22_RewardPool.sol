// SPDX-License-Identifier: MIT

// Rewards Pool is a community based experiment project.

pragma solidity 0.8.13;

import "./RewardDistributor.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IRewardDistributor.sol";
import "./library/IterableMapping.sol";
import "./library/SafeMathInt.sol";
import "./library/SafeMathUint.sol";
import "./RewardDistributor.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RewardPool is Initializable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuard {
    using SafeMath for uint256;   
    using SafeMathInt for int256; 
    using SafeMathUint for uint256;
    using IterableMapping for IterableMapping.Map;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    address public nativeAsset;
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD; 
    uint256 internal constant magnitude = 2**128;
    uint256 internal constant distributeSharePrecision = 100;
    uint256 public buyBackWait;
    uint256 public lastBuyBackTimestamp;
    uint256 public minimumCoinBalanceForBuyback;
    uint256 public maximumCoinBalanceForBuyback;
    uint256 public gasForProcessing;
    uint8 public totalRewardDistributor;

    bool private swapping;

    struct rewardStore {
        address rewardDistributor;
        uint256 distributeShare;
        uint256 claimWait;
        uint256 lastProcessedIndex;
        uint256 minimumTokenBalanceForRewards;
        uint256 magnifiedRewardPerShare;
        uint256 totalRewardsDistributed;
        uint256 totalSupply;
        uint8 index;
        bool isRemoved;
        bool isActive;
    }

    struct distributeStore {
        uint256 lastClaimTimes;
        int256 magnifiedRewardCorrections;
        uint256 withdrawnRewards;
        uint256 balanceOf;
    }

    mapping (address => rewardStore) private _rewardInfo;
    mapping (uint8 => address) private _rewardAsset; 
    mapping (bytes32 => distributeStore) private _distributeInfo; 
    mapping (address => bool) private excludedFromRewards;
    mapping (address => IterableMapping.Map) private tokenHoldersMap;

    event ExcludeFromRewards(address indexed account, bool isExcluded);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SendRewards(uint256 tokensSwapped,uint256 amount);
    event Claim(address indexed account, uint256 amount, bool indexed automatic); 
    event RewardsDistributed(address indexed from,uint256 weiAmount);
    
    receive() external payable {}

    modifier onlyOperator() {
        require((msg.sender == owner()) || 
                (msg.sender == nativeAsset), "unable to access");
        _;
    }

    function initialize(address _nativeAsset) initializer public {
        __Pausable_init();
        __Ownable_init();

        nativeAsset = _nativeAsset;
        buyBackWait = 86400;
        minimumCoinBalanceForBuyback = 10;
        maximumCoinBalanceForBuyback = 80;
        gasForProcessing = 300000;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(uniswapV2Router.WETH(),_nativeAsset);

        _excludedFromRewards(address(this),true);
        _excludedFromRewards(owner(),true);
        _excludedFromRewards(deadWallet,true);
        _excludedFromRewards(address(uniswapV2Router),true);
        _excludedFromRewards(address(uniswapV2Pair),true);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function recoverLeftOverCoinAmount(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    function recoverLeftOverToken(address token,uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(),amount);
    }

    function setBalanceForBuyback(uint256 newMinValue,uint256 newMaxValue) external onlyOwner {
        require(newMinValue != 0 && newMaxValue != 0, "RewardPool: Can't be zero");
        require(newMinValue < newMaxValue, "RewardPool: Invalid Amount");

        minimumCoinBalanceForBuyback = newMinValue;
        maximumCoinBalanceForBuyback = newMaxValue;
    }

    function setMinimumTokenBalanceForRewards(address reward,uint256 newValue) external onlyOwner {
        _rewardInfo[reward].minimumTokenBalanceForRewards = newValue;
    }

    function validateDistributeShare(uint256 newShare) public view returns (bool) {
        uint256 currenShares = newShare;
        for(uint8 i;i<totalRewardDistributor;i++) {
            currenShares = currenShares.add(_rewardInfo[_rewardAsset[i]].distributeShare);
        }
        return (currenShares <= distributeSharePrecision);
    }

    function setDistributeShare(address rewardToken,uint256 newShare) external onlyOwner {
        require(_rewardInfo[rewardToken].isActive, "RewardPool: Reward Token is invalid");
        _rewardInfo[rewardToken].distributeShare = newShare;
        require(validateDistributeShare(0), "RewardPool: DistributeShare is invalid");
    }

    function setBuyBackWait(uint256 newBuyBackWait) external onlyOwner {
        buyBackWait = newBuyBackWait;
    }

    function createRewardDistributor(
        address _rewardToken,
        uint256 _distributeShare,
        uint256 _claimWait,
        uint256 _minimumTokenBalanceForRewards
    ) external onlyOwner returns (address){
        require(validateDistributeShare(_distributeShare), "RewardPool: DistributeShare is invalid");
        require(_rewardInfo[_rewardToken].rewardDistributor == address(0), "RewardPool: RewardDistributor is already exist");
        require(totalRewardDistributor < 10, "RewardPool: Reward token limit exceed");

        RewardDistributor newRewardsDistributor = new RewardDistributor(_rewardToken);

        _rewardAsset[totalRewardDistributor] = _rewardToken;
        _rewardInfo[_rewardToken] = (
            rewardStore({
                rewardDistributor: address(newRewardsDistributor),
                distributeShare: _distributeShare,
                claimWait: _claimWait,
                lastProcessedIndex : 0,
                minimumTokenBalanceForRewards : _minimumTokenBalanceForRewards,
                magnifiedRewardPerShare : 0,
                totalRewardsDistributed : 0,
                totalSupply: 0,
                index: totalRewardDistributor,
                isRemoved : false,
                isActive: true
            })
        ); 
        totalRewardDistributor++;

        // exclude from receiving rewards
        _excludedFromRewards((address(newRewardsDistributor)),true);
        return address(newRewardsDistributor);
    }

    function removeRewardToken(
        address rewardToken
    ) external onlyOwner {
        require(_rewardInfo[rewardToken].rewardDistributor != address(0), "RewardPool: RewardDistributor is already exist");
        require(!_rewardInfo[rewardToken].isRemoved, "RewardPool: Already Removed");


        uint8 index = _rewardInfo[rewardToken].index;
        _rewardAsset[index] = _rewardAsset[totalRewardDistributor - 1];
        _rewardInfo[_rewardAsset[totalRewardDistributor - 1]].index = index;

        _rewardInfo[rewardToken].isRemoved = true;
        _rewardInfo[rewardToken].isActive = false;
        totalRewardDistributor--;
    }

    function migarateDistributor(
        address _oldRewardToken,
        address _newRewardToken,
        uint256 _distributeShare,
        uint256 _claimWait,
        uint256 _minimumTokenBalanceForRewards
    ) external onlyOwner returns (address){       
        require(_rewardInfo[_oldRewardToken].rewardDistributor != address(0), "RewardPool: RewardDistributor is already exist");
        require(_oldRewardToken != _newRewardToken, "Not be Same");
        require(!_rewardInfo[_oldRewardToken].isRemoved && !_rewardInfo[_newRewardToken].isRemoved, "RewardPool: Already Removed");

        RewardDistributor newRewardsDistributor = new RewardDistributor(_newRewardToken);

        _rewardInfo[_oldRewardToken].isRemoved = true;
        _rewardInfo[_oldRewardToken].isActive = false;

        _rewardAsset[_rewardInfo[_oldRewardToken].index] = _newRewardToken;
        _rewardInfo[_newRewardToken] = (
            rewardStore({
                rewardDistributor: address(newRewardsDistributor),
                distributeShare: _distributeShare,
                claimWait: _claimWait,
                lastProcessedIndex : 0,
                minimumTokenBalanceForRewards : _minimumTokenBalanceForRewards,
                magnifiedRewardPerShare : 0,
                totalRewardsDistributed : 0,
                totalSupply: 0,
                index : _rewardInfo[_oldRewardToken].index,
                isRemoved : false,
                isActive: true
            })
        ); 

        require(validateDistributeShare(0), "RewardPool: DistributeShare is invalid");
        _excludedFromRewards((address(newRewardsDistributor)),true);
        return address(newRewardsDistributor);
    }

    function setRewardActiveStatus(address rewardAsset,bool status) external onlyOwner {
        _rewardInfo[rewardAsset].isActive = status;
    }

    function getBuyBackLimit(uint256 currentBalance) internal view returns (uint256,uint256) {
        return (currentBalance.mul(minimumCoinBalanceForBuyback).div(1e2),
                currentBalance.mul(maximumCoinBalanceForBuyback).div(1e2));
    }

    function generateBuyBackForOpen() external whenNotPaused nonReentrant {
        require(lastBuyBackTimestamp.add(buyBackWait) < block.timestamp, "RewardPool: buybackclaim still not over");

        uint256 initialBalance = address(this).balance;

        (uint256 _minimumCoinBalanceForBuyback,) = getBuyBackLimit(initialBalance);

        require(initialBalance >= _minimumCoinBalanceForBuyback, "RewardPool: Required Minimum BuyBack Amount");
        lastBuyBackTimestamp = block.timestamp;

        for(uint8 i; i<totalRewardDistributor; i++) {
            address rewardToken = _rewardAsset[i];
            if(_rewardInfo[rewardToken].isActive && _rewardInfo[rewardToken].totalSupply > 0) {                
                swapAndSendReward(
                    rewardToken,
                    _minimumCoinBalanceForBuyback.mul(_rewardInfo[rewardToken].distributeShare).div(1e2)
                );
            }
        }
    }

    function generateBuyBack(uint256 buyBackAmount) external whenNotPaused onlyOwner nonReentrant {
        require(lastBuyBackTimestamp.add(buyBackWait) < block.timestamp, "RewardPool: buybackclaim still not over");

        uint256 initialBalance = address(this).balance;

        (uint256 _minimumCoinBalanceForBuyback,uint256 _maximumCoinBalanceForBuyback) = getBuyBackLimit(initialBalance);

        require(initialBalance > _minimumCoinBalanceForBuyback, "RewardPool: Required Minimum BuyBack Amount");

        lastBuyBackTimestamp = block.timestamp;
        buyBackAmount = buyBackAmount > _maximumCoinBalanceForBuyback ? 
                            _maximumCoinBalanceForBuyback : 
                            buyBackAmount > _minimumCoinBalanceForBuyback ? buyBackAmount : _minimumCoinBalanceForBuyback;
        
        for(uint8 i; i<totalRewardDistributor; i++) {
            address rewardToken = _rewardAsset[i];
            if(_rewardInfo[rewardToken].isActive && _rewardInfo[rewardToken].totalSupply > 0) {                
                swapAndSendReward(
                    rewardToken,
                    buyBackAmount.mul(_rewardInfo[rewardToken].distributeShare).div(1e2)
                );
            }
        }
    }

    function setPairAndRouter(address _uniswapV2Router,address _uniswapV2Pair) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        uniswapV2Pair = _uniswapV2Pair;

        _excludedFromRewards(address(uniswapV2Router),true);
        _excludedFromRewards(address(uniswapV2Pair),true);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue != gasForProcessing, "RewardPool: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(address rewardToken,uint256 claimWait) external onlyOwner {
        _rewardInfo[rewardToken].claimWait = claimWait;
    }

    function getClaimWait(address rewardToken) external view returns(uint256) {
        return _rewardInfo[rewardToken].claimWait;        
    }

    function getTotalRewardsDistributed(address reward) external view returns (uint256) {
        return IRewardDistributor(_rewardInfo[reward].rewardDistributor).totalRewardsDistributed();
    }

    function _excludedFromRewards(address account,bool status) internal {
        excludedFromRewards[account] = status;

        emit ExcludeFromRewards(account,status);

        if(status) {
            for(uint8 i;i<totalRewardDistributor;i++) {
                address reward = _rewardAsset[i];
                bytes32 slot = getDistributeSlot(reward,account);
                
                tokenHoldersMap[reward].remove(account);
                _setBalance(reward,slot,0);
            }
        }else {
            uint256 newBalance = IERC20(nativeAsset).balanceOf(account);

            for(uint8 i;i<totalRewardDistributor;i++) {
                address reward = _rewardAsset[i];
                bytes32 slot = getDistributeSlot(reward,account);

                if(newBalance >= _rewardInfo[reward].minimumTokenBalanceForRewards) {
                    tokenHoldersMap[reward].set(account, newBalance);
                    _setBalance(reward,slot,newBalance);
                }else {
                    tokenHoldersMap[reward].remove(account);
                    _setBalance(reward,slot,0);
                }
            }
        }
    }

	function excludeFromRewards(address account) external onlyOwner{
        _excludedFromRewards(account,true);
	}

    function includeInRewards(address account) external onlyOwner{
       _excludedFromRewards(account,false);
	}
    	
    function getAccountRewardsInfo(address reward,address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableRewards,
            uint256 totalRewards,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap[reward].getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > _rewardInfo[reward].lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(_rewardInfo[reward].lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap[reward].keys.length > _rewardInfo[reward].lastProcessedIndex ? 
                            tokenHoldersMap[reward].keys.length.sub(_rewardInfo[reward].lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        bytes32 slot = getDistributeSlot(reward,account);
        withdrawableRewards = withdrawableRewardOf(reward,account);
        totalRewards = accumulativeRewardOf(reward,slot);

        lastClaimTime = _distributeInfo[slot].lastClaimTimes;

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(_rewardInfo[reward].claimWait) : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function accumulativeRewardOf(address reward,bytes32 slot) internal view returns (uint256) {
        return (
        (_rewardInfo[reward].magnifiedRewardPerShare.mul(_distributeInfo[slot].balanceOf).toInt256Safe()
             .add(_distributeInfo[slot].magnifiedRewardCorrections).toUint256Safe() / magnitude)
        );
    }

    function getAccountRewardsInfoAtIndex(address reward,uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap[reward].size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap[reward].getKeyAtIndex(index);

        return getAccountRewardsInfo(reward,account);
    }

    function removedTokenRewardClaim(address rewardToken) external whenNotPaused nonReentrant{
        require(_rewardInfo[rewardToken].isRemoved, "RewardPool: Pool is not active");
        _updateBalanceForRemomvedToken(rewardToken,msg.sender,IERC20(nativeAsset).balanceOf(msg.sender));
        _withdrawRewardsOfUser(rewardToken,_msgSender(),false);
    }

    function singleRewardClaimByUser(address rewardToken) external whenNotPaused nonReentrant{
        require(_rewardInfo[rewardToken].isActive, "RewardPool: Pool is not active");
        _updateBalance(msg.sender,IERC20(nativeAsset).balanceOf(msg.sender));
        _withdrawRewardsOfUser(rewardToken,_msgSender(),false);
    }

    function multipleRewardClaimByUser() external whenNotPaused nonReentrant{
        address user = _msgSender();
        _updateBalance(user,IERC20(nativeAsset).balanceOf(user));
        for(uint8 i;i<totalRewardDistributor;i++) {
            if(_rewardInfo[_rewardAsset[i]].isActive) { 
                _withdrawRewardsOfUser(_rewardAsset[i],user,false);
            }
        }  
    }

    function getLastProcessedIndex(address rewardToken) external view returns(uint256) {
    	return _rewardInfo[rewardToken].lastProcessedIndex;
    }

    function totalHolderSupply(address rewardToken) external view returns (uint256) {
        return _rewardInfo[rewardToken].totalSupply;
    }

    function getNumberOfTokenHolders(address reward) public view returns(uint256) {
        return tokenHoldersMap[reward].keys.length;
    }

    function canAutoClaim(uint256 claimWait,uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
 
    function autoDistribute(address rewardToken) external returns (uint256, uint256, uint256) {
        require(_rewardInfo[rewardToken].isActive, "RewardPool: Pool is not active");
        uint256 gas = gasForProcessing;
    	uint256 numberOfTokenHolders = tokenHoldersMap[rewardToken].keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, _rewardInfo[rewardToken].lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = _rewardInfo[rewardToken].lastProcessedIndex;
    	uint256 gasUsed = 0;
    	uint256 gasLeft = gasleft();
    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap[rewardToken].keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap[rewardToken].keys[_lastProcessedIndex];
    		
    		if(_withdrawRewardsOfUser(rewardToken,account, true)) {
    				claims++;
    		}

    		iterations++;
    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	_rewardInfo[rewardToken].lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, _rewardInfo[rewardToken].lastProcessedIndex);
    }

    function setBalance(address account, uint256 newBalance) external onlyOperator {
        _updateBalance(account,newBalance);
    }

    function updateBalance() external whenNotPaused{
        _updateBalance(_msgSender(),IERC20(nativeAsset).balanceOf(_msgSender()));
    }

    function updateBalanceForAll(address[] memory accounts) external whenNotPaused{
        for(uint256 i;i<accounts.length;i++) {
            _updateBalance(accounts[i],IERC20(nativeAsset).balanceOf(accounts[i]));
        }
    }

    function _updateBalanceForRemomvedToken(address reward,address account, uint256 newBalance) internal {
    	if(excludedFromRewards[account]) {
    		return;
    	}

        if(newBalance >= _rewardInfo[reward].minimumTokenBalanceForRewards) {
            tokenHoldersMap[reward].set(account, newBalance);
            _setBalance(reward,getDistributeSlot(reward,account),newBalance);
        }else {
            tokenHoldersMap[reward].remove(account);
            _setBalance(reward,getDistributeSlot(reward,account),0);
        }  	
    }

    function _updateBalance(address account, uint256 newBalance) internal {
    	if(excludedFromRewards[account]) {
    		return;
    	}

        for(uint8 i;i<totalRewardDistributor;i++) {
            address reward = _rewardAsset[i];
            if(newBalance >= _rewardInfo[reward].minimumTokenBalanceForRewards) {
            	tokenHoldersMap[reward].set(account, newBalance);
                _setBalance(reward,getDistributeSlot(reward,account),newBalance);
            }else {
            	tokenHoldersMap[reward].remove(account);
                _setBalance(reward,getDistributeSlot(reward,account),0);
            }
        }    	
    }

    function _setBalance(address reward,bytes32 slot,uint256 newBalance) internal {      
        uint256 currentBalance = _distributeInfo[slot].balanceOf;

        if(newBalance > currentBalance) {
            uint256 mintAmount = newBalance - currentBalance;
            {
                _rewardInfo[reward].totalSupply += mintAmount;
                _distributeInfo[slot].balanceOf += mintAmount;
                _distributeInfo[slot].magnifiedRewardCorrections = _distributeInfo[slot].magnifiedRewardCorrections.sub(
                    (_rewardInfo[reward].magnifiedRewardPerShare.mul(mintAmount)).toInt256Safe()
                ); 
            }
        }else if(newBalance < currentBalance) {
            uint256 burnAmount = currentBalance - newBalance;
            require(currentBalance >= burnAmount, "ERC20: burn amount exceeds balance");
            {
                _rewardInfo[reward].totalSupply -= burnAmount;
                _distributeInfo[slot].balanceOf = currentBalance - burnAmount;
                _distributeInfo[slot].magnifiedRewardCorrections = _distributeInfo[slot].magnifiedRewardCorrections.add(
                    (_rewardInfo[reward].magnifiedRewardPerShare.mul(burnAmount)).toInt256Safe()
                );

            }            
        }        
    }

    function _withdrawRewardsOfUser(address reward,address account,bool automatic) internal returns (bool) {
        bytes32 slot = getDistributeSlot(reward,account);
        if(!(canAutoClaim(_rewardInfo[reward].claimWait,_distributeInfo[slot].lastClaimTimes)) ||
            _rewardInfo[reward].minimumTokenBalanceForRewards > _distributeInfo[slot].balanceOf) {
            return false;
        }
        uint256 _withdrawableReward = _withdrawableRewardOf(
                                        _rewardInfo[reward].magnifiedRewardPerShare,
                                        slot
                                        );
        if (_withdrawableReward > 0) {
            bool success = IRewardDistributor(_rewardInfo[reward].rewardDistributor).distributeReward(account,_withdrawableReward);

            if(success) {
                _distributeInfo[slot].withdrawnRewards = _distributeInfo[slot].withdrawnRewards.add(_withdrawableReward);
            }
            _distributeInfo[slot].lastClaimTimes = block.timestamp;
            emit Claim(account, _withdrawableReward, automatic);
            return true;
        }

        return false;
    }
    
    function withdrawableRewardOf(address reward,address account) public view returns(uint256) {
        return _withdrawableRewardOf(
            _rewardInfo[reward].magnifiedRewardPerShare,
            getDistributeSlot(reward,account));
  	}

    function rewardOf(address reward,address account) external view returns(uint256) {
        return _withdrawableRewardOf(
            _rewardInfo[reward].magnifiedRewardPerShare,
            getDistributeSlot(reward,account));
    }

    function _withdrawableRewardOf(uint256 magnifiedRewardPerShare,bytes32 slot) internal view returns(uint256) {
        return (magnifiedRewardPerShare.mul(_distributeInfo[slot].balanceOf).toInt256Safe()
        .add(_distributeInfo[slot].magnifiedRewardCorrections).toUint256Safe() / magnitude
        ).sub(_distributeInfo[slot].withdrawnRewards);
    }

    function withdrawnRewardOf(address reward,address user) external view returns(uint256) {
        return _distributeInfo[getDistributeSlot(reward,user)].withdrawnRewards;
    }

    function swapCoinForReward(address rewardAsset,uint256 coinAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = rewardAsset;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: coinAmount}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapAndSendReward(address rewardAsset,uint256 coinAmount) internal {
        swapCoinForReward(rewardAsset,coinAmount);
        uint256 rewards = IERC20(rewardAsset).balanceOf(address(this));
        bool success = IERC20(rewardAsset).transfer(_rewardInfo[rewardAsset].rewardDistributor, rewards);
		
        if (success) {
            distributeRewards(rewardAsset,rewards);
            emit SendRewards(coinAmount, rewards);
        }
    }

    function distributeRewards(address reward,uint256 amount) internal{
        if (amount > 0) {
        _rewardInfo[reward].magnifiedRewardPerShare = _rewardInfo[reward].magnifiedRewardPerShare.add(
            (amount).mul(magnitude) / _rewardInfo[reward].totalSupply
        );
        emit RewardsDistributed(msg.sender, amount);

        _rewardInfo[reward].totalRewardsDistributed = _rewardInfo[reward].totalRewardsDistributed.add(amount);      
        }
    }

    function getRewardsDistributor(address rewardAsset) external view returns (address) {
        return _rewardInfo[rewardAsset].rewardDistributor;     
    }

    function getRewardDistributorInfo(address rewardAsset) external view returns (
        address rewardDistributor,
        uint256 distributeShare,
        bool isActive
    ) {
        return (
            _rewardInfo[rewardAsset].rewardDistributor,
            _rewardInfo[rewardAsset].distributeShare,
            _rewardInfo[rewardAsset].isActive
        );
    }

    function getTotalNumberofRewardsDistributor() external view returns (uint256) {
        return totalRewardDistributor;
    }

    function getPoolStatus(address rewardAsset) external view returns (bool isActive) {
        return _rewardInfo[rewardAsset].isActive;
    }

    function rewardsDistributorAt(uint8 index) external view returns (address) {
        return  _rewardInfo[_rewardAsset[index]].rewardDistributor;
    }

    function getAllRewardsDistributor() external view returns (address[] memory rewardDistributors) {
        rewardDistributors = new address[](totalRewardDistributor);
        for(uint8 i; i<totalRewardDistributor; i++) {
            rewardDistributors[i] = _rewardInfo[_rewardAsset[i]].rewardDistributor;
        }
    }

    function getDistributeSlot(address rewardToken,address user) internal pure returns (bytes32) {
        return (
            keccak256(abi.encode(rewardToken,user))
        );
    }

    function getMinmumAndMaximumBuyback() external view returns (uint256 _minimumCoinBalanceForBuyback,uint256 _maximumCoinBalanceForBuyback) {
        return (getBuyBackLimit(address(this).balance));
    }

    function rewardInfo(address rewardToken) external view returns (
        address rewardDistributor,
        uint256 distributeShare,
        uint256 claimWait,
        uint256 lastProcessedIndex,
        uint256 minimumTokenBalanceForRewards,
        uint256 magnifiedRewardPerShare,
        uint256 totalRewardsDistributed,
        uint256 totalSupply,
        uint256 index,
        bool isRemoved,
        bool isActive
    ) {
        rewardStore memory store = _rewardInfo[rewardToken];
        return (
            store.rewardDistributor,
            store.distributeShare,
            store.claimWait,
            store.lastProcessedIndex,
            store.minimumTokenBalanceForRewards,
            store.magnifiedRewardPerShare,
            store.totalRewardsDistributed,
            store.totalSupply,
            store.index,
            store.isRemoved,
            store.isActive
        );
    }

    function distributeInfo(address reward,address user) external view returns (
        uint256 lastClaimTimes,
        int256 magnifiedRewardCorrections,
        uint256 withdrawnRewards,
        uint256 balanceOf
    ) {
        bytes32 slot = getDistributeSlot(reward,user);
        return (
            _distributeInfo[slot].lastClaimTimes,
            _distributeInfo[slot].magnifiedRewardCorrections,
            _distributeInfo[slot].withdrawnRewards,
            _distributeInfo[slot].balanceOf
        );
    }

    function coinBalance() external view returns (uint256) {
        return (address(this).balance);
    }

    function isExcludedFromReward(address account) external view returns(bool) {
        return excludedFromRewards[account];
    }

    function rewardAssetAt(uint8 index) external view returns (address) {
        return _rewardAsset[index];
    }
}