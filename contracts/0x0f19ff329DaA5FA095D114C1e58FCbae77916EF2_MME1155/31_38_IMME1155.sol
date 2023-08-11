// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IMME1155
 * @author Souq.Finance
 * @notice Defines the interface of the MME for ERC1155 pools with single collection.
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */

interface IMME1155 {
    /**
     * @dev Emitted when pool is paused
     * @param admin The admin address
     */
    event PoolPaused(address admin);
    /**
     * @dev Emitted when pool is unpaused
     * @param admin The admin address
     */
    event PoolUnpaused(address admin);

    /**
     * @dev initialize the pool with pool data and the symbol/name of the LP Token
     * @param _poolData The pool data structure
     * @param symbol The symbol of the lp token
     * @param name The name of the lp token
     */
    function initialize(DataTypes.PoolData memory _poolData, string memory symbol, string memory name) external;

    /**
     * @dev Function to pause
     */
    function pause() external;

    /**
     * @dev Function to unpause
     */
    function unpause() external;

    /**
     * @dev Function to get the quote for swapping shares in buy or sell direction
     * @param amounts The amounts of shares to buy or sell
     * @param tokenIds The shares token ids
     * @param buy The directional boolean. If buy direction then true
     * @param useFee the boolean determining whether to use Fee in the calculation or not in case we want to calculate the value of the shares for liquidity
     */
    function getQuote(
        uint256[] memory amounts,
        uint256[] memory tokenIds,
        bool buy,
        bool useFee
    ) external view returns (DataTypes.Quotation memory quotation);

    /**
     * @dev Function to swap stablecoins to shares
     * @param amounts The amounts of token ids outputted
     * @param tokenIds The token ids outputted
     * @param maxStable The maximum amount of stablecoin to be spent
     */
    function swapStable(uint256[] memory amounts, uint256[] memory tokenIds, uint256 maxStable) external;

    /**
     * @dev Function to swap shares to stablecoins
     * @param amounts The amounts of token ids outputted
     * @param tokenIds The token ids outputted
     * @param minStable The minimum stablecoin to receive
     */
    function swapShares(uint256[] memory amounts, uint256[] memory tokenIds, uint256 minStable) external;

    /**
     * @dev Function to get the TVL of the pool in stablecoin
     * @return uint256 The TVL
     */
    function getTVL() external view returns (uint256);

    /**
     * @dev Function to get the TVL of a specific sub pool
     * @param id The id of the sub pool
     * @return DataTypes.AMMSubPool1155 memory The TVL
     */
    function getPool(uint256 id) external view returns (DataTypes.AMMSubPool1155Details memory);

    /**
     * @dev Function to add liquidity using Stable coins
     * @param targetLP The amount of target LPs outputted
     * @param _maxStable The amount of maximum stablecoins to be spent
     */
    function addLiquidityStable(uint256 targetLP, uint256 _maxStable) external;

    /**
     * @dev Function to add liquidity using shares
     * @param tokenIds The token ids of shares to be spent
     * @param maxAmounts The maximum amounts of shares to be spent
     * @param targetLP The amount of required LPs outputted
     */
    function addLiquidityShares(uint256[] memory tokenIds, uint256[] memory maxAmounts, uint256 targetLP) external;

    /**
     * @dev Function to remove liquidity by shares
     * @param targetLP The amount of LPs to be burned
     * @param tokenIds The token ids of shares to be outputted
     * @param maxAmounts The maximum amounts of shares to be outputted
     */
    function removeLiquidityShares(uint256 targetLP, uint256[] memory tokenIds, uint256[] memory maxAmounts) external;

    /**
     * @dev Function to remove liquidity by stable coins
     * @param targetLP The amount of LPs to be burned
     * @param minStable The minimum stable tokens to receive
     */
    function removeLiquidityStable(uint256 targetLP, uint256 minStable) external;

    /**
     * @dev Function to process all queued transactions upto limit
     * @param limit The number of transactions to process
     * @return uint256 The number of transactions processed
     */
    function processWithdrawals(uint256 limit) external returns(uint256);

