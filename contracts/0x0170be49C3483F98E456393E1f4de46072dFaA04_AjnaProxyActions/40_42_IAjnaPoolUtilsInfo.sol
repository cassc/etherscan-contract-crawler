// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IAjnaPoolUtilsInfo {
    function priceToIndex(uint256 price_) external pure returns (uint256);

    function borrowerInfo(
        address pool_,
        address borrower_
    ) external view returns (uint256 debt_, uint256 collateral_, uint256 index_);

    function poolPricesInfo(
        address ajnaPool_
    )
        external
        view
        returns (uint256 hpb_, uint256 hpbIndex_, uint256 htp_, uint256 htpIndex_, uint256 lup_, uint256 lupIndex_);

    function lpToQuoteTokens(
        address ajnaPool_,
        uint256 lp_,
        uint256 index_
    ) external view returns (uint256 quoteAmount_);
}