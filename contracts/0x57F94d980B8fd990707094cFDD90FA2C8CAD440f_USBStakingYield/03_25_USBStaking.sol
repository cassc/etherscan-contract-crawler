// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./USBStakingFactory.sol";
import "./USBStakingYield.sol";

contract USBStaking is Initializable, PausableUpgradeable, AccessControlUpgradeable {

    using SafeERC20Upgradeable for ERC20Upgradeable;

    /** 
     * @dev Manager is the person allowed to manage this product 
     */
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /** 
     * @dev The factory of farming contracts. Can be zero address if this farming is not deployed by factory.
     */
    USBStakingFactory public factory; 

    /** 
     * @dev address of stake token contract 
     */
    ERC20Upgradeable public stakeToken;  

    /** 
     * @dev address of reward token contract 
     */
    ERC20Upgradeable public rewardToken;
   
    /**
     * @notice amount of reward token to be distribute for one block 
     * @dev [rewardPerBlock]=rewardToken/block
     */ 
    uint256 public rewardPerBlock;

    /** 
     * @notice block number when staking starts
     * @dev [startBlock]=block
     */
    uint256 public startBlock;

    /**
     * @notice block number when staking ends
     * @dev [endBlock]=block
     */
    uint256 public endBlock;

    /**
     * @notice last block number when tokens distribution occurs
     * @dev [lastRewardBlock]=block
     */
    uint256 public lastRewardBlock;
    
    /**
     * @notice accumulated reward tokens per stake token. Accumulates with every update() call
     * @dev [accumulatedRewardTokenPerStakeToken]=rewardToken/stakeToken
     */
    uint256 public accumulatedRewardTokenPerStakeToken;
    
    /**
     * @notice total amount of staked token by all stakers
     * @dev [totalStake]=stakeToken
     */
    uint256 public totalStake;

    /**
     * @notice total pending reward token. If you want to get current pending reward call `getTotalPendingReward(0)`
     * @dev [totalPendingReward]=rewardToken
     */
    uint256 public totalPendingReward;

    /**
     * @notice total reward token claimed by stakers
     * @dev totalClaimedReward = sum of all claimedReward by all users
     * @dev [totalClaimedReward]=rewardToken
     */
    uint256 public totalClaimedReward;

    /**
     * @notice user position
     * @dev address of user => UserPosition
     */
    mapping (address => UserPosition) public userPosition;

    /**
     * @notice array of yield rewards contracts
     */
    USBStakingYield[] public yields;

    /**
     * @notice is stake paused
     * @dev true - paused, false - unpaused
     */
    bool public isStakePaused;
    
    /** 
     * @notice info of each user
     */
    struct UserPosition {
        uint256 stake;          // how many stake tokens the user has provided. [stake]=stakeToken
        uint256 claimedReward;  // total stake of tokens send as reward to user [claimedReward]=rewardToken
        uint256 pendingReward;  // how many reward tokens user was rewarded with. [pendingReward]=rewardToken
        uint256 instantAccumulatedShareOfReward;   // how many tokens already pended. [instantAccumulatedShareOfReward]=rewardToken
    }
   
    event Stake(address indexed user, uint256 stakeAmount);
    event Unstake(address indexed user, uint256 unstakeAmount);
    event ClaimReward(address indexed user, uint256 claimedRewardAmount);
    event ClaimRewardAndStake(address indexed user, uint256 claimedRewardAndStakedAmount);
    event Exit(address indexed user, uint256 exitAmount, uint256 claimedRewardAmount);
    event EmergencyUnstake(address indexed user, uint256 withdrawAmount);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "USBStaking: Caller is not the Admin");
        _;
    }

    modifier onlyAdminOrFactory() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || msg.sender == address(factory), "USBStaking: Caller is not the admin or factory");
        _;
    }

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "USBStaking: Caller is not the Manager");
        _;
    }

    modifier onlyNonStakePaused() {
        require(!isStakePaused, "USBStaking: stake is paused");
        _;
    }

    /**
     * @dev initializer of USBStaking
     * @param _factory address of factory contract. Possible to zero address
     * @param _rewardToken address of reward token
     * @param _stakeToken address of stake token
     * @param _initialReward the amount of reward token to be initial reward
     * @param _rewardPerBlock the amount of reward to be distributed for one block
     */
    function initialize(
        address _factory,
        address _stakeToken,
        address _rewardToken,
        uint256 _initialReward,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock
    ) external initializer {
        __AccessControl_init();
        __Pausable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);

        if(_factory != address(0)){
            factory = USBStakingFactory(_factory);
            _setupRole(MANAGER_ROLE, _factory);
        }
        
        stakeToken = ERC20Upgradeable(_stakeToken);
        rewardToken = ERC20Upgradeable(_rewardToken);

        if(_initialReward > 0) {
            rewardToken.safeTransferFrom(msg.sender, address(this), _initialReward);
        }

        _setRewardPerBlock(_rewardPerBlock);
        _setPeriod(_startBlock, _endBlock);
    }

    //************* ADMIN FUNCTIONS *************//

    /**
     * @dev transfer admin of USBStakingFactory to `_admin`
     * @param _admin address of new admin
     */
    function transferAdminship(address _admin) external onlyAdmin {
        require(_admin != address(0), "USBStaking: _admin is zero");
        require(!hasRole(DEFAULT_ADMIN_ROLE, _admin), "USBStaking: _admin already have admin role");
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    
    /**
     * @dev grant the manager
     * @param _manager address of manager
     */
    function grantManager(address _manager) external onlyAdmin {
        _grantRole(MANAGER_ROLE, _manager);
    }

    /**
     * @dev revoke the manager
     * @param _manager address of manager
     */
    function revokeManager(address _manager) external onlyAdmin {
        _revokeRole(MANAGER_ROLE, _manager);
    }
    
    /**
     * @dev transfer any tokens from staking
     * @param _token address of token to be transferred
     * @param _recipient address of receiver of tokens
     * @param _amount amount of token to be transferred
     */
    function sweepTokens(address _token, address _recipient, uint256 _amount) external onlyAdmin {
        require(_amount > 0, "USBStaking: amount=0");
        if (_token == address(stakeToken)) {
            uint256 balanceOfStakeToken = stakeToken.balanceOf(address(this));
            require(balanceOfStakeToken > totalStake, "USBStaking: balanceOfStakeToken==totalStake");
            uint256 excess = balanceOfStakeToken - totalStake;
            require(excess >= _amount, "USBStaking: sweep more than allowed");   
        }
        ERC20Upgradeable(_token).safeTransfer(_recipient, _amount);
    }

    /**
     * @dev pause staking
     */
    function pause() external onlyAdmin {
        update();
        super._pause();
    }

    /**
     * @dev unpause staking
     */
    function unpause() external onlyAdmin {
        lastRewardBlock = block.number;
        super._unpause();
    }
    
    /**
     * @dev add yield
     * @param _yield address of USBStakingYield
     */
    function addYield(USBStakingYield _yield) external onlyAdminOrFactory {
        require(yields.length < type(uint8).max, "USBStaking: reached max amount of yield reward pools");
        yields.push(_yield);
    }

    /**
     * @dev removed yield
     * @param _yieldId id of yield in array `yields`
     */
    function removeYield(uint8 _yieldId) external onlyAdminOrFactory {
        require(_yieldId < yields.length, "USBStaking: yieldId >= yields.length");
        if (yields.length > 1 && _yieldId != (yields.length - 1)) {
            yields[_yieldId] = yields[yields.length - 1];
        }
        yields.pop();
    }

    //************* END ADMIN FUNCTIONS *************//
    //************* MANAGER FUNCTIONS *************//

    /**
     * @dev sets reward per block. Can be called by manager
     * @param _rewardPerBlock amount of `rewardToken` to be rewarded each block
     */
    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyManager {
        _setRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @dev sets reward per block
     * @param _rewardPerBlock amount of `rewardToken` to be rewarded each block
     */
    function _setRewardPerBlock(uint256 _rewardPerBlock) internal {
        update();
        rewardPerBlock = _rewardPerBlock;
    }

    /**
     * @dev sets period of staking. Can be called by manager
     * @param _startBlock block number of start staking
     * @param _endBlock block number of end staking
     */
    function setPeriod(uint256 _startBlock, uint256 _endBlock) public onlyManager {
        _setPeriod(_startBlock, _endBlock);
    }

    /**
     * @dev sets period of staking
     * @param _startBlock block number of start staking
     * @param _endBlock block number of end staking
     */
    function _setPeriod(uint256 _startBlock, uint256 _endBlock) internal {
        require(_startBlock < _endBlock, "USBStaking: should be startBlock<endBlock");
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    /**
     * @dev sets reward per block and period of staking
     * @param _rewardPerBlock amount of `rewardToken` to be rewarded each block
     * @param _startBlock block number of start staking
     * @param _endBlock block number of end staking
     */
    function setParams(uint256 _rewardPerBlock, uint256 _startBlock, uint256 _endBlock) external onlyManager {
        _setRewardPerBlock(_rewardPerBlock);
        _setPeriod(_startBlock, _endBlock);
    }

    /**
     * @dev sets staking to pause
     * @param _paused true - paused, false - unpaused
     */
    function setStakePaused(bool _paused) external onlyManager {
        isStakePaused = _paused;
    }

    //************* END MANAGER FUNCTIONS *************//
    //************* MAIN FUNCTIONS *************//

    /**
     * @dev update the `accumulatedRewardTokenPerStakeToken`
     */
    function update() public whenNotPaused {
        if (block.number <= lastRewardBlock) {
            return;
        }   
        if (totalStake == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 rewardAmount = calculateTotalPendingReward(0);
        uint256 accumulatorMultiplier = getAccumulatorMultiplier();
        accumulatedRewardTokenPerStakeToken += rewardAmount * accumulatorMultiplier / totalStake;
        totalPendingReward += rewardAmount;
        lastRewardBlock = block.number;
        uint256 yieldsLength = yields.length;
        for(uint8 i = 0; i < yieldsLength;) {
            try yields[i].update() {

            } catch {

            }
            unchecked { ++i; }
        }
    }

    /**
     * @dev update pending yields
     */
    function updatePendingYieldReward(address user) internal {
        uint256 yieldsLength = yields.length;
        for(uint8 i = 0; i < yieldsLength;) {
            yields[i].updatePendingYieldReward(user);
            unchecked { ++i; }
        }
    }

    /**
     * @dev update instant accumulated share of yield
     */
    function updateInstantAccumulatedShareOfYieldReward(address user) internal {
        uint256 yieldsLength = yields.length;
        for(uint8 i = 0; i < yieldsLength;) {
            yields[i].updateInstantAccumulatedShareOfYieldReward(user);
            unchecked { ++i; }
        }
    }

    /**
     * @notice stake `stakeToken` to msg.sender
     * @param stakeTokenAmount amount of `stakeToken`
     */
    function stake(uint256 stakeTokenAmount) external {
        stakeTo(msg.sender, stakeTokenAmount);
    }

    /**
     * @notice stake `stakeToken` to `beneficiary`
     * @param beneficiary the address of user
     * @param stakeTokenAmount amount of `stakeToken`
     */
    function stakeTo(address beneficiary, uint256 stakeTokenAmount) public onlyNonStakePaused {
        require(stakeTokenAmount > 0, "USBStaking: stakeTokenAmount should be not zero");
        update();
        UserPosition storage user = userPosition[beneficiary];
        uint256 accumulatedShareOfReward = getAccumulatedShareOfReward(beneficiary);
        if (accumulatedShareOfReward > user.instantAccumulatedShareOfReward) {
            user.pendingReward += accumulatedShareOfReward - user.instantAccumulatedShareOfReward;  
        }
        updatePendingYieldReward(beneficiary);
        stakeToken.safeTransferFrom(address(msg.sender), address(this), stakeTokenAmount);
        totalStake += stakeTokenAmount;
        user.stake += stakeTokenAmount;
        user.instantAccumulatedShareOfReward = getAccumulatedShareOfReward(beneficiary);
        updateInstantAccumulatedShareOfYieldReward(beneficiary);
        emit Stake(beneficiary, stakeTokenAmount);
    }

    /**
     * @notice unstake `stakeToken`.
     * @param stakeTokenAmount amount of `stakeToken` to unstake
     */
    function unstake(uint256 stakeTokenAmount) external whenNotPaused {
        UserPosition storage user = userPosition[msg.sender];
        require(stakeTokenAmount > 0, "USBStaking: stakeTokenAmount should be not zero");
        require(stakeTokenAmount <= user.stake, "USBStaking: amount exceeded user stake");
        update();
        uint256 accumulatedShareOfReward = getAccumulatedShareOfReward(msg.sender);
        if(accumulatedShareOfReward > user.instantAccumulatedShareOfReward) {
            user.pendingReward += accumulatedShareOfReward - user.instantAccumulatedShareOfReward;
        }
        updatePendingYieldReward(msg.sender);
        user.stake -= stakeTokenAmount;
        totalStake -= stakeTokenAmount;
        stakeToken.safeTransfer(msg.sender, stakeTokenAmount);
        user.instantAccumulatedShareOfReward = getAccumulatedShareOfReward(msg.sender);
        updateInstantAccumulatedShareOfYieldReward(msg.sender);
        emit Unstake(msg.sender, stakeTokenAmount);
    }

    /**
     * @notice claim the reward
     */
    function claimReward() public whenNotPaused {
        update();
        UserPosition storage user = userPosition[msg.sender];
        uint256 accumulatedShareOfReward = getAccumulatedShareOfReward(msg.sender);
        if(accumulatedShareOfReward > user.instantAccumulatedShareOfReward) {
            user.pendingReward += accumulatedShareOfReward - user.instantAccumulatedShareOfReward;
            user.instantAccumulatedShareOfReward = accumulatedShareOfReward;
        }
        updatePendingYieldReward(msg.sender);
        updateInstantAccumulatedShareOfYieldReward(msg.sender);
        uint256 pendingReward = user.pendingReward;
        if (pendingReward > 0) {
            totalClaimedReward += pendingReward;
            user.claimedReward += pendingReward;
            user.pendingReward = 0;
            _safeRewardTokenTransfer(msg.sender, pendingReward);
            emit ClaimReward(msg.sender, pendingReward);
        }
    }

    /**
     * @notice claim reward from staking and yield
     */
    function claimAllReward() external whenNotPaused {
        uint256 yieldsLength = yields.length;
        for(uint8 i = 0; i < yieldsLength;) {
            yields[i].claimYieldRewardTo(msg.sender);
            unchecked { ++i; }
        }
        claimReward();
    }

    /**
     * @notice stake the reward. Possible to call if reward token equal to stake token
     */
    function claimRewardAndStake() external whenNotPaused {
        require(address(rewardToken) == address(stakeToken), "USBStaking: not allowed for this product");
        update();
        UserPosition storage user = userPosition[msg.sender];
        uint256 accumulatedShareOfReward = getAccumulatedShareOfReward(msg.sender);
        if (accumulatedShareOfReward > user.instantAccumulatedShareOfReward) {
            user.pendingReward += accumulatedShareOfReward - user.instantAccumulatedShareOfReward;
        }
        uint256 pendingReward = user.pendingReward;
        require(pendingReward > 0, "USBStaking: pendingReward=0");
        require(pendingReward <= getRewardTokenAmount(), "USBStaking: insufficient amount of rewardToken");
        totalClaimedReward += pendingReward;
        user.claimedReward += pendingReward;
        updatePendingYieldReward(msg.sender);
        totalStake += pendingReward;
        user.stake += pendingReward;
        user.pendingReward = 0;
        user.instantAccumulatedShareOfReward = getAccumulatedShareOfReward(msg.sender);
        updateInstantAccumulatedShareOfYieldReward(msg.sender);
        emit ClaimRewardAndStake(msg.sender, pendingReward);
    }

    /**
     * @notice unstake all staked token + claim reward
     */
    function exit() external whenNotPaused {
        update();
        UserPosition storage user = userPosition[msg.sender];
        uint256 userStake = user.stake;
        require(userStake > 0, "USBStaking: no stake");
        uint256 accumulatedShareOfReward = getAccumulatedShareOfReward(msg.sender);
        if (accumulatedShareOfReward > user.instantAccumulatedShareOfReward) {
            user.pendingReward += accumulatedShareOfReward - user.instantAccumulatedShareOfReward;
        }
        updatePendingYieldReward(msg.sender);
        totalStake -= userStake;
        user.stake = 0;
        stakeToken.safeTransfer(msg.sender, userStake);
        
        uint256 pendingReward = user.pendingReward;
        if(pendingReward > 0){
            totalClaimedReward += pendingReward;
            user.claimedReward += pendingReward;
            user.pendingReward = 0;
            _safeRewardTokenTransfer(msg.sender, pendingReward);
        }
        user.instantAccumulatedShareOfReward = 0;
        updateInstantAccumulatedShareOfYieldReward(msg.sender);
        emit Exit(msg.sender, userStake, pendingReward);
    }

    /**
     * @notice emergency unstake `stakeToken` without carrying about reward
     */
    function emergencyUnstake() external {
        if (!paused()) {
            update();
        }
        UserPosition storage user = userPosition[msg.sender];
        uint256 userStake = user.stake;
        require(userStake > 0, "USBStaking: no emergency stake");
        totalStake -= userStake;
        user.stake = 0;
        user.instantAccumulatedShareOfReward = 0;
        stakeToken.safeTransfer(address(msg.sender), userStake);
        emit EmergencyUnstake(msg.sender, userStake);
    }

    /**
     * @dev internal transfer of reward token
     * @param beneficiar address of receiver
     * @param amount amount of reward token `beneficiar` will receive
     */
    function _safeRewardTokenTransfer(address beneficiar, uint256 amount) internal {
        uint256 rewardTokenBalance = getRewardTokenAmount();
        if (amount > rewardTokenBalance) {
            rewardToken.safeTransfer(beneficiar, rewardTokenBalance);
            uint256 shortfall = amount - rewardTokenBalance;
            totalClaimedReward -= shortfall;
            userPosition[beneficiar].claimedReward -= shortfall;
            userPosition[beneficiar].pendingReward += shortfall;
        } else {
            rewardToken.safeTransfer(beneficiar, amount);
        }
    }

    //************* END MAIN FUNCTIONS *************//
    //************* VIEW FUNCTIONS *************//

    /**
     * @dev return the share of reward of `user` by his stake
     */
    function getAccumulatedShareOfReward(address user) public view returns (uint256) {
        uint256 accumulatorMultiplier = getAccumulatorMultiplier();
        return userPosition[user].stake * accumulatedRewardTokenPerStakeToken / accumulatorMultiplier;
    }

    /**
     * @dev calculates the pending reward from `lastRewardBlock` to current block + `blocks`
     * @param blocks the number of blocks to get the pending reward
     */
    function calculateTotalPendingReward(uint256 blocks) public view returns (uint256) {
        uint256 blockDelta = getBlockDelta(lastRewardBlock, block.number + blocks);
        return blockDelta * rewardPerBlock;
    }

    /**
     * @dev return sum of all rewardsPerBlock to current block + `blocks`
     * @param blocks the number of blocks
     */
    function getTotalPendingReward(uint256 blocks) public view returns (uint256) {
        return totalPendingReward + calculateTotalPendingReward(blocks);
    }

    /**
     * @dev return the unclaimed rewards amount of users
     */
    function getUnclaimedRewardAmount() external view returns (uint256 unclaimedRewards) {
        uint256 _totalPendingReward = getTotalPendingReward(0);
        if (_totalPendingReward >= totalClaimedReward) {
            unclaimedRewards = _totalPendingReward - totalClaimedReward;
        }
    }

    /**
     * @dev return the length of array `yields`
     */
    function getYieldsLength() external view returns (uint256) {
        return yields.length;
    }

    /**
     * @dev return the amount of reward token on contract
     */
    function getRewardTokenAmount() public view returns (uint256) {
        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        if (rewardToken == stakeToken) {
            return rewardTokenBalance > totalStake ? rewardTokenBalance - totalStake : 0;
        } else {
            return rewardTokenBalance;
        }
    }
    
    /**
     * @dev return the amount of stake token on contract
     */
    function getStakedTokenAmount() external view returns (uint256) {
        return stakeToken.balanceOf(address(this));
    }

    /** 
     * @dev return reward blockDelta over the given from to to block 
     */
    function getBlockDelta(uint256 from, uint256 to) public view returns (uint256 blockDelta) {
        require (from <= to, "USBStaking: should be from<=to");
        uint256 _startBlock = startBlock;
        uint256 _endBlock = endBlock;
        if (_startBlock == 0 || to <= _startBlock || from >= _endBlock) {
            return 0;
        }
        uint256 lastBlock = to <= _endBlock ? to : _endBlock;
        uint256 firstBlock = from >= _startBlock ? from : _startBlock;
        blockDelta = lastBlock - firstBlock;
    }

    /**
     * @dev return user position as (user stake, totalClaimedReward, intime pending reward)
     */
    function getUserPosition(address _user) external view returns (uint256 userStake, uint256 userClaimedReward, uint256 userPendingReward) {
        UserPosition storage user = userPosition[_user];
        uint256 accumulatedRewardTokenPerStakedTokenLocal = accumulatedRewardTokenPerStakeToken;
        uint256 accumulatorMultiplier = getAccumulatorMultiplier();
        userPendingReward = user.pendingReward;
        if (block.number > lastRewardBlock && totalStake != 0) {
            uint256 blockDelta = getBlockDelta(lastRewardBlock, block.number);
            uint256 rewardAmount = blockDelta * rewardPerBlock;
            accumulatedRewardTokenPerStakedTokenLocal += rewardAmount * accumulatorMultiplier / totalStake;
            uint256 accumulatedShareOfReward = user.stake * accumulatedRewardTokenPerStakedTokenLocal / accumulatorMultiplier;
            if (accumulatedShareOfReward > user.instantAccumulatedShareOfReward) {
                userPendingReward += accumulatedShareOfReward - user.instantAccumulatedShareOfReward;
            }
        }
        return (user.stake, user.claimedReward, userPendingReward);
    }

    /**
     * @dev returns the accumulator multiplier for accumulatedRewardTokenPerStakeToken
     * @dev Description why `accumulatorMultiplier` look by this way
        There are need to calculate this formula:
        blockDifference * rewardPerBlock * accamulatorMultiplier / totalStaked
        The dimention of it 
        [blockDifference] * [rewardPerBlock] * [accamulatorMultiplier] / [totalStaked]=
        =block * rewardToken / block * 1 / stakeToken = rewardToken / stakeToken
        reward token and stake token may have different decimals.
        So, we need to optimize this formula by unknown variable `accamulatorMultiplier` to be positive integer
        `rewardPerBlock * accamulatorMultiplier / totalStaked` is positive integer (1)
                                    
        let accamulatorMultiplier = 10 ** (12 + stakeTokenDecimals - rewardTokenDecimals), if stakeTokenDecimals >= rewardTokenDecimals
        let accamulatorMultiplier = 10 ** stakeTokenDecimals, if stakeTokenDecimals < rewardTokenDecimals

        To show that it is good solution for optimization, take a metric:
        M = LOG10(rewardPerBlock * accamulatorMultiplier / totalStaked)

        M = 18 , if stake token decimals < reward token decimals
        M = 12 , if stake token decimals >= reward token decimals

        In another words, this metric shows that order of formula (1) will always be positive integer and will have order 18 or 12.

     */
    function getAccumulatorMultiplier() public view returns (uint256 accumulatorMultiplier) {
        uint8 stakeTokenDecimals = stakeToken.decimals();
        uint8 rewardTokenDecimals = rewardToken.decimals();
        if (stakeTokenDecimals >= rewardTokenDecimals){
            accumulatorMultiplier = 10 ** (12 + stakeTokenDecimals - rewardTokenDecimals);
        } else {
            accumulatorMultiplier =  10 ** stakeTokenDecimals;
        }
    }

    //************* END VIEW FUNCTIONS *************//

}