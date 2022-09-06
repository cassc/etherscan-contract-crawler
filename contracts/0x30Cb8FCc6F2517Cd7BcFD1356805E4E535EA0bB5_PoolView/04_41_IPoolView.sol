// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import {IERC1155Metadata} from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import {PoolStorage} from "./PoolStorage.sol";

/**
 * @notice Pool view function interface
 */
interface IPoolView is IERC1155Metadata {
    /**
     * @notice get fee receiver address
     * @dev called by PremiaMakerKeeper
     * @return fee receiver address
     */
    function getFeeReceiverAddress() external view returns (address);

    /**
     * @notice get fundamental pool attributes
     * @return structured PoolSettings
     */
    function getPoolSettings()
        external
        view
        returns (PoolStorage.PoolSettings memory);

    /**
     * @notice get the list of all token ids in circulation
     * @return list of token ids
     */
    function getTokenIds() external view returns (uint256[] memory);

    /**
     * @notice get current C-Level, accounting for unrealized decay and pending deposits
     * @param isCall whether query is for call or put pool
     * @return cLevel64x64 64x64 fixed point representation of C-Level
     */
    function getCLevel64x64(bool isCall) external view returns (int128);

    /**
     * @notice get pool APY fee
     * @return 64x64 fixed point representation of APY fee
     */
    function getApyFee64x64() external view returns (int128);

    /**
     * @notice get steepness coefficient
     * @param isCall whether query is for call or put pool
     * @return 64x64 fixed point representation of C steepness of Pool
     */
    function getSteepness64x64(bool isCall) external view returns (int128);

    /**
     * @notice get oracle price at timestamp
     * @param timestamp timestamp to query
     * @return 64x64 fixed point representation of price
     */
    function getPrice64x64(uint256 timestamp) external view returns (int128);

    /**
     * @notice get first oracle price update after timestamp. If no update has been registered yet, return current price feed spot price
     * @param timestamp timestamp to query
     * @return spot64x64 64x64 fixed point representation of price
     */
    function getPriceAfter64x64(uint256 timestamp)
        external
        view
        returns (int128 spot64x64);

    /**
     * @notice get parameters for token id
     * @param tokenId token id to query
     * @return token type enum
     * @return maturity
     * @return 64x64 fixed point representation of strike price
     */
    function getParametersForTokenId(uint256 tokenId)
        external
        pure
        returns (
            PoolStorage.TokenType,
            uint64,
            int128
        );

    /**
     * @notice get minimum purchase and interval amounts
     * @return minCallTokenAmount minimum call pool amount
     * @return minPutTokenAmount minimum put pool amount
     */
    function getMinimumAmounts()
        external
        view
        returns (uint256 minCallTokenAmount, uint256 minPutTokenAmount);

    /**
     * @notice get TVL (total value locked) for given address
     * @param account address whose TVL to query
     * @return underlyingTVL user total value locked in call pool (in underlying token amount)
     * @return baseTVL user total value locked in put pool (in base token amount)
     */
    function getUserTVL(address account)
        external
        view
        returns (uint256 underlyingTVL, uint256 baseTVL);

    /**
     * @notice get TVL (total value locked) of entire Pool
     * @return underlyingTVL total value locked in call pool (in underlying token amount)
     * @return baseTVL total value locked in put pool (in base token amount)
     */
    function getTotalTVL()
        external
        view
        returns (uint256 underlyingTVL, uint256 baseTVL);

    /**
     * @notice get position in the liquidity queue of the Pool
     * @param account account address whose liquidity position to query
     * @param isCallPool whether query is for call or put pool
     * @return liquidityBeforePosition total available liquidity before account's liquidity queue
     * @return positionSize size of the account's liquidity queue position
     */
    function getLiquidityQueuePosition(address account, bool isCallPool)
        external
        view
        returns (uint256 liquidityBeforePosition, uint256 positionSize);

    /**
     * @notice get the amount of APY fees reserved for given user and token id
     * @param account account whose reserved fees to query
     * @param shortTokenId short token id whose reserved fees to query
     * @return amount quantity of fees reserved
     */
    function getFeesReserved(address account, uint256 shortTokenId)
        external
        view
        returns (uint256 amount);

    /**
     * @notice get the address of PremiaMining contract
     * @return address of PremiaMining contract
     */
    function getPremiaMining() external view returns (address);

    /**
     * @notice get the gradual divestment timestamps of a user
     * @param account address whose divestment timestamps to query
     * @return callDivestmentTimestamp gradual divestment timestamp of the user for the call pool
     * @return putDivestmentTimestamp gradual divestment timestamp of the user for the put pool
     */
    function getDivestmentTimestamps(address account)
        external
        view
        returns (
            uint256 callDivestmentTimestamp,
            uint256 putDivestmentTimestamp
        );

    /**
     * @notice get the spot price offset used to account for price feed lag
     * @return spotOffset64x64 64x64 fixed point representation of spot price offset
     */
    function getSpotOffset64x64()
        external
        view
        returns (int128 spotOffset64x64);

    /**
     * @notice get the exchange helper address
     * @return exchangeHelper exchange helper address
     */
    function getExchangeHelper() external view returns (address exchangeHelper);
}