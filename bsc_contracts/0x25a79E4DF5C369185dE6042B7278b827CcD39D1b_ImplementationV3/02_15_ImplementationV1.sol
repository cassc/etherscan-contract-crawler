// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Implementation} from "./Implementation.sol";
import {SignatureUtils} from "../utils/SignatureUtils.sol";

contract ImplementationV1 is Implementation {
    /**
     * @dev Handler mint request
     * @param (0) token id, (1) totalCopies, (2) onSaleQuantity, (3) price, (4) amount, (5) token type
     * @param (0) buyer, (1) seller, (2) signer, (3) collectionAddress, (4) tokenAddress
     * @param (0) saleOrderId, (1) transactionId
     * @param (0) saleOrderSignature, (1) mintRequestSignature
     */
    function handleMintRequest(
        uint256[] memory,
        address[] memory,
        bytes[] memory,
        bytes[] memory
    ) public payable {
        _delegatecall(mintHandler);
    }

    /**
     * @dev Handler buy request
     * @param (0) token id, (1) onSaleQuantity, (2) price, (3) token type, (4) amount
     * @param (0) buyer, (1) seller, (2) signer,(3) tokenAddress
     * @param (0) saleOrderId, (1) transactionId
     * @param (0) saleOrderSignature, (1) buyRequestSignature
     */
    function handleBuyRequest(
        uint256[] memory,
        address[] memory,
        bytes[] memory,
        bytes[] memory
    ) public payable  {
        _delegatecall(buyHandler);
    }

    /**
     * @dev Handle cancel sale order request
     * @param (0) onSaleQuantity, (1) price, (2) tokenType
     * @param (0) seller, (1) caller
     * @param (0) saleOrderId
     * @param (0) saleOrderSignature
     */
    function handleCancelOrder(
        uint256[] memory,
        address[] memory,
        bytes[] memory,
        bytes[] memory
    ) public {
        _delegatecall(cancelHandler);
    }

    function handleMintRequestByAdmin(
        address,
        bytes[] memory,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory
    ) public {
        _delegatecall(adminMintHandler);
    }
}