// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

interface IDODO {
    function sellBaseToken(
        uint256 amount,
        uint256 minReceiveQuote,
        bytes calldata data
    ) external returns (uint256);

    function buyBaseToken(
        uint256 amount,
        uint256 maxPayQuote,
        bytes calldata data
    ) external returns (uint256);
}

interface IDODOHelper {
    function querySellQuoteToken(IDODO dodo, uint256 amount)
        external
        view
        returns (uint256);
}