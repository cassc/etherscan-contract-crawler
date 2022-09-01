// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {RewardMath} from "../utils/RewardMath.sol";
import {INonfungiblePositionManager} from "../interfaces/INonfungiblePositionManager.sol";
import {IGaugeV2UniV3} from "../interfaces/IGaugeV2UniV3.sol";
import {IRegistry} from "../interfaces/IRegistry.sol";
import {NFTPositionInfo} from "../utils/NFTPositionInfo.sol";
import {Multicall} from "../utils/Multicall.sol";
import {TransferHelperExtended} from "../utils/TransferHelperExtended.sol";
import {PoolAddress} from "../utils/PoolAddress.sol";
import {IUniswapV3Staker} from "../interfaces/IUniswapV3Staker.sol";
import {INFTStaker} from "../interfaces/INFTStaker.sol";

/// @title Uniswap V3 canonical staking interface
contract BaseGaugeV2UniV3 is
    IGaugeV2UniV3,
    IUniswapV3Staker,
    Multicall,
    ReentrancyGuard
{
    IRegistry public immutable override registry;
    IUniswapV3Pool public immutable pool;

    uint256 public totalRewardUnclaimed;
    uint160 public totalSecondsClaimedX128;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public constant DURATION = 2 hours; // rewards are released over 7 days

    /// @notice Represents the deposit of a liquidity NFT
    struct Deposit {
        address owner;
        int24 tickLower;
        int24 tickUpper;
    }

    /// @notice Represents a staked liquidity NFT
    struct Stake {
        uint160 secondsPerLiquidityInsideInitialX128;
        uint96 liquidityNoOverflow;
        uint128 liquidityIfOverflow;
        uint128 nonDerivedLiquidity;
    }

    /// @inheritdoc IUniswapV3Staker
    IUniswapV3Factory public override factory;

    /// @inheritdoc IUniswapV3Staker
    INonfungiblePositionManager public override nonfungiblePositionManager;

    /// @dev deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public override deposits;

    /// @dev stakes[tokenId] => Stake
    mapping(uint256 => Stake) private _stakes;

    uint256 public totalLiquiditySupply;

    /// @dev rewards[owner] => uint256
    /// @inheritdoc IUniswapV3Staker
    mapping(address => uint256) public override rewards;

    mapping(address => uint256) public override balanceOf;

    /// @dev Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    /// @dev Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    /// @dev Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    /// @dev Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /// @param _nonfungiblePositionManager the NFT position manager contract address
    constructor(
        address token0,
        address token1,
        uint24 fee,
        address _registry,
        INonfungiblePositionManager _nonfungiblePositionManager
    ) {
        registry = IRegistry(_registry);
        nonfungiblePositionManager = _nonfungiblePositionManager;

        factory = IUniswapV3Factory(nonfungiblePositionManager.factory());
        address _pool = factory.getPool(token0, token1, fee);
        require(_pool != address(0), "pool doesn't exist");

        pool = IUniswapV3Pool(_pool);

        startTime = block.timestamp;
    }

    /// @inheritdoc IUniswapV3Staker
    function stakes(uint256 tokenId)
        public
        view
        override
        returns (
            uint160 secondsPerLiquidityInsideInitialX128,
            uint128 liquidity
        )
    {
        Stake storage stake = _stakes[tokenId];
        secondsPerLiquidityInsideInitialX128 = stake
            .secondsPerLiquidityInsideInitialX128;
        liquidity = stake.liquidityNoOverflow;
        if (liquidity == type(uint96).max)
            liquidity = stake.liquidityIfOverflow;
    }

    /// @notice Upon receiving a Uniswap V3 ERC721, creates the token deposit setting owner to `from`. Also stakes token
    /// in one or more incentives if properly formatted `data` has a length > 0.
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(
            msg.sender == address(nonfungiblePositionManager),
            "UniswapV3Staker::onERC721Received: not a univ3 nft"
        );

        (
            IUniswapV3Pool _pool,
            int24 tickLower,
            int24 tickUpper,
            uint128 _liquidity
        ) = NFTPositionInfo.getPositionInfo(
                factory,
                nonfungiblePositionManager,
                tokenId
            );

        deposits[tokenId] = Deposit({
            owner: from,
            tickLower: tickLower,
            tickUpper: tickUpper
        });

        require(
            _pool == pool,
            "UniswapV3Staker::stakeToken: token pool is not the right pool"
        );
        require(
            _liquidity > 0,
            "UniswapV3Staker::stakeToken: cannot stake token with 0 liquidity"
        );

        totalLiquiditySupply += uint256(_liquidity);
        uint128 liquidity = uint128(derivedLiquidity(_liquidity, from));

        (, uint160 secondsPerLiquidityInsideX128, ) = _pool
            .snapshotCumulativesInside(tickLower, tickUpper);

        if (liquidity >= type(uint96).max) {
            _stakes[tokenId] = Stake({
                secondsPerLiquidityInsideInitialX128: secondsPerLiquidityInsideX128,
                liquidityNoOverflow: type(uint96).max,
                liquidityIfOverflow: liquidity,
                nonDerivedLiquidity: _liquidity
            });
        } else {
            _stakes[tokenId] = Stake({
                secondsPerLiquidityInsideInitialX128: secondsPerLiquidityInsideX128,
                liquidityNoOverflow: uint96(liquidity),
                liquidityIfOverflow: 0,
                nonDerivedLiquidity: _liquidity
            });
        }

        _addTokenToAllTokensEnumeration(tokenId);
        _addTokenToOwnerEnumeration(from, tokenId);
        balanceOf[from] += 1;

        emit TokenStaked(tokenId, _liquidity);
        return this.onERC721Received.selector;
    }

    /// @inheritdoc IUniswapV3Staker
    function withdrawToken(uint256 tokenId) external override {
        // try to update rewards
        _updateReward(tokenId);

        totalLiquiditySupply -= uint256(_stakes[tokenId].nonDerivedLiquidity);

        require(
            deposits[tokenId].owner == msg.sender,
            "UniswapV3Staker::withdrawToken: only owner can withdraw token"
        );

        delete deposits[tokenId];
        delete _stakes[tokenId];

        _removeTokenFromOwnerEnumeration(msg.sender, tokenId);
        _removeTokenFromAllTokensEnumeration(tokenId);
        balanceOf[msg.sender] -= 1;

        emit TokenUnstaked(tokenId);

        nonfungiblePositionManager.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    function _updateReward(uint256 tokenId) internal {
        Deposit memory deposit = deposits[tokenId];

        (
            uint160 secondsPerLiquidityInsideInitialX128,
            uint128 liquidity
        ) = stakes(tokenId);

        require(
            liquidity != 0,
            "UniswapV3Staker::unstakeToken: stake does not exist"
        );

        (, uint160 secondsPerLiquidityInsideX128, ) = pool
            .snapshotCumulativesInside(deposit.tickLower, deposit.tickUpper);

        (uint256 reward, uint160 secondsInsideX128) = RewardMath
            .computeRewardAmount(
                totalRewardUnclaimed,
                totalSecondsClaimedX128,
                startTime,
                endTime,
                liquidity,
                secondsPerLiquidityInsideInitialX128,
                secondsPerLiquidityInsideX128,
                block.timestamp
            );

        // if this overflows, e.g. after 2^32-1 full liquidity seconds have been claimed,
        // reward rate will fall drastically so it's safe
        totalSecondsClaimedX128 += secondsInsideX128;
        // reward is never greater than total reward unclaimed
        totalRewardUnclaimed -= reward;
        // this only overflows if a token has a total supply greater than type(uint256).max
        rewards[deposit.owner] += reward;
    }

    function _claimReward(uint256 tokenId, address to)
        internal
        returns (uint256)
    {
        _updateReward(tokenId);
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] -= reward;
        TransferHelperExtended.safeTransfer(registry.maha(), to, reward);
        emit RewardClaimed(to, reward);
        return reward;
    }

    /// @inheritdoc IUniswapV3Staker
    function claimRewards(uint256[] memory tokenIds, address to)
        external
        override
        returns (uint256)
    {
        uint256 reward;
        for (uint256 index = 0; index < tokenIds.length; index++) {
            reward += _claimReward(tokenIds[index], to);
        }
        return reward;
    }

    function claimReward(uint256 tokenId, address to)
        external
        override
        returns (uint256)
    {
        return _claimReward(tokenId, to);
    }

    function derivedLiquidity(uint256 liquidity, address account)
        public
        view
        returns (uint256)
    {
        uint256 _derived = (liquidity * 20) / 100;
        uint256 _adjusted = 0;
        uint256 _supply = IERC20(registry.locker()).totalSupply();

        if (_supply > 0) {
            _adjusted = INFTStaker(registry.staker()).balanceOf(account);
            _adjusted =
                (((totalLiquiditySupply * _adjusted) / _supply) * 80) /
                100;
        }

        // because of this we are able to max out the boost by 5x
        return Math.min((_derived + _adjusted), liquidity);
    }

    function boostedFactor(uint256 tokenId, address who)
        public
        view
        returns (
            uint256 original,
            uint256 boosted,
            uint256 factor
        )
    {
        (, , , uint128 _liquidity) = NFTPositionInfo.getPositionInfo(
            factory,
            nonfungiblePositionManager,
            tokenId
        );

        original = (_liquidity * 20) / 100;
        boosted = derivedLiquidity(_liquidity, who);
        factor = (original * 1e18) / boosted;
    }

    function left(address token) external view override returns (uint256) {
        return totalRewardUnclaimed;
    }

    /// @inheritdoc IUniswapV3Staker
    function isIdsWithinRange(uint256[] memory tokenIds)
        external
        view
        override
        returns (bool[] memory)
    {
        bool[] memory ret = new bool[](tokenIds.length);

        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];
            (
                IUniswapV3Pool _pool,
                int24 tickLower,
                int24 tickUpper,

            ) = NFTPositionInfo.getPositionInfo(
                    factory,
                    nonfungiblePositionManager,
                    tokenId
                );

            (, int24 tick, , , , , ) = _pool.slot0();
            ret[index] = tickLower < tick && tick < tickUpper;
        }

        return ret;
    }

    function incentives() external view override returns (uint256, uint160) {
        return (totalRewardUnclaimed, totalSecondsClaimedX128);
    }

    function notifyRewardAmount(address token, uint256 amount)
        external
        override
        nonReentrant
    {
        require(
            token == registry.maha(),
            "UniswapV3Staker::createIncentive: only maha allowed"
        );
        require(
            amount > 0,
            "UniswapV3Staker::createIncentive: reward must be positive"
        );

        totalRewardUnclaimed += amount;
        endTime = block.timestamp + DURATION;

        TransferHelperExtended.safeTransferFrom(
            registry.maha(),
            msg.sender,
            address(this),
            amount
        );

        emit IncentiveCreated(pool, startTime, endTime, amount);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < balanceOf[owner],
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf[to];
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
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
        private
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
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
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
}