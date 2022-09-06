// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./INonfungiblePositionManager.sol";
import "./IMulticall.sol";

interface IUniswapV3Staker is IERC721Receiver, IMulticall {
    /// @notice The Uniswap V3 Factory
    function factory() external view returns (IUniswapV3Factory);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);

    /// @notice The nonfungible position manager with which this staking contract is compatible
    function nonfungiblePositionManager()
        external
        view
        returns (INonfungiblePositionManager);

    /// @notice Represents a staking incentive
    /// @return totalRewardUnclaimed The amount of reward token not yet claimed by users
    /// @return totalSecondsClaimedX128 Total liquidity-seconds claimed, represented as a UQ32.128
    function incentives()
        external
        view
        returns (uint256 totalRewardUnclaimed, uint160 totalSecondsClaimedX128);

    /// @notice Returns information about a deposited NFT
    /// @return owner The owner of the deposited NFT
    /// @return tickLower The lower tick of the range
    /// @return tickUpper The upper tick of the range
    function deposits(uint256 tokenId)
        external
        view
        returns (
            address owner,
            int24 tickLower,
            int24 tickUpper
        );

    /// @notice Returns information about a deposited NFT
    /// @param depositOwner The owner of the deposited NFT
    /// @return uint256 The current no of nfts deposited by owner.
    function balanceOf(address depositOwner) external view returns (uint256);

    /// @notice Returns information about a staked liquidity NFT
    /// @param tokenId The ID of the staked token
    /// @return secondsPerLiquidityInsideInitialX128 secondsPerLiquidity represented as a UQ32.128
    /// @return liquidity The amount of liquidity in the NFT as of the last time the rewards were computed
    function stakes(uint256 tokenId)
        external
        view
        returns (
            uint160 secondsPerLiquidityInsideInitialX128,
            uint128 liquidity
        );

    /// @notice Returns amounts of reward tokens owed to a given address according to the last time all stakes were updated
    /// @param owner The owner for which the rewards owed are checked
    /// @return rewardsOwed The amount of the reward token claimable by the owner
    function rewards(address owner) external view returns (uint256 rewardsOwed);

    /// @notice checks if the given LP token ids are within their given liquidaty range or not
    function isIdsWithinRange(uint256[] memory tokenIds)
        external
        view
        returns (bool[] memory);

    function left(address token) external view returns (uint256);

    /// @notice Creates a new liquidity mining incentive program
    /// @param reward The amount of reward tokens to be distributed
    function notifyRewardAmount(address token, uint256 reward) external;

    /// @notice Withdraws a Uniswap V3 LP token `tokenId` from this contract to the recipient `to`
    /// @param tokenId The ID of the token
    function withdrawToken(uint256 tokenId) external;

    /// @param to The address where claimed rewards will be sent to
    /// @param tokenId The ID of the token
    /// @return reward The amount of reward tokens claimed
    function claimReward(uint256 tokenId, address to)
        external
        returns (uint256 reward);

    /// @param to The address where claimed rewards will be sent to
    /// @param tokenIds The IDs of the token
    /// @return reward The amount of reward tokens claimed
    function claimRewards(uint256[] memory tokenIds, address to)
        external
        returns (uint256 reward);

    /// @notice Event emitted when a liquidity mining incentive has been created
    /// @param pool The Uniswap V3 pool
    /// @param startTime The time when the incentive program begins
    /// @param endTime The time when rewards stop accruing
    /// @param reward The amount of reward tokens to be distributed
    event IncentiveCreated(
        IUniswapV3Pool indexed pool,
        uint256 startTime,
        uint256 endTime,
        uint256 reward
    );

    /// @notice Event emitted when a Uniswap V3 LP token has been staked
    /// @param tokenId The unique identifier of an Uniswap V3 LP token
    /// @param liquidity The amount of liquidity staked
    event TokenStaked(uint256 indexed tokenId, uint128 liquidity);

    /// @notice Event emitted when a Uniswap V3 LP token has been unstaked
    /// @param tokenId The unique identifier of an Uniswap V3 LP token
    event TokenUnstaked(uint256 indexed tokenId);

    /// @notice Event emitted when a reward token has been claimed
    /// @param to The address where claimed rewards were sent to
    /// @param reward The amount of reward tokens claimed
    event RewardClaimed(address indexed to, uint256 reward);
}