// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Poolable.sol";
import "./Recoverable.sol";

/** @title NftStakingPool
 */
contract NftStakingPool is Ownable, Poolable, Recoverable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;

    struct PoolDeposit {
        address owner;
        uint64 pool;
        uint256 depositDate;
        uint256 claimed;
    }

    struct MultiStakeParam {
        uint256[] tokenIds;
        uint256 poolId;
    }

    IERC20 public rewardToken;

    // poolDeposit per collection and tokenId
    mapping(address => mapping(uint256 => PoolDeposit)) private _deposits;
    // user rewards mapping
    mapping(address => uint256) private _userRewards;

    event Stake(address indexed account, uint256 poolId, address indexed collection, uint256 tokenId);
    event Unstake(address indexed account, address indexed collection, uint256 tokenId);

    event BatchStake(address indexed account, uint256 poolId, address indexed collection, uint256[] tokenIds);
    event BatchUnstake(address indexed account, address indexed collection, uint256[] tokenIds);

    event Claimed(address indexed account, address indexed collection, uint256 tokenId, uint256 rewards, uint256 pool);
    event ClaimedMulti(address indexed account, MultiStakeParam[] groups, uint256 rewards);

    constructor(IERC20 _rewardToken) {
        rewardToken = _rewardToken;
    }

    function _sendRewards(address destination, uint256 amount) internal virtual {
        rewardToken.safeTransfer(destination, amount);
    }

    function _sendAndUpdateRewards(address account, uint256 amount) internal {
        if (amount > 0) {
            _userRewards[account] = _userRewards[account] + amount;
            _sendRewards(account, amount);
        }
    }

    function _getPendingRewardAmounts(PoolDeposit memory deposit, Pool memory pool) internal view returns (uint256) {
        uint256 reward = 0;
        uint256 dt = deposit.depositDate;

        while (dt != 0 && pool.lockDuration != 0) {
            dt += pool.lockDuration;
            if (dt > block.timestamp) break;
            reward += pool.rewardAmount;
            if (pool.endRewardDate != 0 && dt > pool.endRewardDate) break;
        }

        if (reward <= deposit.claimed) {
            return 0;
        }

        return reward - deposit.claimed;
    }

    function _stake(
        address account,
        address collection,
        uint256 tokenId,
        uint256 poolId
    ) internal {
        require(_deposits[collection][tokenId].owner == address(0), "Stake: Token already staked");

        // add deposit
        _deposits[collection][tokenId] = PoolDeposit({
            owner: account,
            pool: uint64(poolId),
            depositDate: block.timestamp,
            claimed: 0
        });

        // transfer token
        IERC721(collection).safeTransferFrom(account, address(this), tokenId);
    }

    /**
     * @notice Stake a token from the collection
     */
    function stake(uint256 poolId, uint256 tokenId) external nonReentrant whenPoolOpened(poolId) {
        address account = _msgSender();
        Pool memory pool = getPool(poolId);
        _stake(account, pool.collection, tokenId, poolId);
        emit Stake(account, poolId, pool.collection, tokenId);
    }

    function _unstake(
        address account,
        address collection,
        uint256 tokenId
    ) internal returns (uint256) {
        PoolDeposit storage deposit = _deposits[collection][tokenId];
        require(isUnlockable(deposit.pool, deposit.depositDate), "Stake: Not yet unstakable");

        Pool memory pool = getPool(deposit.pool);
        uint256 rewards = _getPendingRewardAmounts(deposit, pool);
        if (rewards > 0) {
            deposit.claimed += rewards;
        }

        // update deposit
        delete _deposits[collection][tokenId];

        // transfer token
        IERC721(collection).safeTransferFrom(address(this), account, tokenId);

        return rewards;
    }

    /**
     * @notice Unstake a token
     */
    function unstake(address collection, uint256 tokenId) external nonReentrant {
        require(_deposits[collection][tokenId].owner == _msgSender(), "Stake: Not owner of token");

        address account = _msgSender();
        uint256 rewards = _unstake(account, collection, tokenId);
        _sendAndUpdateRewards(account, rewards);

        emit Unstake(account, collection, tokenId);
    }

    function _restake(
        uint256 newPoolId,
        address collection,
        uint256 tokenId
    ) internal returns (uint256) {
        require(isPoolOpened(newPoolId), "Stake: Pool is closed");
        require(collectionForPool(newPoolId) == collection, "Stake: Invalid collection");

        PoolDeposit storage deposit = _deposits[collection][tokenId];
        Pool memory oldPool = getPool(deposit.pool);

        require(isUnlockable(deposit.pool, deposit.depositDate), "Stake: Not yet unstakable");
        uint256 rewards = _getPendingRewardAmounts(deposit, oldPool);

        // update deposit
        deposit.pool = uint64(newPoolId);
        deposit.depositDate = block.timestamp;
        deposit.claimed = 0;

        return rewards;
    }

    /**
     * @notice Allow a user to [re]stake a token in a new pool without unstaking it first.
     */
    function restake(
        uint256 newPoolId,
        address collection,
        uint256 tokenId
    ) external nonReentrant {
        require(_deposits[collection][tokenId].owner != address(0), "Stake: Token not staked");
        require(_deposits[collection][tokenId].owner == _msgSender(), "Stake: Not owner of token");

        address account = _msgSender();
        uint256 rewards = _restake(newPoolId, collection, tokenId);
        _sendAndUpdateRewards(account, rewards);

        emit Unstake(account, collection, tokenId);
        emit Stake(account, newPoolId, collection, tokenId);
    }

    function _batchStake(
        address account,
        uint256 poolId,
        uint256[] memory tokenIds
    ) internal whenPoolOpened(poolId) {
        Pool memory pool = getPool(poolId);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(account, pool.collection, tokenIds[i], poolId);
        }

        emit BatchStake(account, poolId, pool.collection, tokenIds);
    }

    function _batchUnstake(
        address account,
        address collection,
        uint256[] memory tokenIds
    ) internal {
        uint256 rewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_deposits[collection][tokenIds[i]].owner == account, "Stake: Not owner of token");
            rewards = rewards + _unstake(account, collection, tokenIds[i]);
        }
        _sendAndUpdateRewards(account, rewards);

        emit BatchUnstake(account, collection, tokenIds);
    }

    function _batchRestake(
        address account,
        uint256 poolId,
        address collection,
        uint256[] memory tokenIds
    ) internal {
        uint256 rewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_deposits[collection][tokenIds[i]].owner == account, "Stake: Not owner of token");
            rewards += _restake(poolId, collection, tokenIds[i]);
        }
        _sendAndUpdateRewards(account, rewards);

        emit BatchUnstake(account, collection, tokenIds);
        emit BatchStake(account, poolId, collection, tokenIds);
    }

    /**
     * @notice Batch stake a list of tokens from the collection
     */
    function batchStake(uint256 poolId, uint256[] calldata tokenIds) external nonReentrant {
        _batchStake(_msgSender(), poolId, tokenIds);
    }

    /**
     * @notice Batch unstake tokens
     */
    function batchUnstake(address collection, uint256[] calldata tokenIds) external nonReentrant {
        _batchUnstake(_msgSender(), collection, tokenIds);
    }

    /**
     * @notice Batch restake tokens
     */
    function batchRestake(
        uint256 poolId,
        address collection,
        uint256[] calldata tokenIds
    ) external nonReentrant {
        _batchRestake(_msgSender(), poolId, collection, tokenIds);
    }

    /**
     * @notice Batch stake a list of tokens from different collections
     */
    function stakeMulti(MultiStakeParam[] memory groups) external nonReentrant {
        address account = _msgSender();

        for (uint256 i = 0; i < groups.length; i++) {
            _batchStake(account, groups[i].poolId, groups[i].tokenIds);
        }
    }

    /**
     * @notice Batch unstake tokens from different collections
     */
    function unstakeMulti(MultiStakeParam[] memory groups) external nonReentrant {
        address account = _msgSender();

        for (uint256 i = 0; i < groups.length; i++) {
            address collection = getPool(groups[i].poolId).collection;
            _batchUnstake(account, collection, groups[i].tokenIds);
        }
    }

    /**
     * @notice Batch restake tokens from different collections
     */
    function restakeMulti(MultiStakeParam[] memory groups) external nonReentrant {
        address account = _msgSender();

        for (uint256 i = 0; i < groups.length; i++) {
            address collection = getPool(groups[i].poolId).collection;
            _batchRestake(account, groups[i].poolId, collection, groups[i].tokenIds);
        }
    }

    function claim(address collection, uint256 tokenId) external {
        address account = _msgSender();
        PoolDeposit storage deposit = _deposits[collection][tokenId];
        require(deposit.owner == account, "Stake: Not owner of token");
        require(isUnlockable(deposit.pool, deposit.depositDate), "Stake: Not yet unstakable");

        Pool memory pool = getPool(deposit.pool);
        uint256 rewards = _getPendingRewardAmounts(deposit, pool);
        if (rewards > 0) {
            deposit.claimed += rewards;
        }

        _sendAndUpdateRewards(account, rewards);
        emit Claimed(account, collection, tokenId, rewards, deposit.pool);
    }

    function claimMulti(MultiStakeParam[] memory groups) external {
        address account = _msgSender();
        uint256 rewards = 0;
        for (uint256 i = 0; i < groups.length; i++) {
            Pool memory pool = getPool(groups[i].poolId);

            for (uint256 u = 0; u < groups[i].tokenIds.length; u++) {
                PoolDeposit storage deposit = _deposits[pool.collection][groups[i].tokenIds[u]];
                require(deposit.owner == _msgSender(), "Stake: Not owner of token");
                require(isUnlockable(deposit.pool, deposit.depositDate), "Stake: Not yet unstakable");

                uint256 depositRewards = _getPendingRewardAmounts(deposit, pool);
                if (depositRewards > 0) {
                    deposit.claimed += depositRewards;
                    rewards += depositRewards;
                }
            }
        }

        _sendAndUpdateRewards(account, rewards);
        emit ClaimedMulti(account, groups, rewards);
    }

    /**
     * @notice Checks if a token has been deposited for enough time to get rewards
     */
    function isTokenUnlocked(address collection, uint256 tokenId) public view returns (bool) {
        require(_deposits[collection][tokenId].owner != address(0), "Stake: Token not staked");
        return isUnlocked(_deposits[collection][tokenId].pool, _deposits[collection][tokenId].depositDate);
    }

    /**
     * @notice Get the stake detail for a token (owner, poolId, min unstakable date, reward unlock date)
     */
    function getStakeInfo(address collection, uint256 tokenId)
        external
        view
        returns (
            address owner, // owner
            uint256 poolId, // poolId
            uint256 depositDate, // deposit date
            uint256 unlockDate, // unlock date
            uint256 rewardDate, // reward date
            uint256 totalClaimed // total claimed
        )
    {
        if (_deposits[collection][tokenId].owner == address(0)) {
            return (address(0), 0, 0, 0, 0, 0);
        }
        PoolDeposit memory deposit = _deposits[collection][tokenId];
        Pool memory pool = getPool(deposit.pool);
        return (
            deposit.owner,
            deposit.pool,
            deposit.depositDate,
            deposit.depositDate + pool.minDuration,
            deposit.depositDate + pool.lockDuration,
            deposit.claimed
        );
    }

    /**
     * @notice Returns the total reward for a user
     */
    function getUserTotalRewards(address account) external view returns (uint256) {
        return _userRewards[account];
    }

    function recoverNonFungibleToken(address _token, uint256 _tokenId) external override onlyOwner {
        // staked tokens cannot be recovered by owner
        require(_deposits[_token][_tokenId].owner == address(0), "Stake: Cannot recover staked token");
        IERC721(_token).transferFrom(address(this), address(msg.sender), _tokenId);
        emit NonFungibleTokenRecovery(_token, _tokenId);
    }
}