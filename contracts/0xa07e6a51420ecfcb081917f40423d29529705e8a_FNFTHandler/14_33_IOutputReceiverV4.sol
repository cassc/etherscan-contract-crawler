// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IOutputReceiverV3.sol";


/**
 * @title Provider interface for Revest FNFTs
 */
interface IOutputReceiverV4 is IOutputReceiverV3 {

    event TransferERC20OutputReceiver(address indexed transferTo, address indexed transferFrom, address indexed token, uint amountTokens, uint fnftId, bytes extraData);

    event TransferERC721OutputReceiver(address indexed transferTo, address indexed transferFrom, address indexed token, uint[] tokenIds, uint fnftId, bytes extraData);

    event TransferERC1155OutputReceiver(address indexed transferTo, address indexed transferFrom, address indexed token, uint tokenId, uint amountTokens, uint fnftId, bytes extraData);

    function onTransferFNFT(
        uint fnftId, 
        address operator,
        address from,
        address to,
        uint quantity, 
        bytes memory data
    ) external;

}