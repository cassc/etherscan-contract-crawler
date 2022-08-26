// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IPYESlice.sol";
import "./interfaces/IApple.sol";

contract SmartChefPYE is Ownable, ReentrancyGuard, ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The address of the smart chef factory
    address public SMART_CHEF_FACTORY;

    // PYESliceToken for stakers
    address public pyeSlice;
    IPYESlice PYESliceInterface;

    // donation state variables
    uint256 public totalDonations; // (sum of below)
    uint256 public pyeSwapDonations;
    uint256 public pyeLabDonations;
    uint256 public miniPetsDonations;
    uint256 public pyeWalletDonations;
    uint256 public pyeChartsDonations;

    // Whether a limit is set for users
    bool public hasUserLimit;

    // Whether it is initialized
    bool public isInitialized;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The block number when Apple mining ends.
    uint256 public bonusEndBlock;

    // The block number when Apple mining starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;

    // Apple tokens created per block.
    uint256 public rewardPerBlock;

    // The time for lock funds.
    uint256 public lockTime;

    // Dev fee.
    uint256 public devfee = 1000;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // The reward token
    IApple public rewardToken;

    // The weth token and USDC token
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // The staked token
    IERC20 public stakedToken;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
        uint256 depositTime;    // The last time when the user deposit funds
    }

    struct Share {
        uint256 amount;
        uint256 totalExcludedWETH;
        uint256 totalRealisedWETH;
        uint256 totalExcludedUSDC;
        uint256 totalRealisedUSDC; 
    }

    // Dev address.
    address public devaddr;
    //address public rewardDistributor;

    address[] stakers;
    mapping (address => uint256) stakerIndexes;
    mapping (address => uint256) stakerClaims;
    mapping (address => bool) isRewardExempt;

    mapping (address => Share) public shares;
// ----------------- BEGIN WETH Variables -----------

    uint256 public unallocatedWETHRewards;
    uint256 public totalShares;
    uint256 public totalRewardsWETH;
    uint256 public totalDistributedWETH;
    uint256 public rewardsPerShareWETH;
    uint256 public rewardsPerShareAccuracyFactor = 10 ** 36; // Keeping same accuracy factor in the USDC Token Variables

// ----------------- BEGIN USDC Token Variables -----------

    uint256 public unallocatedUSDCRewards;
    uint256 public totalRewardsUSDC;
    uint256 public totalDistributedUSDC;
    uint256 public rewardsPerShareUSDC;
    uint256 public totalStakedTokens;

