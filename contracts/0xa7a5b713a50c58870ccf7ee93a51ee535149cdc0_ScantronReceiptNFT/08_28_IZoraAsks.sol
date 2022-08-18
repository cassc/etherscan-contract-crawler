// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.9;

interface IZoraAsks {
    function askForNFT(address nft, uint256 id)
        external
        view
        returns (
            address seller,
            address sellerFundsRecipient,
            address askCurrency,
            uint16 findersFeeBps,
            uint256 askPrice
        );
}