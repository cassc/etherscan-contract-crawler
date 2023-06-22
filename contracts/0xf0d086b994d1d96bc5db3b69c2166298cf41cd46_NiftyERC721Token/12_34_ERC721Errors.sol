// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract ERC721Errors {
    string internal constant ERROR_QUERY_FOR_ZERO_ADDRESS = "Query for zero address";
    string internal constant ERROR_QUERY_FOR_NONEXISTENT_TOKEN = "Token does not exist";
    string internal constant ERROR_APPROVAL_TO_CURRENT_OWNER = "Current owner approval";
    string internal constant ERROR_APPROVE_TO_CALLER = "Approve to caller";
    string internal constant ERROR_NOT_OWNER_NOR_APPROVED = "Not owner nor approved";
    string internal constant ERROR_NOT_AN_ERC721_RECEIVER = "Not an ERC721Receiver";
    string internal constant ERROR_TRANSFER_FROM_INCORRECT_OWNER = "Transfer from incorrect owner";
    string internal constant ERROR_TRANSFER_TO_ZERO_ADDRESS = "Transfer to zero address";    
    string internal constant ERROR_ALREADY_MINTED = "Token already minted";    
    string internal constant ERROR_NO_TOKENS_MINTED = "No tokens minted";    
}