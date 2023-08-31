// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IPaymentSplitterFactory} from "ethier/factories/IPaymentSplitterFactory.sol";

interface IAlbaDelegate {
    function tokenURI(uint256 tokenId, string memory slug) external view returns (string memory);

    function verifyMintReserve(bytes32 message, bytes calldata signature) external view;

    function verifyMint(
        bytes16 collectionId,
        address user,
        uint16 num,
        uint32 nonce,
        bytes calldata signature
    ) external view;

    function tokenHTML(
        bytes16 uuid,
        uint256 tokenId,
        bytes32 seed,
        bytes16[] memory deps
    ) external view returns (bytes memory);

    function paymentSplitterFactory() external view returns (IPaymentSplitterFactory);

    function operatorFilterSubscription() external view returns (address);

    function getAlbaFeeReceiver() external view returns (address);
}