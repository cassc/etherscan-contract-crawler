// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IPool} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPool.sol";

interface IPoolPositionSlim is IERC20Metadata {
    error InvalidBinIds(uint128[] binIds);
    error InvalidRatio();
    error BinIsMerged();
    error InvalidTokenId(uint256 tokenId);

    event MigrateBinLiquidity(uint128 oldBinId, uint128 newBinId);

    function allBinIds() external view returns (uint128[] memory);

    function binIds(uint256) external view returns (uint128);

    function ratios(uint256) external view returns (uint128);

    /// @notice tokenId that holds PP assets
    function tokenId() external view returns (uint256);

    /// @notice Pool that the position exists in
    function pool() external view returns (IPool);

    /// @notice Whether or not the PP contains all static bins as opposed to
    //movement bins
    function isStatic() external view returns (bool);

    /// @notice Returns struct array of bin lp amounts that need to be transfered for a mint
    /// @param  binZeroLpAddAmount LP amount of bin[0] to be added
    function binLpAddAmountRequirement(uint128 binZeroLpAddAmount) external view returns (IPool.RemoveLiquidityParams[] memory params);

    /// @notice Burns PoolPosition ERC20 tokens from given account and
    //trasnfers Pool liquidity position to toTokenId
    /// @param account wallet or contract whose PoolPosition tokens will be
    //burned
    /// @param toTokenId pool.position() that will own the output liquidity
    /// @param lpAmountToUnStake number of PoolPosition LPs tokens to burn
    function burnFromToTokenIdAsBinLiquidity(address account, uint256 toTokenId, uint256 lpAmountToUnStake) external returns (IPool.RemoveLiquidityParams[] memory params);

    /// @notice Burns PoolPosition ERC20 tokens and trasnfers resulting
    //liquidity as A/B tokens to recipient
    /// @param account wallet or contract whose PoolPosition tokens will be
    //burned
    /// @param recipient pool.position() that will own the output tokens
    /// @param lpAmountToUnStake number of PoolPosition LPs tokens to burn
    function burnFromToAddressAsReserves(address account, address recipient, uint256 lpAmountToUnStake) external returns (uint256 amountA, uint256 amountB);

    /// @notice Migrates the PoolPosition liquidity to active bin if the
    //liquidity is currently merged
    /// @dev Migrating only applies to one-bin dynamic-kind PoolPositions and
    //it must be called before any other external call will execute if the bin
    //in the PoolPosition has been merged.
    function migrateBinLiquidity() external;

    /// @notice Mint new PoolPosition tokens
    /// @param to wallet or contract where PoolPosition tokens will be minted
    /// @param fromTokenId pool.position() that will contribute input liquidity
    /// @param binZeroLpAddAmount LP balance of pool.position() in PoolPosition
    //bins[0] to be transfered
    //  @return liquidity number of PoolPosition LP tokens minted
    function mint(address to, uint256 fromTokenId, uint128 binZeroLpAddAmount) external returns (uint256 liquidity);

    /// @notice Amount of pool.tokenA() and pool.tokenB() tokens held by the
    //PoolPosition
    //  @return reserveA Amount of pool.tokenA() tokens held by the
    //  PoolPosition
    //  @return reserveB Amount of pool.tokenB() tokens held by the
    //  PoolPosition
    function getReserves() external view returns (uint256 reserveA, uint256 reserveB);
}