/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "../external/lib/PMMPricing.sol";

interface IDODOV2 {
    //========== Common ==================

    function sellBase(address to) external returns (uint256 receiveQuoteAmount);

    function sellQuote(address to) external returns (uint256 receiveBaseAmount);

    function getVaultReserve() external view returns (uint256 baseReserve, uint256 quoteReserve);

    function querySellQuote(address trader, uint256 payQuoteAmount)
        external
        view
        returns (
            uint256 receiveBaseAmount,
            uint256 mtFee,
            PMMPricing.RState newRState,
            uint256 newQuoteTarget
        );

    function querySellBase(address trader, uint256 payBaseAmount)
        external
        view
        returns (
            uint256 receiveQuoteAmount,
            uint256 mtFee,
            PMMPricing.RState newRState,
            uint256 newBaseTarget
        );

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function getPMMStateForCall()
        external
        view
        returns (
            uint256 i,
            uint256 K,
            uint256 B,
            uint256 Q,
            uint256 B0,
            uint256 Q0,
            uint256 R
        );

    function getUserFeeRate(address user) external view returns (uint256 lpFeeRate, uint256 mtFeeRate);

    function getDODOPoolBidirection(address token0, address token1)
        external
        view
        returns (address[] memory, address[] memory);

    //========== DODOVendingMachine ========

    function createDODOVendingMachine(
        address baseToken,
        address quoteToken,
        uint256 lpFeeRate,
        uint256 i,
        uint256 k,
        bool isOpenTWAP
    ) external returns (address newVendingMachine);

    function buyShares(address to)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    //========== DODOPrivatePool ===========

    function createDODOPrivatePool() external returns (address newPrivatePool);

    function initDODOPrivatePool(
        address dppAddress,
        address creator,
        address baseToken,
        address quoteToken,
        uint256 lpFeeRate,
        uint256 k,
        uint256 i,
        bool isOpenTwap
    ) external;

    function reset(
        address operator,
        uint256 newLpFeeRate,
        uint256 newI,
        uint256 newK,
        uint256 baseOutAmount,
        uint256 quoteOutAmount,
        uint256 minBaseReserve,
        uint256 minQuoteReserve
    ) external returns (bool);

    function _OWNER_() external returns (address);

    function _LP_FEE_RATE_() external returns (uint64);

    function _K_() external returns (uint64);

    function _I_() external returns (uint128);

    //========== CrowdPooling ===========

    function createCrowdPooling() external returns (address payable newCrowdPooling);

    function initCrowdPooling(
        address cpAddress,
        address creator,
        address[] memory tokens,
        uint256[] memory timeLine,
        uint256[] memory valueList,
        bool[] memory switches,
        int256 globalQuota
    ) external;

    function bid(address to) external;
}