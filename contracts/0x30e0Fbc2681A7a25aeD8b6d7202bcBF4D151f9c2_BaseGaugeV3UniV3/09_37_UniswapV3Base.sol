// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IRegistry} from "../../interfaces/IRegistry.sol";
import {INonfungiblePositionManager} from "../../interfaces/INonfungiblePositionManager.sol";
import {IGauge} from "../../interfaces/IGauge.sol";

abstract contract UniswapV3Base is Initializable, ReentrancyGuard, IGauge {
    using SafeMath for uint256;
    using SafeMath for uint128;

    /// @notice Represents the deposit of a liquidity NFT
    struct Deposit {
        address owner;
        uint128 liquidity;
        uint128 derivedLiquidity;
    }

    /* ========== STATE VARIABLES ========== */
    IRegistry public override registry;
    IERC20 public rewardsToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 7 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public maxBoostRequirement = 5000e18;
    mapping(uint256 => uint256) public userRewardPerTokenPaid;

    uint256 public totalSupply;

    /// @dev all the NFT deposits
    mapping(uint256 => Deposit) public deposits;

    /// @dev [nft token id => reward count] rewards
    mapping(uint256 => uint256) public rewards;

    /// @dev the uniswap v3 factory
    IUniswapV3Factory public factory;

    /// @dev the uniswap v3 nft position manager
    INonfungiblePositionManager public nonfungiblePositionManager;

    /// @dev the pool for which we are staking the rewards
    IUniswapV3Pool public pool;

    /// @dev the number of NFTs staked by the given user.
    mapping(address => uint256) public balanceOf;

    /// @dev Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) internal _ownedTokens;

    /// @dev Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal _ownedTokensIndex;

    /// @dev Array with all token ids, used for enumeration
    uint256[] internal _allTokens;

    /// @dev Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal _allTokensIndex;

    /// @dev is the user attached to this gauge
    mapping(address => bool) public attached;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _registry,
        address token0,
        address token1,
        uint24 fee,
        address _rewardsToken,
        address _nonfungiblePositionManager
    ) public initializer {
        nonfungiblePositionManager = INonfungiblePositionManager(
            _nonfungiblePositionManager
        );

        registry = IRegistry(_registry);
        factory = IUniswapV3Factory(nonfungiblePositionManager.factory());
        rewardsToken = IERC20(_rewardsToken);

        address _pool = factory.getPool(token0, token1, fee);
        require(_pool != address(0), "pool doesn't exist");
        pool = IUniswapV3Pool(_pool);
    }

    /* ========== VIEWS ========== */

    function left(address) external view override returns (uint256) {
        if (block.timestamp >= periodFinish) return 0;
        uint256 _remaining = periodFinish - block.timestamp;
        return _remaining * rewardRate;
    }

    function liquidity(uint256 _tokenId) external view returns (uint256) {
        return deposits[_tokenId].liquidity;
    }

    function derivedLiquidity(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return deposits[_tokenId].derivedLiquidity;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) return rewardPerTokenStored;
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply)
            );
    }

    function earned(uint256 _tokenId) public view returns (uint256) {
        return
            deposits[_tokenId]
                .derivedLiquidity
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[_tokenId]))
                .div(1e18)
                .add(rewards[_tokenId]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) internal {
        uint256 length = balanceOf[to];
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) internal {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        internal
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf[from];
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) internal {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(deposits[_tokenId].owner == msg.sender, "only tokenid owner");
        _;
    }
    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(
        address indexed user,
        uint256 tokenId,
        uint128 liquidty,
        uint128 derivedLiquidity
    );
    event Withdrawn(address indexed user, uint256 tokenId);
    event RewardPaid(address indexed user, uint256 tokenId, uint256 reward);
    event MaxBoostRequirementChanged(uint256 _old, uint256 _new);
    event EmergencyModeEnabled();
}