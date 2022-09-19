// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./imports/IBEP20.sol";
import "./imports/SafeBEP20.sol";


contract PoolStakingLock is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // The address of retrostaking factory
    address public POOL_STAKING_FACTORY;

    // Whether a limit is set for users
    bool public hasUserLimit;

    // Whether a limit is set for Pool
    bool public hasPoolLimit;

    // Whether a HarvestLock
    bool public hasPoolHL;

    // Whether a WithdrawLock
    bool public hasPoolWL;

    // Whether it is initialized
    bool public isInitialized;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The block number when mining ends.
    uint256 public bonusEndBlock;

    // The block number when mining starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;

    // The pool limit global staking (0 if none)
    uint256 public poolLimitGlobal;

    // The pool minimum limit for amount deposited
    uint256 public poolMinDeposit;

    // Tokens created per block.
    uint256 public rewardPerBlock;

    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // Keep track of number of tokens staked in case the contract earns reflect fees
    uint256 public totalStaked = 0;

    // The reward token
    IBEP20 public rewardToken;

    // The staked token
    IBEP20 public stakedToken;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
        uint256 rewardLockedUp; //Reward locked up
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);
    event Withdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 amount);

    constructor() {
        POOL_STAKING_FACTORY = msg.sender;
    }

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _bonusEndBlock: end block
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _poolLimitGlobal: pool limit global in stakedToken (if any, else 0)
     * @param _poolMinDeposit: pool minimal limit for deposited amount
     * @param _poolHarvestLock: pool Harvest is locked (if true is enable, else false is disable)
     * @param _poolWithdrawLock: pool Withdraw is locked (if true is enable, else false is disable)
     * @param _admin: admin address with ownership
     */
    function initialize(
        IBEP20 _stakedToken,
        IBEP20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        uint256 _poolLimitGlobal,
        uint256 _poolMinDeposit,
        bool _poolHarvestLock,
        bool _poolWithdrawLock,
        address _admin
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == POOL_STAKING_FACTORY, "Not factory");

        // Make this contract initialized
        isInitialized = true;

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        if (_poolLimitPerUser > 0) {
            hasUserLimit = true;
            poolLimitPerUser = _poolLimitPerUser;
        }

        if (_poolLimitGlobal > 0) {
            hasPoolLimit = true;
            poolLimitGlobal = _poolLimitGlobal;
        }

        if (_poolMinDeposit > 0) {
            poolMinDeposit = _poolMinDeposit;
        }

        if (_poolHarvestLock) {
            hasPoolHL = true;
        }

        if (_poolWithdrawLock) {
            hasPoolWL = true;
        }

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(
            _getBlockNumber() < bonusEndBlock, 
            "Cannot deposit after the last reward block"
        );
        uint256 finalDepositAmount = 0;

        if (hasUserLimit) {
            require(
                _amount.add(user.amount) <= poolLimitPerUser,
                "User amount above limit"
            );
        }

        if (hasPoolLimit) {
            require(
                _amount.add(totalStaked) <= poolLimitGlobal,
                "Global amount above limit"
            );
        }

        require(
            user.amount + _amount >= poolMinDeposit,
            "Amount under limit"
        );

        _updatePool();

        if (user.amount > 0) {
            payOrLockupPending(user);
        }

        if (_amount > 0) {
            uint256 preStakeBalance = stakedToken.balanceOf(address(this));
            stakedToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            finalDepositAmount = stakedToken.balanceOf(address(this)).sub(
                preStakeBalance
            );
            user.amount = user.amount.add(finalDepositAmount);
            totalStaked = totalStaked.add(finalDepositAmount);
        }

        _updateRewardDebt(user);

        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        bool poolStatusWithdraw = poolWIsLock();
        require(user.amount >= _amount, "Amount to withdraw too high");

        _updatePool();

        // Withdraw pending AUTO
        payOrLockupPending(user);

        if (!poolStatusWithdraw) {
            if (_amount > 0) {
                stakedToken.safeTransfer(address(msg.sender), _amount);
                user.amount = user.amount.sub(_amount);
                totalStaked = totalStaked.sub(_amount);
            }
        } else {
            revert("Pool locked");
        }

        _updateRewardDebt(user);

        emit Withdraw(msg.sender, _amount);
    }

    function harvest() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        _updatePool();

        // Withdraw pending AUTO
        require(payOrLockupPending(user), "Harvests locked");
        _updateRewardDebt(user);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
            totalStaked = totalStaked.sub(amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    function rewardBalance() public view returns (uint256) {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (stakedToken == rewardToken) return balance.sub(totalStaked);
        return balance;
    }

    function totalStakeTokenBalance() public view returns (uint256) {
        if (stakedToken == rewardToken) return totalStaked;
        return stakedToken.balanceOf(address(this));
    }

    function poolHIsLock() public view returns (bool) {
        bool statusPool;
        if (hasPoolHL) {
            statusPool = bonusEndBlock >= _getBlockNumber();
            if (startBlock >= _getBlockNumber()) {
                statusPool = false;
            }
        }
        return statusPool;
    }

    function poolWIsLock() public view returns (bool) {
        bool statusPool;
        if (hasPoolWL) {
            statusPool = bonusEndBlock >= _getBlockNumber();
            if (startBlock >= _getBlockNumber()) {
                statusPool = false;
            }
        }
        return statusPool;
    }

    function poolChangeHLock(bool _value) public onlyOwner {
        hasPoolHL = _value;
    }

    function poolChangeWLock(bool _value) public onlyOwner {
        hasPoolWL = _value;
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(_amount <= rewardBalance(), "not enough rewards");
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(
            _tokenAddress != address(stakedToken),
            "Cannot be staked token"
        );

        IBEP20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        bonusEndBlock = _getBlockNumber();
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(
        bool _hasUserLimit,
        uint256 _poolLimitPerUser
    ) external onlyOwner {
        require(hasUserLimit, "Must be set");
        if (_hasUserLimit) {
            require(
                _poolLimitPerUser > poolLimitPerUser,
                "New limit must be higher"
            );
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(poolLimitPerUser);
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(_getBlockNumber() < startBlock, "Pool has started");
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) external onlyOwner {
        require(_getBlockNumber() < startBlock, "Pool has started");
        require(
            _startBlock < _bonusEndBlock,
            "New startBlock must be lower than new endBlock"
        );
        require(
            _getBlockNumber() < _startBlock,
            "New startBlock must be higher than current block"
        );

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
        uint256 stakedTokenSupply = totalStaked;
        if (_getBlockNumber() > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, _getBlockNumber());
            uint256 reward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare = accTokenPerShare.add(
                reward.mul(PRECISION_FACTOR).div(stakedTokenSupply)
            );
            uint256 pending = user
                .amount
                .mul(adjustedTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(user.rewardDebt);
            return pending.add(user.rewardLockedUp);
        } else {
            uint256 pending = user
                .amount
                .mul(accTokenPerShare)
                .div(PRECISION_FACTOR)
                .sub(user.rewardDebt);
            return pending.add(user.rewardLockedUp);
        }
    }

    function payOrLockupPending(UserInfo storage user) internal returns(bool) {
        bool poolStatusHarvest = poolHIsLock();

        uint256 pending = user
            .amount
            .mul(accTokenPerShare)
            .div(PRECISION_FACTOR)
            .sub(user.rewardDebt);
        uint256 totalRewards = pending.add(user.rewardLockedUp);

        if (!poolStatusHarvest) {
            if (totalRewards > 0) {
                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(
                    user.rewardLockedUp
                );
                user.rewardLockedUp = 0;

                // send rewards
                uint256 currentRewardBalance = rewardBalance();
                if (currentRewardBalance > 0) {
                    if (totalRewards > currentRewardBalance) {
                        rewardToken.safeTransfer(
                            address(msg.sender),
                            currentRewardBalance
                        );
                        emit Harvest(msg.sender, currentRewardBalance);
                    } else {
                        rewardToken.safeTransfer(
                            address(msg.sender),
                            totalRewards
                        );
                        emit Harvest(msg.sender, totalRewards);
                    }
                }
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
        }

        return !poolStatusHarvest;
    }

    function _updateRewardDebt(UserInfo storage user) internal {
        user.rewardDebt = user.amount.mul(accTokenPerShare).div(
            PRECISION_FACTOR
        );
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (_getBlockNumber() <= lastRewardBlock) {
            return;
        }

        uint256 stakedTokenSupply = totalStaked;

        if (stakedTokenSupply == 0) {
            lastRewardBlock = _getBlockNumber();
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, _getBlockNumber());
        uint256 reward = multiplier.mul(rewardPerBlock);
        accTokenPerShare = accTokenPerShare.add(
            reward.mul(PRECISION_FACTOR).div(stakedTokenSupply)
        );
        lastRewardBlock = _getBlockNumber();
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    function _getBlockNumber() internal view virtual returns(uint256) {
        return block.number;
    }
}