// SPDX-License-Identifier: UNLICENSED
// Author: Kai Aldag <[email protected]>
// Date: August 15th, 2022
// Purpose: Convenience contract for aidropping external 1155 tokens


pragma solidity ^0.8.14;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


/**
 * @title Convenience smart contract for sending numerous ERC-1155 tokens from contract owner
 * 
 * @author Kai Aldag <[email protected]>
 * 
 * @dev Ensure the tokenContract has this contract marked as an approved address of the owner.
 * 
 * @custom:security-contact [email protected]
 */
contract BatchSender is Ownable {


    IERC1155 internal tokenContract;
    uint256 internal defaultTokenId;

    constructor(address _tokenAddress, uint256 _defaultTokenId) Ownable() {
        tokenContract = IERC1155(_tokenAddress);
        defaultTokenId = _defaultTokenId;
    }

    // ========================  Transfer Methods  ========================

    function defaultBatchSend(address[] calldata recipients, uint256 quantity) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            tokenContract.safeTransferFrom(owner(), recipient, defaultTokenId, quantity, "");
        }
    }

    function defaultBatchSend(address[] calldata recipients, uint256[] calldata quantities) external onlyOwner {
        require(recipients.length == quantities.length, "BatchSender: lengths do not match");
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 quantity = quantities[i];
            tokenContract.safeTransferFrom(owner(), recipient, defaultTokenId, quantity, "");
        }
    }

    function batchSend(uint256 tokenId, address[] calldata recipients) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            tokenContract.safeTransferFrom(owner(), recipient, tokenId, 1, "");
        }
    }


    // ========================  Setter Methods  ========================

    function updateTokenAddress(address newAddress) external onlyOwner {
        tokenContract = IERC1155(newAddress);
    }

    function updateDefaultTokenId(uint256 newId) external onlyOwner {
        defaultTokenId = newId;
    }
}