// ----------------- END USDC Token Variables -----------    

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);
    event Withdraw(address indexed user, uint256 amount);
    event NewLockTime(uint256 lockTime);
    event setLockTime(address indexed user, uint256 lockTime);
    event StakedAndMinted(address indexed _address, uint256 _blockTimestamp);
    event UnstakedAndBurned(address indexed _address, uint256 _blockTimestamp);

    constructor(IERC20 _stakedToken, IApple _rewardToken, uint256 _rewardPerBlock, uint256 _startBlock, uint256 _lockTime, address _pyeSlice) ERC20("","") {

        // Make this contract initialized
        isInitialized = true;

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = 999999999;
        lockTime = _lockTime;
        devaddr = msg.sender;
        pyeSlice = _pyeSlice;

        PYESliceInterface = IPYESlice(_pyeSlice);

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        isRewardExempt[msg.sender] = true;
        isRewardExempt[address(this)] = true;
    }

    modifier onlyToken {
        require(msg.sender == address(stakedToken));
        _;
    }
    
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        if (hasUserLimit) {
            require(_amount.add(user.amount) <= poolLimitPerUser, "User amount above limit");
        }

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            if (pending > 0) {
                safeappleTransfer(msg.sender, pending);
            }
        }

        if (_amount > 0) {

            // begin slice logic
            uint256 currentStakedBalance = user.amount; // current staked balance
            uint256 currentPYESliceBalance = IERC20(pyeSlice).balanceOf(msg.sender);

            if (currentStakedBalance == 0 && currentPYESliceBalance == 0) {
                _beforeTokenTransfer(msg.sender, address(this), _amount);
                stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
                user.amount = user.amount.add(_amount);
                PYESliceInterface.mintPYESlice(msg.sender, 1);
                totalStakedTokens = totalStakedTokens.add(_amount);
                if(!isRewardExempt[msg.sender]){ setShare(msg.sender, user.amount); }
                user.depositTime = block.timestamp;
                emit StakedAndMinted(msg.sender, block.timestamp);
            } else {
                _beforeTokenTransfer(msg.sender, address(this), _amount);
                stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
                user.amount = user.amount.add(_amount);
                totalStakedTokens = totalStakedTokens.add(_amount);
                if(!isRewardExempt[msg.sender]){ setShare(msg.sender, user.amount); }
                user.depositTime = block.timestamp; 
            }
        } else {
            distributeRewardWETH(msg.sender);
            distributeRewardUSDC(msg.sender);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Deposit(msg.sender, _amount);
    }

    function harvest() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            if (pending > 0) {
                safeappleTransfer(msg.sender, pending);
            }
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");
        require(user.depositTime + lockTime < block.timestamp, "Can not withdraw in lock period");

        _updatePool();

        uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);

        if (_amount > 0) {

            // begin slice logic
            uint256 currentStakedBalance = user.amount; // current staked balance
            uint256 currentPYESliceBalance = IERC20(pyeSlice).balanceOf(msg.sender);

            if (currentStakedBalance.sub(_amount) == 0 && currentPYESliceBalance > 0) {
                user.amount = user.amount.sub(_amount);
                _beforeTokenTransfer(address(this), msg.sender, _amount);
                stakedToken.safeTransfer(address(msg.sender), _amount);
                PYESliceInterface.burnPYESlice(msg.sender, currentPYESliceBalance);
                totalStakedTokens = totalStakedTokens.sub(_amount);
                if(!isRewardExempt[msg.sender]){ setShare(msg.sender, user.amount); }
                emit UnstakedAndBurned(msg.sender, block.timestamp);
            } else {
                user.amount = user.amount.sub(_amount);
                _beforeTokenTransfer(address(this), msg.sender, _amount);
                stakedToken.safeTransfer(address(msg.sender), _amount);
                totalStakedTokens = totalStakedTokens.sub(_amount);
                if(!isRewardExempt[msg.sender]){ setShare(msg.sender, user.amount); }
            }
        }

        if (pending > 0) {
            safeappleTransfer(msg.sender, pending);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        uint256 currentPYESliceBalance = IERC20(pyeSlice).balanceOf(msg.sender);
        _beforeTokenTransfer(address(this), msg.sender, user.amount);

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
            PYESliceInterface.burnPYESlice(msg.sender, currentPYESliceBalance);
            totalStakedTokens = totalStakedTokens.sub(amountToTransfer);
            emit UnstakedAndBurned(msg.sender, block.timestamp);
        }

        if(!isRewardExempt[msg.sender]){ setShare(msg.sender, 0); }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.transfer(address(msg.sender), _amount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        require(_tokenAddress != address(rewardToken), "Cannot be reward token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        require(hasUserLimit, "Must be set");
        if (_hasUserLimit) {
            require(_poolLimitPerUser > poolLimitPerUser, "New limit must be higher");
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(poolLimitPerUser);
    }

    /*
     * @notice Update lock time
     * @dev Only callable by owner.
     * @param _lockTime: the time in seconds that staked tokens are locked
     */
    function updateLockTime(uint256 _lockTime) external onlyOwner {
        lockTime = _lockTime;
        emit NewLockTime(_lockTime);
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
        require(_startBlock < _bonusEndBlock, "New startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        
        if (block.number > lastRewardBlock && totalStakedTokens != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 appleReward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare =
            accTokenPerShare.add(appleReward.mul(PRECISION_FACTOR).div(totalStakedTokens));
            return user.amount.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        } else {
            return user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        }
    }

    // Safe apple transfer function, just in case if rounding error causes pool to not have enough apple.
    function safeappleTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBalance = rewardToken.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > tokenBalance) {
            transferSuccess = rewardToken.transfer(_to, tokenBalance);
        } else {
            transferSuccess = rewardToken.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokenTransfer: transfer failed");
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalStakedTokens == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 appleReward = multiplier.mul(rewardPerBlock);
        rewardToken.mint(devaddr, appleReward.mul(devfee).div(10000));
        rewardToken.mint(address(this), appleReward);
        accTokenPerShare = accTokenPerShare.add(appleReward.mul(PRECISION_FACTOR).div(totalStakedTokens));
        lastRewardBlock = block.number;
    }
    
    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return isRewardExempt[account];
    }

    function setIsRewardExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this));
        UserInfo storage user = userInfo[holder];
        isRewardExempt[holder] = exempt;
        if(exempt){
            setShare(holder, 0);
        }else{
            setShare(holder, user.amount);
        }
    }
    
    function setShare(address staker, uint256 amount) internal {
        if(shares[staker].amount > 0){
            distributeRewardWETH(staker);
            distributeRewardUSDC(staker);
        }

        if(amount > 0 && shares[staker].amount == 0){
            addStaker(staker);
        }else if(amount == 0 && shares[staker].amount > 0){
            removeStaker(staker);
        }

        totalShares = totalShares.sub(shares[staker].amount).add(amount);
        shares[staker].amount = amount;
        shares[staker].totalExcludedWETH = getCumulativeRewardsWETH(shares[staker].amount);
        shares[staker].totalExcludedUSDC = getCumulativeRewardsUSDC(shares[staker].amount);
    }
    
    // WETH STUFF

    function distributeRewardWETH(address staker) internal {
        if(shares[staker].amount == 0){ return; }

        uint256 amount = getUnpaidEarningsWETH(staker);
        if(amount > 0){
            totalDistributedWETH = totalDistributedWETH.add(amount);
            IERC20(WETH).transfer(staker, amount);
            stakerClaims[staker] = block.timestamp;
            shares[staker].totalRealisedWETH = shares[staker].totalRealisedWETH.add(amount);
            shares[staker].totalExcludedWETH = getCumulativeRewardsWETH(shares[staker].amount);
        }
    }

    function claimWETH() external {
        distributeRewardWETH(msg.sender);
    }

    function getUnpaidEarningsWETH(address staker) public view returns (uint256) {
        if(shares[staker].amount == 0){ return 0; }

        uint256 stakerTotalRewardsWETH = getCumulativeRewardsWETH(shares[staker].amount);
        uint256 stakerTotalExcludedWETH = shares[staker].totalExcludedWETH;

        if(stakerTotalRewardsWETH <= stakerTotalExcludedWETH){ return 0; }

        return stakerTotalRewardsWETH.sub(stakerTotalExcludedWETH);
    }

    function getCumulativeRewardsWETH(uint256 share) internal view returns (uint256) {
        return share.mul(rewardsPerShareWETH).div(rewardsPerShareAccuracyFactor);
    }

    function addStaker(address staker) internal {
        stakerIndexes[staker] = stakers.length;
        stakers.push(staker);
    }

    function removeStaker(address staker) internal {
        stakers[stakerIndexes[staker]] = stakers[stakers.length-1];
        stakerIndexes[stakers[stakers.length-1]] = stakerIndexes[staker];
        stakers.pop();
    }

    // Rescue eth that is sent here by mistake
    function rescueETH(uint256 amount, address to) external onlyOwner{
        payable(to).transfer(amount);
      }

    function setFee(address _feeAddress, uint256 _devfee) public onlyOwner {
        devaddr = _feeAddress;
        devfee = _devfee;
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyWETHWithdraw(uint256 _amount) external onlyOwner {
        IERC20(WETH).transfer(address(msg.sender), _amount);
    }


// ------------------- BEGIN USDC TOKEN FUNCTIONS ---------------

    function depositUSDCToStakingContract(uint256 _amountUSDC) external onlyToken {
        if (totalShares == 0) {unallocatedUSDCRewards = unallocatedUSDCRewards.add(_amountUSDC); return; } 
        
        if (unallocatedUSDCRewards > 0) {
            uint256 amount = _amountUSDC.add(unallocatedUSDCRewards);
            totalRewardsUSDC = totalRewardsUSDC.add(amount);
            rewardsPerShareUSDC = rewardsPerShareUSDC.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
            unallocatedUSDCRewards = 0;
        } else {
            totalRewardsUSDC = totalRewardsUSDC.add(_amountUSDC);
            rewardsPerShareUSDC = rewardsPerShareUSDC.add(rewardsPerShareAccuracyFactor.mul(_amountUSDC).div(totalShares));
        }   
    }

    function depositUSDC(uint256 _amount) external onlyOwner {
        uint256 balanceBefore = IERC20(address(USDC)).balanceOf(address(this));

        IERC20(USDC).transferFrom(address(msg.sender), address(this), _amount);

        uint256 amount = IERC20(address(USDC)).balanceOf(address(this)).sub(balanceBefore);

        totalRewardsUSDC = totalRewardsUSDC.add(amount);
        rewardsPerShareUSDC = rewardsPerShareUSDC.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
        
    }

    function getCumulativeRewardsUSDC(uint256 share) internal view returns (uint256) {
        return share.mul(rewardsPerShareUSDC).div(rewardsPerShareAccuracyFactor);
    }

    function getUnpaidEarningsUSDC(address staker) public view returns (uint256) {
        if(shares[staker].amount == 0){ return 0; }

        uint256 stakerTotalRewardsUSDC = getCumulativeRewardsUSDC(shares[staker].amount);
        uint256 stakerTotalExcludedUSDC = shares[staker].totalExcludedUSDC;

        if(stakerTotalRewardsUSDC <= stakerTotalExcludedUSDC){ return 0; }

        return stakerTotalRewardsUSDC.sub(stakerTotalExcludedUSDC);
    }

    function distributeRewardUSDC(address staker) internal {
        if(shares[staker].amount == 0){ return; }

        uint256 amount = getUnpaidEarningsUSDC(staker);
        if(amount > 0){
            totalDistributedUSDC = totalDistributedUSDC.add(amount);
            IERC20(USDC).transfer(staker, amount);
            stakerClaims[staker] = block.timestamp;
            shares[staker].totalRealisedUSDC = shares[staker].totalRealisedUSDC.add(amount);
            shares[staker].totalExcludedUSDC = getCumulativeRewardsUSDC(shares[staker].amount);
        }
    }

    function claimUSDC() external {
        distributeRewardUSDC(msg.sender);
    }

    //--------------------- BEGIN DONATION FUNCTIONS -------------

    function addPYESwapDonation(uint256 _pyeSwapDonation) external nonReentrant {
        uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
        IERC20(WETH).transferFrom(address(msg.sender), address(this), _pyeSwapDonation);
        uint256 amount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
        totalRewardsWETH = totalRewardsWETH.add(amount);
        rewardsPerShareWETH = rewardsPerShareWETH.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
        totalDonations += amount;
        pyeSwapDonations += amount;
    }

    function addPYELabDonation(uint256 _pyeLabDonation) external nonReentrant {
        uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
        IERC20(WETH).transferFrom(address(msg.sender), address(this), _pyeLabDonation);
        uint256 amount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
        totalRewardsWETH = totalRewardsWETH.add(amount);
        rewardsPerShareWETH = rewardsPerShareWETH.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
        totalDonations += amount;
        pyeLabDonations += amount;
    }

    function addMiniPetsDonation(uint256 _miniPetsDonation) external nonReentrant {
        uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
        IERC20(WETH).transferFrom(address(msg.sender), address(this), _miniPetsDonation);
        uint256 amount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
        totalRewardsWETH = totalRewardsWETH.add(amount);
        rewardsPerShareWETH = rewardsPerShareWETH.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
        totalDonations += amount;
        miniPetsDonations += amount;
    }

    function addPYEWalletDonation(uint256 _pyeWalletDonation) external nonReentrant {
        uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
        IERC20(WETH).transferFrom(address(msg.sender), address(this), _pyeWalletDonation);
        uint256 amount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
        totalRewardsWETH = totalRewardsWETH.add(amount);
        rewardsPerShareWETH = rewardsPerShareWETH.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
        totalDonations += amount;
        pyeWalletDonations += amount;
    }

    function addPYEChartsDonation(uint256 _pyeChartsDonation) external nonReentrant {
        uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
        IERC20(WETH).transferFrom(address(msg.sender), address(this), _pyeChartsDonation);
        uint256 amount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
        totalRewardsWETH = totalRewardsWETH.add(amount);
        rewardsPerShareWETH = rewardsPerShareWETH.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
        totalDonations += amount;
        pyeChartsDonations += amount;
    }

    //--------------------BEGIN MODIFIED SNAPSHOT FUNCITONALITY---------------

    // @dev a modified implementation of ERC20 Snapshot to keep track of staked balances (shares) rather than balanceOf (total token ownership). 
    // ERC20 Snapshot import/inheritance is avoided in this contract to avoid issues with interface conflicts and to directly control private 
    // functionality to keep snapshots of staked balances instead.
    // copied from source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Snapshot.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;
    Counters.Counter private _currentSnapshotId;

    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalStakedSnapshots;

    // @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
    event Snapshot(uint256 id);

    // generate a snapshot, calls internal _snapshot().
    function snapshot() public onlyOwner {
        _snapshot();
    }

    function _snapshot() internal returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    function _getCurrentSnapshotId() internal view returns (uint256) {
        return _currentSnapshotId.current();
    }

    // @dev returns shares of a holder, not balanceOf, at a certain snapshot.
    function sharesOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : shares[account].amount;
    }

    // @dev returns totalStakedTokens at a certain snapshot
    function totalStakedAt(uint256 snapshotId) public view returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalStakedSnapshots);

        return snapshotted ? value : totalStakedTokens;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalStakedSnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalStakedSnapshot();
        } else if (to == address(this)) {
            // user is staking
            _updateAccountSnapshot(from);
            _updateTotalStakedSnapshot();
        } else if (from == address(this)) {
            // user is unstaking
            _updateAccountSnapshot(to);
            _updateTotalStakedSnapshot();
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], shares[account].amount);
    }

    function _updateTotalStakedSnapshot() private {
        _updateSnapshot(_totalStakedSnapshots, totalStakedTokens);
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    // ------------------ BEGIN PRESALE TOKEN FUNCTIONALITY -------------------

    // @dev struct containing all elements of pre-sale token. 
    struct presaleToken {
        string presaleTokenName;
        address presaleTokenAddress;
        uint256 presaleTokenBalance;
        uint256 presaleTokenRewardsPerShare; 
        uint256 presaleTokenTotalDistributed;
        uint256 presaleTokenSnapshotId;
    }

    // @dev dynamic array of struct presaleToken
    presaleToken[] public presaleTokenList;
    bool checkDuplicateEnabled; 
    mapping (address => uint256) entitledTokenReward;
    mapping (address => mapping (address => bool)) hasClaimed;

    //------------------- BEGIN PRESALE-TOKEN ARRAY MODIFIERS AND GETTERS--------------------

    // performs safety checks when depositing.
    modifier depositCheck(address _presaleTokenAddress, uint256 _amount) {
        require(IERC20(_presaleTokenAddress).balanceOf(msg.sender) >= _amount , "Deposit amount exceeds balance!"); 
        require(msg.sender != address(0) || msg.sender != 0x000000000000000000000000000000000000dEaD , "Cannot deposit from address(0)!");
        require(_amount != 0 , "Cannot deposit 0 tokens!");
        require(totalStakedTokens != 0 , "Nobody is staked!");
            _;
    }

    // @dev deletes the last struct in the presaleTokenList. 
    function popToken() internal {
        presaleTokenList.pop();
    }

    // returns number of presale Tokens stored.
    function getTokenArrayLength() public view returns (uint256) {
        return presaleTokenList.length;
    }

    // @dev enter the address of token to delete. avoids empty gaps in the middle of the array.
    function deleteToken(address _address) public onlyOwner {
        uint tokenLength = presaleTokenList.length;
        for(uint i = 0; i < tokenLength; i++) {
            if (_address == presaleTokenList[i].presaleTokenAddress) {
                if (1 < presaleTokenList.length && i < tokenLength-1) {
                    presaleTokenList[i] = presaleTokenList[tokenLength-1]; }
                    delete presaleTokenList[tokenLength-1];
                    popToken();
                    break;
            }
        }
    }

    // @dev create presale token and fund it. requires allowance approval from token. 
    function createAndFundPresaleToken(string memory _presaleTokenName, address _presaleTokenAddress, uint256 _amount) external onlyOwner depositCheck(_presaleTokenAddress, _amount) {
        // check duplicates
        if (checkDuplicateEnabled) { checkDuplicates(_presaleTokenAddress); }

        // deposit the token
        IERC20(_presaleTokenAddress).transferFrom(address(msg.sender), address(this), _amount);
        // store staked balances at time of reward token deposit
        _snapshot();
        // push new struct, with most recent snapshot ID
        presaleTokenList.push(presaleToken(
            _presaleTokenName, 
            _presaleTokenAddress, 
            _amount, 
            (rewardsPerShareAccuracyFactor.mul(_amount).div(totalStakedTokens)), 
            0,
            _getCurrentSnapshotId()));
    }

    // @dev change whether or not createAndFundToken should check for duplicate presale tokens
    function shouldCheckDuplicates(bool _bool) external onlyOwner {
        checkDuplicateEnabled = _bool;
    }

    // @dev internal helper function that checks the array for preexisting addresses
    function checkDuplicates(address _presaleTokenAddress) internal view {
        for(uint i = 0; i < presaleTokenList.length; i++) {
            if (_presaleTokenAddress == presaleTokenList[i].presaleTokenAddress) {
                revert("Token already exists!");
            }
        }
    }

    //------------------- BEGIN PRESALE-TOKEN TRANSFER FXNS AND STRUCT MODIFIERS --------------------

    // @dev update an existing token's balance based on index.
    function fundExistingToken(uint256 _index, uint256 _amount) external onlyOwner depositCheck(presaleTokenList[_index].presaleTokenAddress, _amount) {
        require(_index <= presaleTokenList.length , "Index out of bounds!");

        if ((bytes(presaleTokenList[_index].presaleTokenName)).length == 0 || presaleTokenList[_index].presaleTokenAddress == address(0)) {
            revert("Attempting to fund a token with no name, or with an address of 0.");
        }

        // do the transfer
        uint256 presaleTokenBalanceBefore = presaleTokenList[_index].presaleTokenBalance;
        uint256 presaleTokenRewardsPerShareBefore = presaleTokenList[_index].presaleTokenRewardsPerShare;
        IERC20(presaleTokenList[_index].presaleTokenAddress).transferFrom(address(msg.sender), address(this), _amount);
        _snapshot();
        // update struct balances to add amount
        presaleTokenList[_index].presaleTokenBalance = presaleTokenBalanceBefore.add(_amount);
        presaleTokenList[_index].presaleTokenRewardsPerShare = presaleTokenRewardsPerShareBefore.add((rewardsPerShareAccuracyFactor.mul(_amount).div(totalStakedTokens)));
        
    }

    // remove unsafe or compromised token from availability
    function withdrawExistingToken(uint256 _index) external onlyOwner {
        require(_index <= presaleTokenList.length , "Index out of bounds!");
        
        if ((bytes(presaleTokenList[_index].presaleTokenName)).length == 0 || presaleTokenList[_index].presaleTokenAddress == address(0)) {
            revert("Attempting to withdraw from a token with no name, or with an address of 0.");
        }

        // do the transfer
        IERC20(presaleTokenList[_index].presaleTokenAddress).transfer(address(msg.sender), presaleTokenList[_index].presaleTokenBalance);
        // update struct balances to subtract amount
        presaleTokenList[_index].presaleTokenBalance = 0;
        presaleTokenList[_index].presaleTokenRewardsPerShare = 0;
    }

    //-------------------------------- BEGIN PRESALE TOKEN REWARD FUNCTION-----------

    function claimPresaleToken(uint256 _index) external nonReentrant {
        require(_index <= presaleTokenList.length , "Index out of bounds!");
        require(!hasClaimed[msg.sender][presaleTokenList[_index].presaleTokenAddress] , "You have already claimed your reward!");
        // calculate reward based on share at time of current snapshot (which is when a token is funded or created)
        if(sharesOfAt(msg.sender, presaleTokenList[_index].presaleTokenSnapshotId) == 0){ 
            entitledTokenReward[msg.sender] = 0; } 
            else { entitledTokenReward[msg.sender] = sharesOfAt(msg.sender, presaleTokenList[_index].presaleTokenSnapshotId).mul(presaleTokenList[_index].presaleTokenRewardsPerShare).div(rewardsPerShareAccuracyFactor); }
        
        require(presaleTokenList[_index].presaleTokenBalance >= entitledTokenReward[msg.sender]);
        // struct balances before transfer
        uint256 presaleTokenBalanceBefore = presaleTokenList[_index].presaleTokenBalance;
        uint256 presaleTokenTotalDistributedBefore = presaleTokenList[_index].presaleTokenTotalDistributed;
        // transfer
        IERC20(presaleTokenList[_index].presaleTokenAddress).transfer(address(msg.sender), entitledTokenReward[msg.sender]);
        hasClaimed[msg.sender][presaleTokenList[_index].presaleTokenAddress] = true;
        // update struct balances 
        presaleTokenList[_index].presaleTokenBalance = presaleTokenBalanceBefore.sub(entitledTokenReward[msg.sender]);
        presaleTokenList[_index].presaleTokenTotalDistributed = presaleTokenTotalDistributedBefore.add(entitledTokenReward[msg.sender]);       
    }

    // allows user to see their entitled presaleToken reward based on staked balance at time of token creation
    function getUnpaidEarningsPresale(uint256 _index, address staker) external view returns (uint256) {
        uint256 entitled;
        if (hasClaimed[staker][presaleTokenList[_index].presaleTokenAddress]) {
            entitled = 0;
        } else {
            entitled = sharesOfAt(staker, presaleTokenList[_index].presaleTokenSnapshotId).mul(presaleTokenList[_index].presaleTokenRewardsPerShare).div(rewardsPerShareAccuracyFactor);
        }
        return entitled;
    }
}