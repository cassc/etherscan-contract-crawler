// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @title OrderTypes
 * @author nneverlander. Twitter @nneverlander
 * @notice This library contains the order types used by the main exchange and complications
 */
library OrderTypes {
    /// @dev the tokenId and numTokens (==1 for ERC721)
    struct TokenInfo {
        uint256 tokenId;
        uint256 numTokens;
    }

    /// @dev an order item is a collection address and tokens from that collection
    struct OrderItem {
        address collection;
        TokenInfo[] tokens;
    }

    struct MakerOrder {
        ///@dev is order sell or buy
        bool isSellOrder;
        ///@dev signer of the order (maker address)
        address signer;
        ///@dev Constraints array contains the order constraints. Total constraints: 7. In order:
        // numItems - min (for buy orders) / max (for sell orders) number of items in the order
        // start price in wei
        // end price in wei
        // start time in block.timestamp
        // end time in block.timestamp
        // nonce of the order
        // max tx.gasprice in wei that a user is willing to pay for gas
        // 1 for trustedExecution, 0 or non-existent for not trustedExecution
        uint256[] constraints;
        ///@dev nfts array contains order items where each item is a collection and its tokenIds
        OrderItem[] nfts;
        ///@dev address of complication for trade execution (e.g. FlowOrderBookComplication), address of the currency (e.g., WETH)
        address[] execParams;
        ///@dev additional parameters like traits for trait orders, private sale buyer for OTC orders etc
        bytes extraParams;
        ///@dev the order signature uint8 v: parameter (27 or 28), bytes32 r, bytes32 s
        bytes sig;
    }
}