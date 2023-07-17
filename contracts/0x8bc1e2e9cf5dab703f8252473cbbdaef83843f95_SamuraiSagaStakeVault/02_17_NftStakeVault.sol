// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/Poolable.sol";
import "./libraries/Recoverable.sol";

/** @title NftStakeVault
 */
contract NftStakeVault is Ownable, Poolable, Recoverable, ReentrancyGuard, ERC721Holder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct PoolDeposit {
        uint256 depositDate;
        uint256 pool;
        address owner;
    }

    IERC721 public nftCollection;
    IERC20 public rewardToken;

    // poolDeposit per tokenId
    mapping(uint256 => PoolDeposit) _deposits;
    // owner to tokenId mapping
    mapping(address => uint256[]) _userTokens;
    // user rewards mapping
    mapping(address => uint256) _userRewards;

    event Stake(address indexed account, uint256 poolId, uint256 tokenId);
    event Unstake(address indexed account, uint256 poolId, uint256 tokenId);

    constructor(IERC721 _nftCollection, IERC20 _rewardToken) {
        nftCollection = _nftCollection;
        rewardToken = _rewardToken;
    }

    function _popToken(address account, uint256 tokenId) private {
        uint256 delta = 0;
        uint256 token;
        for (uint256 i = 0; i < _userTokens[account].length; i++) {
            token = _userTokens[account][i];
            if (token == tokenId) {
                delta = delta + 1;
            }
            else {
                _userTokens[account][i - delta] = token;
            }
        }
        for (uint256 i = 0; i < delta; i++) {
            _userTokens[account].pop();
        }
    }

    function _sendRewards(address destination, uint256 amount) internal virtual {
        rewardToken.safeTransfer(destination, amount);
    }

    /**
     * @notice Stake a token from the collection
     */
    function stake(uint256 poolId, uint256 tokenId) external whenPoolOpened(poolId) nonReentrant {
        // transfer token
        nftCollection.safeTransferFrom(_msgSender(), address(this), tokenId);

        // add deposit
        address account = _msgSender();
        _deposits[tokenId] = PoolDeposit({depositDate: block.timestamp, pool: poolId, owner: account});
        _userTokens[account].push(tokenId);

        emit Stake(account, poolId, tokenId);
    }

    /**
     * @notice Unstake a token
     */
    function unstake(uint256 tokenId) external nonReentrant {
        address account = _msgSender();
        require(_deposits[tokenId].owner == account, "Stake: Not owner of token");

        uint256 poolId = _deposits[tokenId].pool;
        require(isUnlockable(poolId, _deposits[tokenId].depositDate), "Stake: Not yet unstakable");
        bool unlocked = isUnlocked(poolId, _deposits[tokenId].depositDate);

        // transfer token
        nftCollection.safeTransferFrom(address(this), account, tokenId);

        // update deposit
        _popToken(account, tokenId);
        delete _deposits[tokenId];

        // transfer reward if unlocked
        if (unlocked) {
            Pool memory pool = getPool(poolId);
            _sendRewards(account, pool.rewardAmount);
            _userRewards[account] = _userRewards[account].add(pool.rewardAmount);
        }

        emit Unstake(account, poolId, tokenId);
    }

    /**
     * @notice Allow a user to [re]stake a token in a new pool without unstaking it first.
     */
    function restake(uint256 newPoolId, uint256 tokenId) external nonReentrant {
        address account = _msgSender();
        require(_deposits[tokenId].owner == account, "Stake: Not owner of token");
        require(isPoolOpened(newPoolId), "Stake: Pool is closed");

        uint256 oldPoolId = _deposits[tokenId].pool;
        require(isUnlockable(oldPoolId, _deposits[tokenId].depositDate), "Stake: Not yet unstakable");
        bool unlocked = isUnlocked(oldPoolId, _deposits[tokenId].depositDate);

        // update deposit
        _deposits[tokenId].pool = newPoolId;
        _deposits[tokenId].depositDate = block.timestamp;

        // transfer reward if unlocked
        if (unlocked) {
            Pool memory pool = getPool(oldPoolId);
            _sendRewards(account, pool.rewardAmount);
            _userRewards[account] = _userRewards[account].add(pool.rewardAmount);
        }

        emit Unstake(account, oldPoolId, tokenId);
        emit Stake(account, newPoolId, tokenId);
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
            address,
            uint256,
            uint256,
            uint256
        )
    {
        require(_deposits[tokenId].owner != address(0), "Stake: Token not staked");
        PoolDeposit memory deposit = _deposits[tokenId];
        Pool memory pool = getPool(deposit.pool);
        return (deposit.owner, deposit.pool, deposit.depositDate + pool.minDuration, deposit.depositDate + pool.lockDuration);
    }

    /**
     * @notice Get the number of tokens staked by a user
     */
    function getUserStakedTokensCount(address account) external view returns (uint256) {
        return _userTokens[account].length;
    }

    /**
     * @notice Get the list of tokens staked by a user
     */
    function getUserStakedTokens(
        address account,
        uint256 size,
        uint256 cursor
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > _userTokens[account].length - cursor) {
            length = _userTokens[account].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = _userTokens[account][cursor + i];
        }

        return (values, cursor + length);
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