// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/ISFIRewarder.sol";

/**
 * @dev Contract for rewarding users with SFI for the Saffron liquidity mining program.
 *
 * Code based off Sushiswap's Masterchef contract with the addition of SFIRewarder.
 * 
 * NOTE: Do not add pools with LP tokens that are deflationary or have reflection.
 */
contract SaffronStakingV2 is Ownable {
    using SafeERC20 for IERC20;

    // Structure of user deposited amounts and their pending reward debt.
    struct UserInfo {
        // Amount of tokens added by the user.
        uint256 amount;

        // Accounting mechanism. Prevents double-redeeming rewards in the same block.
        uint256 rewardDebt;
    }

    // Structure holding information about each pool's LP token and allocation information.
    struct PoolInfo {
        // LP token contract. In the case of single-asset staking this is an ERC20.
        IERC20 lpToken;

        // Allocation points to determine how many SFI will be distributed per block to this pool.
        uint256 allocPoint;

        // The last block that accumulated rewards were calculated for this pool.
        uint256 lastRewardBlock; 

        // Accumulator storing the accumulated SFI earned per share of this pool.
        // Shares are user lpToken deposit amounts. This value is scaled up by 1e18.
        uint256 accSFIPerShare; 
    }

    // The amount of SFI to be rewarded per block to all pools.
    uint256 public sfiPerBlock;

    // SFI rewards are cut off after a specified block. Can be updated by governance to extend/reduce reward time.
    uint256 public rewardCutoff; 

    // SFIRewarder contract holding the SFI tokens to be rewarded to users.
    ISFIRewarder public rewarder;

    // List of pool info structs by pool id.
    PoolInfo[] public poolInfo;

    // Mapping to store list of added LP tokens to prevent accidentally adding duplicate pools.
    mapping(address => bool) public lpTokenAdded; 

    // Mapping of mapping to store user informaton indexed by pool id and the user's address.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    constructor(address _rewarder, uint256 _sfiPerBlock, uint256 _rewardCutoff) {
        require(_rewarder != address(0), "invalid rewarder");
        require(_rewardCutoff >= block.number, "invalid rewardCutoff");
        rewarder = ISFIRewarder(_rewarder);
        sfiPerBlock = _sfiPerBlock;
        rewardCutoff = _rewardCutoff;
    }

    /** 
     * @dev Update the SFIRewarder. Only callable by the contract owner.
     * @param _rewarder The new SFIRewarder account.
     */
    function setRewarder(address _rewarder) external onlyOwner {
        require(_rewarder != address(0), "invalid rewarder address");
        rewarder = ISFIRewarder(_rewarder);
    }

    /** 
     * @dev Update the amount of SFI rewarded per block. Only callable by the contract owner.
     * @param _sfiPerBlock The new SFI per block amount to be distributed.
     */
    function setRewardPerBlock(uint256 _sfiPerBlock) external onlyOwner {
        massUpdatePools();
        sfiPerBlock = _sfiPerBlock;
        emit RewardPerBlockSet(sfiPerBlock);
    }

    /** 
     * @dev Update the reward end block. Only callable by the contract owner.
     * @param _rewardCutoff The new cut-off block to end SFI reward distribution.
     */
    function setRewardCutoff(uint256 _rewardCutoff) external onlyOwner {
        require(_rewardCutoff >= block.number, "invalid rewardCutoff");
        rewardCutoff = _rewardCutoff;
    }

    /** 
     * @dev Update the reward end block and sfiPerBlock atomically. Only callable by the contract owner.
     * @param _rewardCutoff The new cut-off block to end SFI reward distribution.
     * @param _sfiPerBlock The new SFI per block amount to be distributed.
     */
    function setRewardPerBlockAndRewardCutoff(uint256 _sfiPerBlock, uint256 _rewardCutoff) external onlyOwner {
        require(_rewardCutoff >= block.number, "invalid rewardCutoff");
        massUpdatePools();
        sfiPerBlock = _sfiPerBlock;
        rewardCutoff = _rewardCutoff;
    }

    /** 
     * @dev Return the number of pools in the poolInfo list.
     */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @dev Add a new pool specifying its lp token and allocation points.
     * @param _allocPoint The allocationPoints for the pool. Determines SFI per block.
     * @param _lpToken Token address for the LP token in this pool.
     */
    function add(uint256 _allocPoint, address _lpToken) public onlyOwner {
        require(_lpToken != address(0), "invalid _lpToken address");
        require(!lpTokenAdded[_lpToken], "lpToken already added");
        require(block.number < rewardCutoff, "can't add pool after cutoff");
        require(_allocPoint > 0, "can't add pool with 0 ap");
        massUpdatePools();
        totalAllocPoint = totalAllocPoint + _allocPoint;
        lpTokenAdded[_lpToken] = true;
        poolInfo.push(PoolInfo({lpToken: IERC20(_lpToken), allocPoint: _allocPoint, lastRewardBlock: block.number, accSFIPerShare: 0}));
    }

    /**
     * @dev Set the allocPoint of the specific pool with id _pid.
     * @param _pid The pool id that is to be set.
     * @param _allocPoint The new allocPoint for the pool.
     */
    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {
        require(_pid < poolInfo.length, "can't set non-existant pool");
        require(_allocPoint > 0, "can't set pool to 0 ap");
        massUpdatePools();
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    /**
     * @dev Return the pending SFI rewards of a user for a specific pool id.
     *
     * Helper function for front-end web3 implementations.
     *
     * @param _pid Pool id to get SFI rewards report from.
     * @param _user User account to report SFI rewards from.
     * @return Pending SFI amount for the user indexed by pool id.
     */
    function pendingSFI(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accSFIPerShare = pool.accSFIPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        uint256 latestRewardBlock = block.number >= rewardCutoff ? rewardCutoff : block.number;

        if (latestRewardBlock > pool.lastRewardBlock && lpSupply != 0) {
            // Get number of blocks to multiply by
            uint256 multiplier = latestRewardBlock - pool.lastRewardBlock;
            // New SFI reward is the number of blocks multiplied by the SFI per block times multiplied by the pools share of the total
            uint256 sfiReward = multiplier * sfiPerBlock * pool.allocPoint;
            // Add delta/change in share of the new reward to the accumulated SFI per share for this pool's token
            accSFIPerShare = accSFIPerShare + (sfiReward * 1e18 / lpSupply / totalAllocPoint);
        }
        // Return the pending SFI amount for this user
        return (user.amount * accSFIPerShare / 1e18) - user.rewardDebt;
    }

    /**
     * @dev Update reward variables for all pools. Be careful of gas spending! More than 100 pools is not recommended.
     */
    function massUpdatePools() public {
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            updatePool(pid);
        }
    }

    /**
     * @dev Update accumulated SFI shares of the specified pool.
     * @param _pid The id of the pool to be updated.
     */
    function updatePool(uint256 _pid) public returns (PoolInfo memory) {
        // Retrieve pool info by the pool id
        PoolInfo storage pool = poolInfo[_pid];

        // Only reward SFI for blocks earlier than rewardCutoff block
        uint256 latestRewardBlock = block.number >= rewardCutoff ? rewardCutoff : block.number;

        // Don't update twice in the same block
        if (latestRewardBlock > pool.lastRewardBlock) {
            // Get the amount of this pools token owned by the SaffronStaking contract
            uint256 lpSupply = pool.lpToken.balanceOf(address(this));
            // Calculate new rewards if amount is greater than 0
            if (lpSupply > 0) {
                // Get number of blocks to multiply by
                uint256 multiplier = latestRewardBlock - pool.lastRewardBlock;
                // New SFI reward is the number of blocks multiplied by the SFI per block times multiplied by the pools share of the total
                uint256 sfiReward = multiplier * sfiPerBlock * pool.allocPoint;
                // Add delta/change in share of the new reward to the accumulated SFI per share for this pool's token
                pool.accSFIPerShare = pool.accSFIPerShare + (sfiReward * 1e18 / lpSupply / totalAllocPoint);
            } 
            // Set the last reward block to the most recent reward block
            pool.lastRewardBlock = latestRewardBlock;
        }
        // Return this pools updated info
        return poolInfo[_pid];
    }

    /**
     * @dev Deposit the user's lp token into the the specified pool.
     * @param _pid Pool id where the user's asset is being deposited.
     * @param _amount Amount to deposit into the pool.
     */
    function deposit(uint256 _pid, uint256 _amount) public {
        // Get pool identified by pid
        PoolInfo memory pool = updatePool(_pid);
        // Get user in this pool identified by msg.sender address
        UserInfo storage user = userInfo[_pid][msg.sender];
        // Calculate pending SFI earnings for this user in this pool
        uint256 pending = (user.amount * pool.accSFIPerShare / 1e18) - user.rewardDebt;

        // Effects
        // Add the new deposit amount to the pool user's amount total
        user.amount = user.amount + _amount;
        // Update the pool user's reward debt to this new amount
        user.rewardDebt = user.amount * pool.accSFIPerShare / 1e18;

        // Interactions
        // Transfer pending SFI rewards to the user
        safeSFITransfer(msg.sender, pending);
        // Transfer the users tokens to this contract (deposit them in this contract)
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        emit TokensDeposited(msg.sender, _pid, _amount, pool.lpToken.balanceOf(address(this)));
    }

    /**
     * @dev Withdraw the user's lp token from the specified pool.
     * @param _pid Pool id from which the user's asset is being withdrawn.
     * @param _amount Amount to withdraw from the pool.
     */
    function withdraw(uint256 _pid, uint256 _amount) public {
        // Get pool identified by pid
        PoolInfo memory pool = updatePool(_pid);
        // Get user in this pool identified by msg.sender address
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "can't withdraw more than user balance");
        // Calculate pending SFI earnings for this user in this pool
        uint256 pending = (user.amount * pool.accSFIPerShare / 1e18) - user.rewardDebt;

        // Effects
        // Subtract the new withdraw amount from the pool user's amount total
        user.amount = user.amount - _amount;
        // Update the pool user's reward debt to this new amount
        user.rewardDebt = user.amount * pool.accSFIPerShare / 1e18;

        // Interactions
        // Transfer pending SFI rewards to the user
        safeSFITransfer(msg.sender, pending);
        // Transfer contract's tokens amount to this user (withdraw them from this contract)
        pool.lpToken.safeTransfer(address(msg.sender), _amount);

        emit TokensWithdrawn(msg.sender, _pid, _amount, pool.lpToken.balanceOf(address(this)));
    }

    /**
     * @dev Emergency function to withdraw a user's asset in a specified pool.
     * @param _pid Pool id from which the user's asset is being withdrawn.
     */
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;

        // Effects
        user.amount = 0;
        user.rewardDebt = 0;

        // Interactions
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        emit TokensEmergencyWithdrawn(msg.sender, _pid, amount, pool.lpToken.balanceOf(address(this)));
    }

    /**
     * @dev Transfer SFI from the SFIRewarder contract to the user's account.
     * @param to Account to transfer SFI to from the SFIRewarder contract.
     * @param amount Amount of SFI to transfer from the SFIRewarder to the user's account.
     */
    function safeSFITransfer(address to, uint256 amount) internal {
        if (amount > 0) rewarder.rewardUser(to, amount);
    }

    /**
     * @dev Emitted when `amount` tokens are deposited by `user` into pool id `pid`.
     */
    event TokensDeposited(address indexed user, uint256 indexed pid, uint256 amount, uint256 balance);

    /**
     * @dev Emitted when `amount` tokens are withdrawn by `user` from pool id `pid`.
     */
    event TokensWithdrawn(address indexed user, uint256 indexed pid, uint256 amount, uint256 balance);

    /**
     * @dev Emitted when `amount` tokens are emergency withdrawn by `user` from pool id `pid`.
     */
    event TokensEmergencyWithdrawn(address indexed user, uint256 indexed pid, uint256 amount, uint256 balance);

    /**
     * @dev Emitted when `sfiPerBlock` is set by governance.
     */
    event RewardPerBlockSet(uint256 newSfiPerBlock);

}