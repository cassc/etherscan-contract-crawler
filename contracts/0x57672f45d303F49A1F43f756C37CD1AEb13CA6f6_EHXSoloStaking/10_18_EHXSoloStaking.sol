//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IEHXToken.sol";
import "./library/SafeMath.sol";
import "./library/EnumerableSet.sol";
import "./DividendTracker.sol";

contract EHXSoloStaking is OwnableUpgradeable,ReentrancyGuardUpgradeable {
    using SafeMath for uint256;

    using EnumerableSet for EnumerableSet.AddressSet;

    DividendTrackers public dividendTracker;

    IERC20 public USDC;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many staking tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 unstakeUnlock;
        uint256 stakeCollected;  //amount of stake collected by the user
        uint256 unstakeAmount;
        uint256 rewardsClaimTime;
        uint256 stakingTime;
        uint256 unstakingTime;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of staking token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Tokens to distribute per block.
        uint256 lastRewardTimestamp;  // Last block number that Tokens distribution occurs.
        uint256 accTokensPerShare; // Accumulated Tokens per share, times 1e12. See below.
    }

    bool public claimPaused = false;

    EnumerableSet.AddressSet private walletsOutstanding;
    mapping(address => uint256) public totalAmount;
    mapping(address => uint256) public claimedAmount;
    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public totalClaimDuration;
    mapping(address => uint256) public firstClaimPercent;
    mapping(address => bool) public claimedFirst;
    mapping(address => uint256) public rewardsPending;
    mapping(address => uint256) public rewardsClaimed;      ////// mapping for storing rewards accumulated by the user

    uint256 public totalPendingUnstakedTokens;
    uint256 public unstakeLockDuration = 7 days;
    uint256 public constant MAX_UNSTAKE_DURATION = 21 days;
    
    event AllocatedTokens(address indexed wallet, uint256 amount);
    event ResetAllocation(address indexed wallet);
    event ClaimedTokens(address indexed wallet,  uint256 amount);
    event Initialized();


    IERC20 public stakingToken;
    IERC20 public rewardToken;
    mapping (address => uint256) public holderUnlockTime;

    uint256 public totalStaked;
    uint256 public apy;
    uint256 public lockDuration;
    uint256 public exitPenaltyPerc;

    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    
    PoolInfo public pool;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event WithdrawUnstakedTokens(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event StakedNFT(address indexed nftAddress, uint256 indexed tokenId, address indexed sender);
    event UnstakedNFT(address indexed nftAddress, uint256 indexed tokenId, address indexed sender);

    function initialize(address _stakingToken, uint256 _apy, uint256 _lockDuration, uint256 _exitPenalty) external initializer{
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_stakingToken);
        address profitSharingToken;
        __Ownable_init();
        if(block.chainid == 1){
            profitSharingToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
        }
        // } else if(block.chainid == 4){
        //     profitSharingToken  = 0xE7d541c18D6aDb863F4C570065c57b75a53a64d3; // Rinkeby Testnet USDC
        // } else if(block.chainid == 56){
        //     profitSharingToken  = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD
        // } else if(block.chainid == 97){
        //     profitSharingToken  = 0xD0Db716Bff27bc4cDc9dD855Ed86f20c4390BEd6; // BSC Testnet BUSD
        // } else {
        //     profitSharingToken  = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
        //     // revert("Chain not configured");
        // } 

        USDC = IERC20(address(profitSharingToken));

        dividendTracker = new DividendTrackers(profitSharingToken);

        apy = _apy;
        lockDuration = _lockDuration;
        exitPenaltyPerc = _exitPenalty;
        pool.lpToken = IERC20(_stakingToken);
        pool.allocPoint = 1000;
        pool.lastRewardTimestamp = block.timestamp;
        pool.accTokensPerShare = 0;
        totalAllocPoint = 1000;
        emit Initialized();
    }

    function stopReward() external onlyOwner {
        updatePool();
        apy = 0;
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        if(pool.lastRewardTimestamp == 99999999999){
            return 0;
        }
        uint256 accTokensPerShare = pool.accTokensPerShare;
        uint256 lpSupply = totalStaked;
        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 tokenReward = calculateNewRewards().mul(pool.allocPoint).div(totalAllocPoint);
            accTokensPerShare = accTokensPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accTokensPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() internal {
        // transfer any accumulated tokens.
        if(USDC.balanceOf(address(this)) > 0){
            USDC.transfer(address(dividendTracker), USDC.balanceOf(address(this)));
            dividendTracker.distributeTokenDividends();
        }
        // PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        uint256 lpSupply = totalStaked;
        if (lpSupply == 0) { 
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }

        uint256 tokenReward = calculateNewRewards().mul(pool.allocPoint).div(totalAllocPoint);
        IEHXToken(address(rewardToken)).mintTokens(address(this), tokenReward);
        pool.accTokensPerShare = pool.accTokensPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardTimestamp = block.timestamp;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public onlyOwner {
            updatePool();
    }

    // Stake primary tokens = IEHX token
    function deposit(uint256 _amount) public nonReentrant {
        if(holderUnlockTime[msg.sender] == 0){
            holderUnlockTime[msg.sender] = block.timestamp + lockDuration;
        }
        UserInfo storage user = userInfo[msg.sender];

        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accTokensPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                if(pending >= rewardsRemaining()){
                    pending = rewardsRemaining();
                }
                rewardsPending[msg.sender] = pending;
                user.rewardsClaimTime= block.timestamp;                
                rewardToken.transfer(payable(address(msg.sender)), pending);
            }
        }

        uint256 amountTransferred = 0;
        if(_amount > 0) {
            uint256 initialBalance = pool.lpToken.balanceOf(address(this));
            user.stakingTime = block.timestamp;                    
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            amountTransferred = pool.lpToken.balanceOf(address(this)) - initialBalance;
            user.amount = user.amount.add(amountTransferred);
            totalStaked += amountTransferred;
        }

        dividendTracker.setBalance(payable(msg.sender), user.amount);
        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(1e12);

        emit Deposit(msg.sender, _amount);
    }

    function receivableReferrenceFees(address _user) public view returns(uint256){
        UserInfo storage user = userInfo[_user];
        if(user.amount == 0){
            return 20;
        }
        else if(user.amount>=3000*10**18 && user.amount<16000*10**18){
            return 50;
        }
        else if(user.amount>=16000*10**18 && user.amount<85000*10**18){
            return 70;
        }
        else if(user.amount>=85000*10**18 && user.amount<250000*10**18){
            return 80;
        }
        else{
            return 100;
        }
    }
    
    // Withdraw primary tokens from STAKING.

    function withdraw(uint256 _amount) public nonReentrant {

        require(holderUnlockTime[msg.sender] <= block.timestamp, "May not do normal withdraw early");
        
        UserInfo storage user = userInfo[msg.sender];
        
        require(_amount <= amountWithdrawable(msg.sender) , "Cannot withdraw vesting tokens.");

        updatePool();
        uint256 pending = user.amount.mul(pool.accTokensPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            if(pending >= rewardsRemaining()){
                pending = rewardsRemaining();
            }
            rewardsClaimed[msg.sender]+=pending;  
            rewardsPending[msg.sender]=0;  
            user.rewardsClaimTime= block.timestamp;                
            rewardToken.transfer(payable(address(msg.sender)), pending);
        }

        if(_amount > 0) {
            user.amount -= _amount;
            totalStaked -= _amount;
            user.unstakeUnlock = block.timestamp + unstakeLockDuration;
            user.unstakeAmount += _amount;
            user.stakeCollected += _amount;
            totalPendingUnstakedTokens += _amount;
            // pool.lpToken.transfer(address(msg.sender),_amount);
        }

        dividendTracker.setBalance(payable(msg.sender), user.amount);
        user.rewardDebt = user.amount.mul(pool.accTokensPerShare).div(1e12);
        
        if(user.amount > 0){
            holderUnlockTime[msg.sender] = block.timestamp + lockDuration;
        } else {
            holderUnlockTime[msg.sender] = 0;
        }
        emit Withdraw(msg.sender, _amount);
    }

    function withdrawUnstakedTokens() external  nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.unstakeUnlock > 0, "No tokens to unstake");
        require(user.unstakeUnlock <= block.timestamp, "Tokens not unlocked yet");
        uint256 amountToWithdraw = user.unstakeAmount;
        user.unstakeUnlock = 0;
        user.unstakeAmount = 0;
        totalPendingUnstakedTokens -= amountToWithdraw;
        user.stakeCollected+=amountToWithdraw;
        user.unstakingTime = block.timestamp;
        pool.lpToken.transfer(address(msg.sender), amountToWithdraw);

        emit WithdrawUnstakedTokens(msg.sender, amountToWithdraw);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external nonReentrant {
        require(!isWalletVesting(msg.sender), "Wallet is vesting and cannot emergency withdraw.");
        
        UserInfo storage user = userInfo[msg.sender];
        uint256 _amount = user.amount;
        totalStaked -= _amount;
        // exit penalty for early unstakers, penalty held on contract as rewards.
        if(holderUnlockTime[msg.sender] >= block.timestamp){
            _amount -= _amount * exitPenaltyPerc / 100;
        }
        holderUnlockTime[msg.sender] = 0;
        user.unstakeUnlock = block.timestamp + unstakeLockDuration;
        user.unstakeAmount += _amount;
        totalPendingUnstakedTokens += _amount;
        user.amount = 0;
        user.rewardDebt = 0;
        dividendTracker.setBalance(payable(msg.sender), 0);
        emit EmergencyWithdraw(msg.sender, _amount);
    }

    function getUnstakeUnlockTime(address account) external view returns (uint256 secondsRemaining, uint256 unstakeTimestamp){
        UserInfo memory user = userInfo[account];
        if(user.unstakeUnlock == 0){
            return (0, 0);
        } else if (user.unstakeUnlock <= block.timestamp) {
            return (0, user.unstakeUnlock);
        } else {
            return (user.unstakeUnlock - block.timestamp, user.unstakeUnlock);
        }
    }

    // Withdraw reward. EMERGENCY ONLY. This allows the owner to migrate rewards to a new staking pool since we are not minting new tokens.
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(_amount <= rewardsRemaining(), 'not enough tokens to take out');
        UserInfo memory user = userInfo[msg.sender];

        rewardsClaimed[msg.sender]+=_amount;      
        user.rewardsClaimTime= block.timestamp;                
        rewardToken.transfer(address(msg.sender), _amount);
    }

    function setUnstakeUnlockDuration(uint256 durationInSeconds) external onlyOwner {
        require(durationInSeconds <= 21 days, "Too high");
        unstakeLockDuration = durationInSeconds;
    }

    function calculateNewRewards() public view returns (uint256) {
        if(pool.lastRewardTimestamp > block.timestamp){
            return 0;
        }
        return (((block.timestamp - pool.lastRewardTimestamp) * totalStaked) * apy / 100 / 365 days);
        
    }

    function rewardsRemaining() public view returns (uint256){
        return rewardToken.balanceOf(address(this)) - totalStaked - totalPendingUnstakedTokens;
    }

    function updateApy(uint256 newApy) external onlyOwner {
        require(newApy <= 10000, "APY must be below 10000%");
        updatePool();
        apy = newApy;
    }

    function updateExitPenalty(uint256 newPenaltyPerc) external onlyOwner {
        require(newPenaltyPerc <= 20, "May not set higher than 20%");
        exitPenaltyPerc = newPenaltyPerc;
    }

    function claim() external nonReentrant {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    // Vesting information

    function vestTokens(
        address[] calldata wallets,     
        uint256[] calldata amountsWithDecimals, 
        uint256[] calldata totalDurationInSeconds, 
        uint256[] calldata timeBeforeFirstClaim, 
        uint256[] calldata firstClaimInitialPercent) 
        external onlyOwner {
        
        updatePool(); // ensure no larger claims made based on new balances
        require(wallets.length == amountsWithDecimals.length, "array lengths must match");
        address wallet;
        uint256 amount;
        uint256 total;
        for(uint256 i = 0; i < wallets.length; i++){
            wallet = wallets[i];
            amount = amountsWithDecimals[i];
            total += amount;
            UserInfo storage user = userInfo[wallet];
            totalAmount[wallet] += amount;
            user.amount += amount;
            totalStaked += amount;
            require(totalDurationInSeconds[i] > 0, "Total Duration must be > 0");
            totalClaimDuration[wallet] = totalDurationInSeconds[i];
            firstClaimPercent[wallet] = firstClaimInitialPercent[i];
            if(lastClaim[wallet] == 0){
                lastClaim[wallet] = block.timestamp + timeBeforeFirstClaim[i];
            }
            emit AllocatedTokens(wallet, amount);
            if(!walletsOutstanding.contains(wallet)){
                walletsOutstanding.add(wallet);
            }
        }

        IEHXToken(address(stakingToken)).mintTokens(address(this), total);
    }

    // for resetting allocation in the event of a mistake
    function resetAllocation(address[] calldata wallets) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            totalAmount[wallets[i]] = 0;
            lastClaim[wallets[i]] = 0;
            walletsOutstanding.remove(wallets[i]);
            emit ResetAllocation(wallets[i]);
        }
    }

    modifier notPaused {
        require(!claimPaused, "Claim is paused");
        _;
    }

    function setClaimPaused(bool paused) external onlyOwner {
        claimPaused = paused;
    }

    function claimVestedTokens() external notPaused nonReentrant {
        updatePool();
        uint256 amountToClaim = currentClaimableAmount(msg.sender);
        if(!claimedFirst[msg.sender]){
            claimedFirst[msg.sender] = true;
        }
        lastClaim[msg.sender] = block.timestamp;
        claimedAmount[msg.sender] += amountToClaim;

        UserInfo storage user = userInfo[msg.sender];

        uint256 pending = user.amount.mul(pool.accTokensPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            if(pending >= rewardsRemaining()){
                pending = rewardsRemaining();
            }
            rewardsClaimed[msg.sender]+=pending;  
            user.rewardsClaimTime= block.timestamp;                           
            rewardToken.transfer(payable(address(msg.sender)), pending);
        }
        user.amount -= amountToClaim;
        totalStaked -= amountToClaim;
        require(amountToClaim > 0, "Cannot claim 0");
        require(walletsOutstanding.contains(msg.sender), "Wallet cannot claim");
        require(stakingToken.balanceOf(address(this)) >= amountToClaim, "Not enough tokens on contract to claim");
        stakingToken.transfer(msg.sender, amountToClaim);
        emit ClaimedTokens(msg.sender, amountToClaim);
        if(totalAmount[msg.sender] <= claimedAmount[msg.sender]){
            walletsOutstanding.remove(msg.sender);
        }
    }

    function isWalletVesting(address account) public view returns (bool){
        return walletsOutstanding.contains(account);
    }

    function currentClaimableAmount(address wallet) public view returns (uint256 amountToClaim){
        if(lastClaim[wallet] > block.timestamp) return 0;
        if(!claimedFirst[wallet]){
            amountToClaim = totalAmount[wallet] * firstClaimPercent[wallet] / 10000;
        }
        uint256 claimPeriods = (block.timestamp - lastClaim[wallet]);
        amountToClaim += claimPeriods * totalAmount[wallet] / (totalClaimDuration[wallet]);
        if(amountToClaim > totalAmount[wallet] - claimedAmount[wallet]){
            amountToClaim = totalAmount[wallet] - claimedAmount[wallet];
        }
    }

    function totalVestingRemainder(address wallet) public view returns (uint256){
        return(totalAmount[wallet] - claimedAmount[wallet]);
    }

    function amountWithdrawable(address wallet) public view returns (uint256){
        UserInfo storage user = userInfo[wallet];
        return(user.amount - totalVestingRemainder(wallet));
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.holderBalance(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    function getNumberOfDividends() external view returns(uint256) {
        return dividendTracker.totalBalance();
    }
}