// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../lib/grappa/src/config/types.sol" as Grappa;
import "../../lib/grappa/src/core/engines/cross-margin/types.sol" as MarginEngine;

interface IMarginEngine {
    function grappa() external view returns (address);

    function optionToken() external view returns (address);

    function marginAccounts(address)
        external
        view
        returns (MarginEngine.Position[] memory shorts, MarginEngine.Position[] memory longs, Grappa.Balance[] memory collaterals);

    function execute(address account, Grappa.ActionArgs[] calldata actions) external;

    function batchExecute(Grappa.BatchExecute[] calldata batchActions) external;

    function previewMinCollateral(MarginEngine.Position[] memory shorts, MarginEngine.Position[] memory longs)
        external
        view
        returns (Grappa.Balance[] memory);
}

interface IGrappa {
    function assets(uint8) external view returns (Grappa.AssetDetail memory);

    function assetIds(address) external view returns (uint8);

    function engineIds(address) external view returns (uint8);

    function oracleIds(address) external view returns (uint8);

    function getPayout(uint256 tokenId, uint64 amount)
        external
        view
        returns (address engine, address collateral, uint256 payout);

    function getProductId(address oracle, address engine, address underlying, address strike, address collateral)
        external
        view
        returns (uint40 id);

    function getTokenId(Grappa.TokenType tokenType, uint40 productId, uint256 expiry, uint256 longStrike, uint256 shortStrike)
        external
        view
        returns (uint256 id);

    function getDetailFromProductId(uint40 productId)
        external
        view
        returns (
            address oracle,
            address engine,
            address underlying,
            uint8 underlyingDecimals,
            address strike,
            uint8 strikeDecimals,
            address collateral,
            uint8 collateralDecimals
        );
}

interface IOptionToken {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IOracle {
    /**
     * @notice  get spot price of _base, denominated in _quote.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @return price with 6 decimals
     */
    function getSpotPrice(address _base, address _quote) external view returns (uint256);

    /**
     * @dev get expiry price of underlying, denominated in strike asset.
     * @param _base base asset. for ETH/USD price, ETH is the base asset
     * @param _quote quote asset. for ETH/USD price, USD is the quote asset
     * @param _expiry expiry timestamp
     *
     * @return price with 6 decimals
     */
    function getPriceAtExpiry(address _base, address _quote, uint256 _expiry)
        external
        view
        returns (uint256 price, bool isFinalized);

    /**
     * @dev return the maximum dispute period for the oracle
     * @dev this will only be checked during oracle registration, as a soft constraint on integrating oracles.
     */
    function maxDisputePeriod() external view returns (uint256 disputePeriod);
}