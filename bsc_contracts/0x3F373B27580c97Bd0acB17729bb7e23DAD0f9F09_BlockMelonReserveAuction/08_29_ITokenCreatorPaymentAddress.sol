// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// originally implemented at 0x005d77e5eeab2f17e62a11f1b213736ca3c05cf6
interface ITokenCreatorPaymentAddress {
    function getTokenCreatorPaymentAddress(uint256 tokenId)
        external
        view
        returns (address payable tokenCreatorPaymentAddress);
}