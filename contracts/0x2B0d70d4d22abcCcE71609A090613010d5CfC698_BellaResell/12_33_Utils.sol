// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @author BELLA
/// @title BRUtilities
/// @notice Smart contract that store all the business logic for BellaResell smart contract
contract Utils is IERC165, AccessControl {

    address private bellaResellAddress;

    using ERC165Checker for address;
    using SafeMath for uint256;
    using SafeMath for uint96;

    mapping(address => bool) public contractAddressWhitelist;

    //Interface
    bytes4 private constant _INTERFACE_ID_IERC165 = type(IERC165).interfaceId;
    bytes4 private constant _INTERFACE_ID_ERC1155 = type(IERC1155).interfaceId;
    bytes4 private constant _INTERFACE_ID_ERC721 = type(IERC721).interfaceId;
    bytes4 private constant _INTERFACE_ID_ERC2981 = type(IERC2981).interfaceId;

    constructor(address _bellaResellAddress) {
        bellaResellAddress = _bellaResellAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// Public Functions

    /// Supports interface function.
    /// @notice supports interface function
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(IERC165, AccessControl)
        returns (bool)
    {
        return interfaceId == _INTERFACE_ID_IERC165;
    }

    /// External Functions

    /// Validate Sell.
    /// @param tokenId of NFT
    /// @param nftContract that has generated the NFT
    /// @param supply for that NFT
    /// @param price to apply
    /// @param seller address
    /// @notice validate the data for put on sale an NFT
    function validateSell(
        uint tokenId, 
        address nftContract, 
        uint supply, 
        uint price, 
        address seller
    ) 
        external 
        view 
        returns(bool, string memory) 
    {
        require(nftContract != address(0), "ERR-1-BR");
        require(contractAddressWhitelist[nftContract] == true, "ERR-21-BR");

        require(price > 0, "ERR-2-BR");

        bool __isERC721 = true;
        string memory tokenType = "ERC721";
        if(_isERC721(nftContract)) {
            _validateERC721(nftContract, tokenId, seller);
        } else if(_isERC1155(nftContract)) {
            require(supply > 0, "ERR-14-BR");
            _validateERC1155(nftContract, tokenId, supply, seller);
            __isERC721 = false;
            tokenType = "ERC1155";
        } else {
            revert("ERR-13-BR");
        }

        return (__isERC721, tokenType);
    }

    /// Validate Modify.
    /// @param tokenId of NFT
    /// @param nftContract that has generated the NFT
    /// @param supply for that NFT
    /// @param price to apply
    /// @param seller address
    /// @notice validate the data for modify an Item on sale
    function validateModify(
        uint tokenId, 
        address nftContract, 
        uint supply, 
        uint price, 
        address seller
    ) 
        external 
        view 
        returns(bool, string memory) 
    {
        require(price > 0, "ERR-2-BR");

        bool __isERC721 = true;
        string memory tokenType = "ERC721";
        if(_isERC721(nftContract)) {
            if(supply == 1) {
                _validateERC721(nftContract, tokenId, seller);
            } else if(supply > 1) {
                revert("ERR-14-BR");
            }
        } else if(_isERC1155(nftContract)) {
            if(supply > 0) {
                _validateERC1155(nftContract, tokenId, supply, seller);
            }
            __isERC721 = false;
            tokenType = "ERC1155";
        } else {
            revert("ERR-13-BR");
        }

        return (__isERC721, tokenType);
    }

    /// Validate Buy.
    /// @param sender for buy transaction
    /// @param seller address
    /// @param quantity how much token sender want to buy
    /// @param supply for that NFT
    /// @param price to apply
    /// @param value for transaction
    /// @notice validate the data to buy an Item
    function validateBuy(
        address sender, 
        address seller, 
        uint quantity, 
        uint supply, 
        uint price, 
        uint value
    ) 
        external 
        pure 
        returns(uint) 
    {
        require(sender != address(0), "ERR-19-BR");
        require(seller != address(0), "ERR-20-BR");
        require(quantity > 0 && quantity <= supply, "ERR-15-BR");
        require(sender != seller, "ERR-5-BR");
        (bool result, uint256 requiredValue) = price.tryMul(quantity);
        if(result) {
            require(value == requiredValue, string(abi.encodePacked("ERR-16-BR", ":", Strings.toString(requiredValue))));
            
        } else {
            revert("ERR-6-BR");
        }

        return requiredValue;
    }

    /// Validate RemoveItem.
    /// @param supply for that NFT
    /// @param nftContract that has generated the NFT
    /// @param tokenId of the NFT
    /// @param seller address
    /// @notice validate the data remove an item on sale
    function validateRemoveItem(
        uint supply, 
        address nftContract, 
        uint tokenId, 
        address seller
    ) 
        external 
        view
    {
        if(supply > 0) {
            if(_isERC721(nftContract)) {
                if(IERC721(nftContract).ownerOf(tokenId) == seller) {
                    revert("ERR-17-BR");
                }
            } else {
                if(IERC1155(nftContract).balanceOf(seller, tokenId) >= supply) {
                    revert("ERR-17-BR");
                }
            }
        } else {
            revert("ERR-18-BR");
        }
    }

    /// Calculate fee.
    /// @param price to apply fee
    /// @param _feePercentage to apply to price
    /// @notice calcualte the fee for given price and feePercentage, feePercentage are managed as for ERC2981 so for example to calculate the 5% of the price feePercentage will be 500
    function calculateFee(uint price, uint _feePercentage) 
        external 
        pure
        returns(uint) {       
        return price * _feePercentage / 10000;
    }
    
    /// Is ERC2981.
    /// @param nftContract to verify
    /// @param tokenId to verify
    /// @param price for selling
    /// @notice check if the given NFT supports ERC2981 and calculate the values and recipient for royalty
    function isERC2981(address nftContract, uint tokenId, uint price) 
        external 
        view 
        returns(uint,address) 
    {
        address receiptReceiver = address(0);
        uint royaltyAmount = 0;
        if(nftContract.supportsInterface(_INTERFACE_ID_ERC2981)) {
            (receiptReceiver, royaltyAmount) = IERC2981(nftContract).royaltyInfo(tokenId, price);
        }
        return (royaltyAmount, receiptReceiver);
    }

    /// External Functions - Only Owner

    /// Set bella resell address.
    /// @param _bellaResellAddress smart contract address
    /// @notice set the bella resell address
    function setBellaResellAddress(address _bellaResellAddress) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        bellaResellAddress = _bellaResellAddress;
    }

     /// Put nft contract address in whitelist
    /// @param nftContractAddress nft contract address
    /// @notice put nft contract address in whitelist
    function putNftContractAddress(address nftContractAddress, bool active) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        contractAddressWhitelist[nftContractAddress]=active;
    }

    /// Private Functions - view

    /// Check an address.
    /// @param _contract to calculate percentage
    /// @notice check if the given address '_contract' is an ERC1155
    function _isERC1155(address _contract) private view returns (bool) {
        return _contract.supportsInterface(_INTERFACE_ID_ERC1155);
    }    
    
    /// Check an address.
    /// @param _contract to calculate percentage
    /// @notice check if the given address '_contract' is an ERC721
    function _isERC721(address _contract) private view returns (bool) {
        return _contract.supportsInterface(_INTERFACE_ID_ERC721);
    }

    /// Validate token ERC1155.
    /// @param nftContract that generates the token
    /// @param tokenId of the nft
    /// @param supply for that token
    /// @param seller address of owner
    /// @notice verify that the seller own at least the supply specified for the sale, and if BellaResell has permission to transfer it
    function _validateERC1155(address nftContract, uint tokenId, uint supply, address seller) private view {
        uint creatorBalance = IERC1155(nftContract).balanceOf(seller, tokenId);
        if(creatorBalance == 0 || creatorBalance < supply) {
            revert("ERR-12-BR");
        }
        if(!IERC1155(nftContract).isApprovedForAll(seller, bellaResellAddress)) {
            revert("ERR-11-BR");
        }
    }

    /// Validate token ERC721.
    /// @param nftContract that generates the token
    /// @param tokenId of the nft
    /// @param seller address of owner
    /// @notice verify that the seller is the owner of the given token, and if BellaResell has permission to transfer it
    function _validateERC721(address nftContract, uint tokenId, address seller) private view {
        if(IERC721(nftContract).ownerOf(tokenId) != seller) {
                revert("ERR-10-BR");
            }
        if(!IERC721(nftContract).isApprovedForAll(seller, bellaResellAddress)) {
            revert("ERR-11-BR");
        }
    }


}