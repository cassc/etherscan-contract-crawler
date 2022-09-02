// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./AccessTokenManager.sol";

/// @author BELLA
/// @title Utils
/// @notice Smart contract with some function utilities
contract Utils {

    struct InitAccessTokenData{
        string channelId; 
        address creator; 
        uint256 tickets;
        uint96 royaltyPercentage; 
        string uriMetadata;
        string communityId;
        AccessTokenManager.AccessTokenItem item;
    }

    struct PurchaseData{
        address sender;
        uint value;
        string channelId;
        address accessTokenContract;
        AccessTokenManager.AccessTokenItem item;
    }

    struct CalculateFeesAndPriceData{
        uint price;
        uint feeBuyerPercentage; 
        uint feeCreatorPercentage; 
        uint minBuyerFeeValue;
    }

    // External functions

    /// validateInitAccessToken
    /// @param data InitAccessTokenData struct    
    /// @notice validation for init access token operation
    function validateInitAccessToken(
        InitAccessTokenData memory data)
        external pure
    {
        require(bytes(data.channelId).length != 0, "ERR-1-ATM");
        require(data.creator != address(0), "ERR-8-ATM");
        require(data.royaltyPercentage <= 10000, "ERR-9-ATM");
        require(bytes(data.uriMetadata).length != 0, "ERR-10-ATM");
        require(data.tickets > 0, "ERR-11-ATM");
        require(bytes(data.communityId).length != 0, "ERR-12-ATM");
        if (data.item.tokenId > 0){
            revert("ERR-13-ATM");
        }
    }

    /// validatePurchase
    /// @param data PurchaseData struct    
    /// @notice validation for purchase operation
    function validatePurchase(
        PurchaseData memory data)
        external view
    {

        require(bytes(data.channelId).length != 0, "ERR-1-ATM");
        require(data.sender != data.item.creator, "ERR-2-ATM");
        require(data.value == data.item.finalPrice, _concatenateStringUint("ERR-3-ATM", data.item.finalPrice));
        if (data.item.tokenId != 0 
            && IERC1155(data.accessTokenContract).balanceOf(data.item.creator, data.item.tokenId) == 0) {            
            revert("ERR-4-ATM");
        }
    }

    /// Calculate fee and price  
    /// @param data CalculateFeesAndPriceData struct    
    /// @notice to calculate the fees (for buyer and creator) and price
    function calculateFeesAndPrice(
        CalculateFeesAndPriceData memory data
    ) 
        external 
        pure 
        returns(uint, uint, uint) 
    {
        uint feeCreator = 0;
        uint feeBuyer = 0;
        if(data.price > 0) {
            if(data.feeCreatorPercentage != 0) {
                feeCreator = _calculateFee( data.price, data.feeCreatorPercentage );
            }
            if(data.feeBuyerPercentage != 0) {
                feeBuyer = _calculateFee( data.price, data.feeBuyerPercentage );
            }
        } else {
            if(data.minBuyerFeeValue != 0) {
                feeBuyer = data.minBuyerFeeValue;
            }
        }
        uint finalPrice = data.price + feeBuyer;
        return (finalPrice, feeCreator, feeBuyer);
    }


    // Private functions

    /// ConcatenateStringUint
    /// @param _string string message
    /// @param value uint value
    /// @notice function to concatenate a string with a uint by converting the uint to string using the openzeppelin library
    function _concatenateStringUint(string memory _string, uint value) private pure returns(string memory) {
        return string(abi.encodePacked(_string, ":", Strings.toString(value)));
    }


    /// Calculate fee.
    /// @param price to apply fee
    /// @param feePercentage to apply to price
    /// @notice to calculate the fee for given price and feePercentage, feePercentage are managed as for ERC2981 so for example to calculate the 5% of the price feePercentage will be 500
    function _calculateFee(uint price, uint feePercentage) private pure returns(uint) {       
        return price * feePercentage / 10000;
    }
}