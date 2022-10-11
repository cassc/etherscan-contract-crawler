// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title Data structure for different structs used in the contract
library DataStruct {
    /// @dev Order structure
    /// @param Offerer The order creator i.e. seller or buyer address
    /// @param offeredAsset The asset offered by the offerer. Example ERC721/ERC1155 in case of seller, ERC20/ETH in case of buyer 
    /// @param expectedAsset The asset offered by the offerer. Example ERC20/ETH in case of seller, ERC721/ERC1155 in case of buyer 
    /// @param salt For making the object hash unique. 0 is sent when buyOrderSignature is not provided
    /// @param start The epoch time when the auction should start. 0 for fixed price trade.
    /// @param end The epoch time when the auction should end. 0 for fixed price trade.
    /// @param data Provided in case of ERC1155 transfer.
    struct Order {
        address offerer;
        Asset offeredAsset;
        Asset expectedAsset;
        uint salt;
        uint start;
        uint end;
        bytes data;
    }

    /// @dev Null address for addr and 0 as quantity, tokenId can be sent as per required condition
    /// @param assetType Can be one of the values from TokenType.sol in bytes form
    /// @param addr The address of the contract in case except ETH
    /// @param tokenId The id of the token in case of ERC721 and ERC1155
    /// @param quantity Amount of the token to be transferred. WEI in case of ETH/ERC20.
    struct Asset {
        bytes4 assetType;
        address addr;
        uint tokenId;
        uint quantity;
    }

    /// @dev Used in calculatePayment for returning calculated data in specific format
    /// @param royaltyReceiver The address of the royalty receiver
    /// @param royaltyAmount The amount of the royalty to be received by the royaltyReceiver
    /// @param netAmount The amount to be received by the seller
    /// @param feeAmount The amount to deducted by the exchange for handling the order
    /// @param callTradedMethod The boolean value for determining if the traded method is to be called on the collectibles or not
    struct PaymentDetail {
        address royaltyReceiver;
        uint royaltyAmount;
        uint netAmount;
        uint feeAmount;
        bool callTradedMethod;
    }
}