    /**
     * @dev Function to get the LP token price
     * @return uint256 The price
     */
    function getLPPrice() external returns (uint256);

    /**
     * @dev Function to get amount of a specific token id available in the pool
     * @param tokenId The token id
     * @return uint256 The amount
     */
    function getTokenIdAvailable(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Function that returns the subpool ids of the given token ids
     * @param tokenIds The address of the pool
     * @return subPools array of the subpool ids
     */
    function getSubPools(uint256[] memory tokenIds) external view returns (uint256[] memory);

    /**
     * @dev Function that returns the subpool ids of the given sequencial token ids
     * @param startTokenId The start id of the token ids
     * @param endTokenId The end id of the token ids
     * @return subPools The array of the subpool ids
     */
    function getSubPoolsSeq(uint256 startTokenId, uint256 endTokenId) external view returns (uint256[] memory);

    /**
     * @dev Function that deposits the initial liquidity to specific subpool
     * @param tokenIds The token ids array of the shares to deposit
     * @param amounts The amounts array of the shares to deposit
     * @param stableIn The stablecoins amount to deposit
     * @param subPoolId The sub pool id
     */
    function depositInitial(uint256[] memory tokenIds, uint256[] memory amounts, uint256 stableIn, uint256 subPoolId) external;

    /**
     * @dev Function to add a new sub pool
     * @param v The initial V value of the sub pool
     * @param f The initial F value of the sub pool
     */
    function addSubPool(uint256 v, uint256 f) external;

    /**
     * @dev Function to move shares sequencially to a different sub pool called by the admin
     * @param startId The start index of the token ids to be moved
     * @param endId The end index of the token ids to be moved
     * @param newSubPoolId The id of the new subpool
     */
    function moveShares(uint256 startId, uint256 endId, uint256 newSubPoolId) external;

    /**
     * @dev Function to move shares in an array list to a different sub pool called by the admin
     * @param ids The array of shares ids to be moved
     * @param newSubPoolId The id of the new subpool
     */
    function moveSharesList(uint256 newSubPoolId, uint256[] memory ids) external;

    /**
     * @dev Function to move enable or disable specific subpools by ids
     * @param subPoolIds The sub pools ids array
     * @param _newStatus The new status, enabled=true or disabled=false
     */
    function changeSubPoolStatus(uint256[] calldata subPoolIds, bool _newStatus) external;

    /**
     * @dev Function to move reserves between subpools
     * @param moverId The sub pool that will move the funds from
     * @param movedId The id of the sub pool that will move the funds to
     * @param amount The amount to move
     */
    function moveReserve(uint256 moverId, uint256 movedId, uint256 amount) external;

    /**
     * @dev Function to update the v of several subpools
     * @param subPoolIds The sub pools array
     * @param vArray The v array
     */
    function updatePoolV(uint256[] calldata subPoolIds, uint256[] calldata vArray) external;

    /**
     * @dev Function to deposit stablecoins from the pool to a yield generating protocol and getting synthetic tokens
     * @param amount The amount of stablecoins
     */
    function depositIntoStableYield(uint256 amount) external;

    /**
     * @dev Function to withdraw stablecoins from the pool to a yield generating protocol using the synthetic tokens
     * @param amount The amount of stablecoins to withdraw
     */
    function withdrawFromStableYield(uint256 amount) external;

    /**
     * @dev Function to rescue and send ERC20 tokens (different than the tokens used by the pool) to a receiver called by the admin
     * @param token The address of the token contract
     * @param amount The amount of tokens
     * @param receiver The address of the receiver
     */
    function RescueTokens(address token, uint256 amount, address receiver) external;

    /**
     * @dev Function to withdraw fees by a caller that is either the royalties or protocol address
     * @param to The address to send the funds to
     * @param amount The amount to withdraw
     * @param feeType The type of the fees to withdraw
     */

    function WithdrawFees(address to, uint256 amount, DataTypes.FeeType feeType) external;
}