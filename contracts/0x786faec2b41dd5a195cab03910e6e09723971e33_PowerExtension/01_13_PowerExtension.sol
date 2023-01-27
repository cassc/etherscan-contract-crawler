// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @artist: Gavin Shapiro

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


interface ILazyDelivery is IERC165 {
    function deliver(uint40 listingId, address to, uint256 assetId, uint24 payableCount, uint256 payableAmount, address payableERC20, uint256 index) external returns(uint256);
}

contract PowerExtension is AdminControl, ICreatorExtensionTokenURI, ILazyDelivery{

    event TokenMinted(address to, uint256 tokenID);
    
    // Creator contract address for the collection.
    address private _creator; 
    
    // Animation and thumbnail URIs. All other metadata is on-chain.
    string private _imageURI;
    string private _animationURI;
    string private _description;
    bool private _holderMintEnabled;

    // Internal trackers that allow for on-chain updating of Rarity property with every mint
    mapping(uint => uint) public _powers;
    uint _currentRarity = 1;
    uint _currentPowerCounter = 0;
    uint _currentTokenID;

    // Marketplace address and listingID for the Meaning auction
    address _marketplace;
    uint _listingId;

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(ILazyDelivery).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    // Set up extension with marketplace address, listing ID, thumbnail image URI, and animation URI
    function configure(address creator, uint40 listingId, address marketplace, string memory newImageURI, string memory newAnimationURI, string memory description) public adminRequired {
        _creator = creator;
        _listingId = listingId;
        _marketplace = marketplace;
        _imageURI = newImageURI;
        _animationURI = newAnimationURI;
        _description = description;
    } 

    function activateHolderMint() external adminRequired {
         _holderMintEnabled = true;
    }

    function deliver(uint40 listingId, address to, uint256, uint24, uint256, address, uint256) external override returns(uint) {
        require(msg.sender == _marketplace && listingId == _listingId, "Invalid calldata");
        require(IERC721(_creator).ownerOf(8) != address(0), "Meaning tokens must be already minted");
        _currentPowerCounter++;
        updatePower();
        return IERC721CreatorCore(_creator).mintExtension(to);
    }

    function holderMint(uint ownedTokenID) public{
        require(IERC721(_creator).ownerOf(ownedTokenID) == msg.sender, "Token must be owned by minter");
        require(ownedTokenID > 8, "Must own a Power token with tokenID > 8");        
        require(_holderMintEnabled, "Holder Mint not active");
        _currentTokenID = IERC721CreatorCore(_creator).mintExtension(msg.sender);
        _currentPowerCounter = _currentTokenID - 8;
        emit TokenMinted(msg.sender, _currentTokenID);
        updatePower();
    }

    function updatePower() private {
        if((_currentPowerCounter)/(8**_currentRarity) >= 1 && (_currentPowerCounter)%(8**_currentRarity)>0){
            _currentRarity++;
        }

        _powers[_currentPowerCounter]=_currentRarity;
    }

    function _wrapRarity(string memory trait, string memory value) public pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"','8^',
            value,
            '"}'
        ));
    }

    function _wrapTrait(string memory trait, string memory value) public pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }


    function buildTokenURI(uint tokenID) public view returns(string memory){
        return string(abi.encodePacked('data:application/json;utf8,',
            '{"name":"Power #',
            Strings.toString(tokenID-8), 
            '","description":',
            '"',_description,'"', 
            ',"attributes":[',
            _wrapRarity("Rarity", Strings.toString(_powers[tokenID-8])),',',
            _wrapTrait("Type", "Power"),
            '],"animation_url":"',
            _animationURI,'","',
            "image_url",'":"',
            _imageURI,
            '"}')
        );
    }

    function tokenURI(address creator, uint256 tokenId) public view override returns(string memory) {
        require(creator == _creator, "Invalid token");
        require(tokenId > 8);
        return buildTokenURI(tokenId);
    }
}