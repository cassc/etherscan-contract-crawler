// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Properties, ItemType} from "../libraries/OrderStructs.sol";
import "../interfaces/IExecutionDelegate.sol";

contract TransferPolicy {

    /**
     * @notice Transfer fees and funds to royalty recipient, protocol, and seller
     * @param currency currency being used for the purchase (e.g., WETH/USDC)
     * @param from sender of the funds
     * @param to seller's recipient
     * @param amount amount being transferred (in currency)
     */
    function _transferFeesAndFunds(
        address executionDelegate,
        address currency,
        address from,
        address to,
        uint256 amount,
        uint256 royaltyFee,
        address royaltyRecipient,
        uint256 protocolFee,
        address protocolFeeRecipient
    ) internal {
        // Initialize the final amount that is transferred to seller
        uint256 finalSellerAmount = amount;

        // 1. Protocol fee
        uint256 protocolFeeAmount = (protocolFee * amount) / 10000;
        finalSellerAmount -= protocolFeeAmount;

        // 2. Royalty fee
        uint256 royaltyFeeAmount = (royaltyFee * amount) / 10000;
        finalSellerAmount -= royaltyFeeAmount;

        if (currency == address(0)) {
            // 1. Protocol fee
            if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
                require(
                    msg.value >= protocolFeeAmount,
                    "_transferFeesAndFunds: increase protocolFeeAmount"
                );
                payable(protocolFeeRecipient).transfer(protocolFeeAmount);
            }

            // 2. Royalty fee
            if ((royaltyRecipient != address(0)) && (royaltyFeeAmount != 0)) {
                require(
                    msg.value >= royaltyFeeAmount,
                    "_transferFeesAndFunds: increase royaltyFeeAmount"
                );
                payable(royaltyRecipient).transfer(royaltyFeeAmount);
            }

            // 3. Transfer final amount to seller
            require(
                msg.value >= finalSellerAmount,
                "_transferFeesAndFunds: increase price"
            );
            payable(to).transfer(finalSellerAmount);
        } else {
            // 1. Protocol fee
            if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
                IExecutionDelegate(executionDelegate).transferERC20(currency, from, protocolFeeRecipient, protocolFeeAmount);
            }

            // 2. Royalty fee
            if ((royaltyRecipient != address(0)) && (royaltyFeeAmount != 0)) {
                IExecutionDelegate(executionDelegate).transferERC20(currency, from, royaltyRecipient, royaltyFeeAmount);
            }

            // 3. Transfer final amount (post-fees) to seller
            IExecutionDelegate(executionDelegate).transferERC20(currency, from, to, finalSellerAmount);
        }
    }

    /**
     * @notice Transfer NFT
     * @param itemType item type (ERC20, ERC721, ERC1155)
     * @param collection address  of the token collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @param amount amount of tokens (1 for ERC721, 1+ for ERC1155)
     * @dev For ERC721, amount is not used
     */
    function _transferNonFungibleToken(
        address executionDelegate,
        ItemType itemType,
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (itemType == ItemType.ERC1155) {
            // erc1155 safeTransferFrom
            IExecutionDelegate(executionDelegate).transferERC1155(collection, from, to, tokenId, amount);
        } else if (itemType == ItemType.ERC721) {
            // erc721 safeTransferFrom
            IExecutionDelegate(executionDelegate).transferERC721(collection, from, to, tokenId);
        }
    }

}