// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../config/types.sol";
import {IOracle} from "./IOracle.sol";

interface IPomace {
    function oracle() external view returns (IOracle oracle);

    function checkEngineAccess(uint256 _tokenId, address _engine) external view;

    function checkEngineAccessAndTokenId(uint256 _tokenId, address _engine) external view;

    function engineIds(address _engine) external view returns (uint8 id);

    function assetIds(address _asset) external view returns (uint8 id);

    function assets(uint8 _id) external view returns (address addr, uint8 decimals);

    function engines(uint8 _id) external view returns (address engine);

    function isCollateralizable(uint8 _asset0, uint8 _asset1) external view returns (bool);

    function isCollateralizable(address _asset0, address _asset1) external view returns (bool);

    function getDebtAndPayout(uint256 tokenId, uint64 amount)
        external
        view
        returns (address engine, uint8 debtId, uint256 debt, uint8 payoutId, uint256 payout);

    function batchGetDebtAndPayouts(uint256[] calldata tokenId, uint256[] calldata amount)
        external
        view
        returns (Balance[] memory debts, Balance[] memory payouts);

    function getProductId(address engine, address underlying, address strike, address collateral)
        external
        view
        returns (uint32 id);

    function getTokenId(TokenType tokenType, uint32 productId, uint256 expiry, uint256 strike, uint256 exerciseWindow)
        external
        view
        returns (uint256 id);

    function getDetailFromProductId(uint32 _productId)
        external
        view
        returns (
            address engine,
            address underlying,
            uint8 underlyingDecimals,
            address strike,
            uint8 strikeDecimals,
            address collateral,
            uint8 collateralDecimals
        );

    /**
     * @notice burn option token and get out cash value at expiry
     * @param _account who to settle for
     * @param _tokenId  tokenId of option token to burn
     * @param _amount   amount to settle
     * @return debt amount collected
     * @return payout amount paid out
     */
    function settleOption(address _account, uint256 _tokenId, uint256 _amount)
        external
        returns (Balance memory debt, Balance memory payout);

    /**
     * @notice burn array of option tokens and get out cash value at expiry
     * @param _account who to settle for
     * @param _tokenIds array of tokenIds to burn
     * @param _amounts   array of amounts to burn
     */
    function batchSettleOptions(address _account, uint256[] memory _tokenIds, uint256[] memory _amounts) external;
}