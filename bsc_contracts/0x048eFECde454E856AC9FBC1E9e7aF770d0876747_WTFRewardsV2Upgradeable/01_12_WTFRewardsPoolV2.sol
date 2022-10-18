// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IWTFRewards.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract WTFRewardsV2Upgradeable is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /***************************************************** STORAGE **********************************************/

    IVotingEscrow public vewtf;
    IERC20Upgradeable public wtf;

    uint256 public constant PRECISION = 1e18;

    struct User {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct Pool {
        uint256 accRewardPerShare;
        uint256 startRewardBlock;
        uint256 endRewardBlock;
        uint256 lastRewardBlock;
        uint256 rewardPerBlock;
        uint256 totalStaked;
    }

    Pool public pool;
    mapping(address => User) public users;

    // V1 Staking data

    IVotingEscrow public vewtfV1;
    IWTFRewards public wtfRewardsV1;
    mapping(address => User) public usersV1;

    // Events

    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 rewardV1, uint256 revardV2);
    event UpdatePool(uint256 multiplier, uint256 totalStaked);
    event AdminTokenRecovery(address indexed tokenRecovered, uint256 amount);
    event NewStartAndEndBlocks(
        uint256 startRewardBlock,
        uint256 endRewardBlock
    );
    event NewRewardPerBlock(uint256 rewardPerBlock);

    function init(
        address _vewtf,
        address _vewtfV1,
        address _wtfRewardsV1,
        address _wtf,
        uint256 _rewardPerBlock,
        uint256 _startRewardBlock,
        uint256 _endRewardBlock
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        vewtf = IVotingEscrow(_vewtf);
        vewtfV1 = IVotingEscrow(_vewtfV1);
        wtfRewardsV1 = IWTFRewards(_wtfRewardsV1);
        wtf = IERC20Upgradeable(_wtf);
        pool.rewardPerBlock = _rewardPerBlock;
        pool.startRewardBlock = _startRewardBlock;
        pool.endRewardBlock = _endRewardBlock;
        pool.lastRewardBlock = _startRewardBlock;
    }

    /**
     * @dev calls to stake and unstake are allowed only from the Voting Escrow contract that automatically registers
     * deposits and withdrawals
     */

    modifier onlyVotingEscrow() {
        require(msg.sender == address(vewtf), "VeWTF Staking: Not authorized");
        _;
    }

    function getRewardDebt(address account) external view returns (uint256) {
        return users[account].rewardDebt;
    }

    function totalStaked() external view returns (uint256) {
        return wtfRewardsV1.totalStaked() + pool.totalStaked;
    }

    function getAccountData(address account)
        external
        view
        returns (User memory user)
    {
        user = users[account];
    }

    function isPoolActive() public view returns (bool) {
        return (block.number < pool.endRewardBlock);
    }

    function lastRewardBlock() external view returns (uint256) {
        return pool.lastRewardBlock;
    }

    function rewardPerShare() external view returns (uint256) {
        return pool.accRewardPerShare;
    }

    function stake(address account, uint256 _amount)
        external
        nonReentrant
        onlyVotingEscrow
    {
        require(isPoolActive(), "VeWTF Staking: Rewards pool is not active");
        require(_amount > 0, "VeWTF Staking: Amount is zero");

        User storage user = users[account];

        _updatePool();

        if (user.amount > 0) {
            uint256 reward = pool
                .accRewardPerShare
                .mul(user.amount)
                .div(PRECISION)
                .sub(user.rewardDebt);
            if (reward > 0) {
                wtf.safeTransfer(account, reward);
            }
        }

        user.amount = user.amount.add(_amount);
        pool.totalStaked = pool.totalStaked.add(_amount);
        user.rewardDebt = pool.accRewardPerShare.mul(user.amount).div(
            PRECISION
        );

        emit Stake(account, _amount);
    }

    function unstake(address account, uint256 _amount)
        external
        nonReentrant
        onlyVotingEscrow
    {
        User storage user = users[account];

        require(
            user.amount >= _amount,
            "VeWTF Staking: Not enough tokens to withdraw"
        );
        require(_amount > 0, "VeWTF Staking: Can`t withdraw zero amount");

        _updatePool();

        uint256 reward = pool
            .accRewardPerShare
            .mul(user.amount)
            .div(PRECISION)
            .sub(user.rewardDebt);

        if (reward > 0) {
            wtf.safeTransfer(account, reward);
        }

        user.amount = user.amount.sub(_amount);
        pool.totalStaked = pool.totalStaked.sub(_amount);

        user.rewardDebt = pool.accRewardPerShare.mul(user.amount).div(
            PRECISION
        );

        emit Unstake(account, _amount);
    }

    /* 
     Migrate user information from staking V1
    */

    function migrateDataFromStakingV1(address[] memory _usersList)
        public
        onlyOwner
    {
        _migrateDataFromStakingV1(_usersList);
    }

    function _migrateDataFromStakingV1(address[] memory _usersList) internal {
        // Migrate pool info
        uint256 lastRewardBlockV1 = wtfRewardsV1.lastRewardBlock();
        uint256 accRewardPerShareV1 = wtfRewardsV1.rewardPerShare();

        pool.lastRewardBlock = lastRewardBlockV1;
        pool.accRewardPerShare = accRewardPerShareV1;

        // Migrate users info
        for (uint256 i = 0; i < _usersList.length; i++) {
            User storage user = usersV1[_usersList[i]];
            user.amount = wtfRewardsV1.users(_usersList[i]).amount;
            user.rewardDebt = wtfRewardsV1.users(_usersList[i]).rewardDebt;
        }
    }

    /* Claim rewards for both V1 and V2 users */

    function claimReward() external returns (uint256) {
        require(
            block.number >= pool.startRewardBlock,
            "VeWTF Staking: Staking has not started yet"
        );

        // Check if user has locks either in v1 or v2

        uint256 lockedV1 = vewtfV1.getLockedAmount(msg.sender);
        User storage userV2 = users[msg.sender];

        // If no locks either in V1 or V2 return 0
        if (lockedV1 == 0 && userV2.amount == 0) {
            return 0;
        }

        // Update pool here
        _updatePool();

        // First compute V1 reward

        // Current user amount in V1
        uint256 amountV1 = wtfRewardsV1.users(msg.sender).amount;

        // V1 user data as registered here in V2
        User storage userV1 = usersV1[msg.sender];

        /*
          The amount based on which we pay to V1 users is fixed after migration. This is to protect against the following
          manipulation: user unlocks in V1 and locks smaller amount in V1 again but gets rewarded for the bigger amount 
          registered here. Thus, if the user unlocked and locked smaller amount we don't pay reward. 
          If he increased the locked amount by mistake in V1 we use the same amount as when registered here.
          If user amount in V1 is zero then the reward for V1 is zero. The reward calculation below accounts for that.
        */

        // First, make sure that the user did not unlock and then lock again directly via V1 with a smaller amount

        if (amountV1 < userV1.amount) {
            return 0;
        }

        uint256 rewardV1;

        // Calculate any debt
        if (userV1.amount > 0) {
            rewardV1 = pool
                .accRewardPerShare
                .mul(userV1.amount)
                .div(PRECISION)
                .sub(userV1.rewardDebt);
            if (rewardV1 > 0) {
                wtf.safeTransfer(msg.sender, rewardV1);
            }
        }

        // Update userV1 reward debt
        userV1.rewardDebt = pool.accRewardPerShare.mul(userV1.amount).div(
            PRECISION
        );

        // Calculate and send V2 reward

        uint256 rewardV2;
        if (userV2.amount > 0) {
            rewardV2 = pool
                .accRewardPerShare
                .mul(userV2.amount)
                .div(PRECISION)
                .sub(userV2.rewardDebt);
            if (rewardV2 > 0) {
                wtf.safeTransfer(msg.sender, rewardV2);
            }
        }

        // Update userV2 reward debt
        userV2.rewardDebt = pool.accRewardPerShare.mul(userV2.amount).div(
            PRECISION
        );

        emit Claim(msg.sender, rewardV1, rewardV2);
    }

    function _updatePool() internal {
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        // Total staked accounts for staked amount in V1 and V2

        uint256 totalStaked = wtfRewardsV1.totalStaked() + pool.totalStaked;

        if (totalStaked == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getBlockDiff(pool.lastRewardBlock, block.number);

        uint256 accReward = multiplier.mul(pool.rewardPerBlock);

        // Update accRewardPerShare using totalStaked data

        pool.accRewardPerShare = pool.accRewardPerShare.add(
            accReward.mul(PRECISION).div(totalStaked)
        );
        pool.lastRewardBlock = block.number;

        emit UpdatePool(multiplier, totalStaked);
    }

    function pendingReward(address _user) public view returns (uint256 reward) {
        reward = pendingRewardV1(_user) + pendingRewardV2(_user);
    }

    function pendingRewardV1(address _user)
        public
        view
        returns (uint256 reward)
    {
        // Ensure that the user has locked amount in VeWTF V1
        uint256 locked = vewtfV1.getLockedAmount(_user);
        if (locked == 0) {
            return 0;
        }
        User memory user = usersV1[_user];

        // Ensure that the user did not unlock and then lock again
        // this can be shown if the user amount in V1 is less than user amount here in V2

        uint256 userV1Amount = wtfRewardsV1.getAccountData(_user).amount;

        if (userV1Amount == 0 || userV1Amount < user.amount) {
            return 0;
        }

        uint256 totalStaked = wtfRewardsV1.totalStaked() + pool.totalStaked;

        if (block.number > pool.lastRewardBlock && totalStaked != 0) {
            uint256 blockDiff = getBlockDiff(
                pool.lastRewardBlock,
                block.number
            );
            uint256 accReward = blockDiff.mul(pool.rewardPerBlock);

            uint256 adjustedTokenPerShare = pool.accRewardPerShare.add(
                accReward.mul(PRECISION).div(totalStaked)
            );
            reward = user.amount.mul(adjustedTokenPerShare).div(PRECISION).sub(
                user.rewardDebt
            );
        } else {
            reward = user.amount.mul(pool.accRewardPerShare).div(PRECISION).sub(
                    user.rewardDebt
                );
        }
    }

    function pendingRewardV2(address _user)
        public
        view
        returns (uint256 reward)
    {
        User memory user = users[_user];
        uint256 totalStaked = wtfRewardsV1.totalStaked() + pool.totalStaked;

        if (block.number > pool.lastRewardBlock && totalStaked != 0) {
            uint256 blockDiff = getBlockDiff(
                pool.lastRewardBlock,
                block.number
            );
            uint256 accReward = blockDiff.mul(pool.rewardPerBlock);
            uint256 adjustedTokenPerShare = pool.accRewardPerShare.add(
                accReward.mul(PRECISION).div(totalStaked)
            );
            reward = user.amount.mul(adjustedTokenPerShare).div(PRECISION).sub(
                user.rewardDebt
            );
        } else {
            reward = user.amount.mul(pool.accRewardPerShare).div(PRECISION).sub(
                    user.rewardDebt
                );
        }
    }

    function getBlockDiff(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        require(
            _from >= pool.startRewardBlock,
            "VeWTF Staking: _from should be >= startRewardBlock"
        );

        if (_from >= pool.endRewardBlock) {
            return 0;
        } else if (_to >= pool.endRewardBlock) {
            return pool.endRewardBlock.sub(_from);
        } else {
            return _to.sub(_from);
        }
    }

    function updateStartAndEndBlocks(
        uint256 _startRewardBlock,
        uint256 _endRewardBlock
    ) external onlyOwner {
        require(
            _startRewardBlock < _endRewardBlock,
            "VeWTF Staking: New startBlock must be lower than new endBlock"
        );
        require(
            block.number < _startRewardBlock,
            "VeWTF Staking: New startBlock must be higher than current block"
        );

        pool.startRewardBlock = _startRewardBlock;
        pool.endRewardBlock = _endRewardBlock;

        // Set the lastRewardBlock as the startBlock
        pool.lastRewardBlock = _startRewardBlock;

        emit NewStartAndEndBlocks(_startRewardBlock, _endRewardBlock);
    }

    function updaterewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        _updatePool();
        pool.rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        pool.endRewardBlock = block.number;
    }

    function evacuateETH(address recv) public onlyOwner {
        payable(recv).transfer(address(this).balance);
    }

    /*
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */

    function recoverWrongTokens(
        address to,
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyOwner {
        require(
            _tokenAddress != address(vewtf),
            "VeWTF Staking: Cannot be staked token"
        );
        require(
            _tokenAddress != address(wtf),
            "VeWTF Staking: Cannot be reward token"
        );

        IERC20Upgradeable(_tokenAddress).safeTransfer(to, _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
}