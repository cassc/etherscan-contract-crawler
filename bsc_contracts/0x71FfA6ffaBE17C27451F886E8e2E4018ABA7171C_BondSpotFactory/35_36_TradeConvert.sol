// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library TradeConvert {
    // convert from base amount to quote amount by pip
    function baseToQuote(
        uint256 quantity,
        uint128 pip,
        uint256 basisPoint
    ) internal view returns (uint256) {
        // quantity * pip / baseBasisPoint / basisPoint / baseBasisPoint;
        // shorten => quantity * pip / basisPoint ;
        return (quantity * pip) / basisPoint;
    }

    function quoteToBase(
        uint256 quoteAmount,
        uint128 pip,
        uint256 basisPoint
    ) public view returns (uint256) {
        return (quoteAmount * basisPoint) / pip;
    }
}