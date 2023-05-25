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
        uint256 depositDate;
        uint64 pool;
        address owner;
    }

    IERC721 public nftCollection;
    IERC20 public rewardToken;

    // poolDeposit per tokenId
    mapping(uint256 => PoolDeposit) private _deposits;
    // user rewards mapping
    mapping(address => uint256) private _userRewards;

    event Stake(address indexed account, uint256 poolId, uint256 tokenId);
    event Unstake(address indexed account, uint256 tokenId);

    event BatchStake(address indexed account, uint256 poolId, uint256[] tokenIds);
    event BatchUnstake(address indexed account, uint256[] tokenIds);

    constructor(IERC721 _nftCollection, IERC20 _rewardToken) {
        nftCollection = _nftCollection;
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

    function _stake(address account, uint256 poolId, uint256 tokenId) internal {
        require(_deposits[tokenId].owner == address(0), "Stake: Token already staked");

        // add deposit
        _deposits[tokenId] = PoolDeposit({depositDate: block.timestamp, pool: uint64(poolId), owner: account});
        // _userTokens[account].add(tokenId);

        // transfer token
        nftCollection.safeTransferFrom(account, address(this), tokenId);
    }

    /**
     * @notice Stake a token from the collection
     */
    function stake(uint256 poolId, uint256 tokenId) external nonReentrant whenPoolOpened(poolId) {
        address account = _msgSender();
        _stake(account, poolId, tokenId);
        emit Stake(account, poolId, tokenId);
    }

    function _unstake(address account, uint256 tokenId) internal returns (uint256) {
        uint256 poolId = _deposits[tokenId].pool;
        require(isUnlockable(poolId, _deposits[tokenId].depositDate), "Stake: Not yet unstakable");
        bool unlocked = isUnlocked(poolId, _deposits[tokenId].depositDate);

        // transfer token
        nftCollection.safeTransferFrom(address(this), account, tokenId);

        // update deposit
        delete _deposits[tokenId];

        uint256 rewards = 0;
        if (unlocked) {
            Pool memory pool = getPool(poolId);
            rewards = pool.rewardAmount;
        }

        return rewards;
    }

    /**
     * @notice Unstake a token
     */
    function unstake(uint256 tokenId) external nonReentrant {
        require(_deposits[tokenId].owner == _msgSender(), "Stake: Not owner of token");

        address account = _msgSender();
        uint256 rewards = _unstake(account, tokenId);
        _sendAndUpdateRewards(account, rewards);

        emit Unstake(account, tokenId);
    }

    function _restake(uint256 newPoolId, uint256 tokenId) internal returns (uint256) {
        require(isPoolOpened(newPoolId), "Stake: Pool is closed");

        uint256 oldPoolId = _deposits[tokenId].pool;
        require(isUnlockable(oldPoolId, _deposits[tokenId].depositDate), "Stake: Not yet unstakable");
        bool unlocked = isUnlocked(oldPoolId, _deposits[tokenId].depositDate);

        // update deposit
        _deposits[tokenId].pool = uint64(newPoolId);
        _deposits[tokenId].depositDate = block.timestamp;

        uint256 rewards = 0;
        if (unlocked) {
            Pool memory pool = getPool(oldPoolId);
            rewards = pool.rewardAmount;
        }

        return rewards;
    }

    /**
     * @notice Allow a user to [re]stake a token in a new pool without unstaking it first.
     */
    function restake(uint256 newPoolId, uint256 tokenId) external nonReentrant {
        require(_deposits[tokenId].owner != address(0), "Stake: Token not staked");
        require(_deposits[tokenId].owner == _msgSender(), "Stake: Not owner of token");

        address account = _msgSender();
        uint256 rewards = _restake(newPoolId, tokenId);
        _sendAndUpdateRewards(account, rewards);

        emit Unstake(account, tokenId);
        emit Stake(account, newPoolId, tokenId);
    }

    /**
     * @notice Batch stake a list of tokens from the collection
     */
    function batchStake(uint256 poolId, uint256[] calldata tokenIds) external whenPoolOpened(poolId) nonReentrant {
        address account = _msgSender();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(account, poolId, tokenIds[i]);
        }

        emit BatchStake(account, poolId, tokenIds);
    }

    /**
     * @notice Batch unstake tokens
     */
    function batchUnstake(uint256[] calldata tokenIds) external nonReentrant {
        address account = _msgSender();

        uint256 rewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_deposits[tokenIds[i]].owner == account, "Stake: Not owner of token");
            rewards = rewards + _unstake(account, tokenIds[i]);
        }
        _sendAndUpdateRewards(account, rewards);

        emit BatchUnstake(account, tokenIds);
    }

    /**
     * @notice Batch restake tokens
     */
    function batchRestake(uint256 poolId, uint256[] calldata tokenIds) external nonReentrant {
        address account = _msgSender();

        uint256 rewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_deposits[tokenIds[i]].owner == account, "Stake: Not owner of token");
            rewards = rewards + _restake(poolId, tokenIds[i]);
        }
        _sendAndUpdateRewards(account, rewards);

        emit BatchUnstake(account, tokenIds);
        emit BatchStake(account, poolId, tokenIds);
    }

    /**
     * @notice Checks if a token has been deposited for enough time to get rewards
     */
    function isTokenUnlocked(uint256 tokenId) public view returns (bool) {
        require(_deposits[tokenId].owner != address(0), "Stake: Token not staked");
        return isUnlocked(_deposits[tokenId].pool, _deposits[tokenId].depositDate);
    }

    /**
     * @notice Get the stake detail for a token (owner, poolId, min unstakable date, reward unlock date)
     */
    function getStakeInfo(uint256 tokenId)
        external
        view
        returns (
            address, // owner
            uint256, // poolId
            uint256, // deposit date
            uint256, // unlock date
            uint256  // reward date
        )
    {
        require(_deposits[tokenId].owner != address(0), "Stake: Token not staked");
        PoolDeposit memory deposit = _deposits[tokenId];
        Pool memory pool = getPool(deposit.pool);
        return (deposit.owner, deposit.pool, deposit.depositDate, deposit.depositDate + pool.minDuration, deposit.depositDate + pool.lockDuration);
    }

    /**
     * @notice Returns the total reward for a user
     */
    function getUserTotalRewards(address account) external view returns (uint256) {
        return _userRewards[account];
    }

    function recoverNonFungibleToken(address _token, uint256 _tokenId) external override onlyOwner {
        // staked collection cannot be recovered by admin
        require(_token != address(nftCollection), "Stake: Cannot recover staked collection");
        IERC721(_token).transferFrom(address(this), address(msg.sender), _tokenId);
        emit NonFungibleTokenRecovery(_token, _tokenId);
    }
}