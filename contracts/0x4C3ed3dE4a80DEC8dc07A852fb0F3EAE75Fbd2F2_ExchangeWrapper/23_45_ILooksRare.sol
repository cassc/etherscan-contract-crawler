// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../librairies/LibLooksRare.sol";

interface ILooksRare {
    function matchAskWithTakerBidUsingETHAndWETH(
        LibLooksRare.TakerOrder calldata takerBid,
        LibLooksRare.MakerOrder calldata makerAsk
    ) external payable;
}