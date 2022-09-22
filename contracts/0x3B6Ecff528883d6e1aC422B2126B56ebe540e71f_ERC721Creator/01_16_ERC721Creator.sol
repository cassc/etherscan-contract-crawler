// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./library/UintSet.sol";
import "./library/Mintable.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/**
 * @title ERC721Creator contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 * Optimized to use as less gas as possible.
 * @author @FrankNFT.eth
 * 
 */
//////////////////////////////////////////////
//                                          //
//   ______ _____   _____ ______ ___  __    //
//  |  ____|  __ \ / ____|____  |__ \/_ |   //
//  | |__  | |__) | |        / /   ) || |   //
//  |  __| |  _  /| |       / /   / / | |   //
//  | |____| | \ \| |____  / /   / /_ | |   //
//  |______|_|  \_\\_____|/_/   |____||_|   //
//                                          //
//////////////////////////////////////////////

contract ERC721Creator is ERC721, ERC721URIStorage, ERC721Burnable, Mintable {
    using UintSet for UintSet.Set;

    uint256 private _lastTokenId;
    uint256 public percentageRoyalty;

    string private _baseTokenURI = "ipfs://";

    mapping(uint256 => address) private tokenCreators;
    address public receiver;

    constructor() ERC721("FrankNFT Honorary Tokens", "FHT") {
        percentageRoyalty = 1000; // 10%
        receiver = owner();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
    * Royalties implementation.
    *
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        bytes4 _ERC165_ = 0x01ffc9a7;
        bytes4 _ERC721_ = 0x80ac58cd;
        bytes4 _EIP2981_ = 0x2a55205a;
        bytes4 _ERC721Metadata_ = 0x5b5e139f;
        return interfaceId == _ERC165_ 
            || interfaceId == _ERC721_
            || interfaceId == _EIP2981_
            || interfaceId == _ERC721Metadata_;
    }

    /**
    * @dev Set the Royalty % for ALL tokens in this contract.
    */
    function setRoyaltyBips(uint256 percentageRoyalty_) external onlyOwner {
        require(percentageRoyalty_ <= 10000, "ERC721Creator: Illegal argument more than 100%");
        percentageRoyalty = percentageRoyalty_;
    }

    function royaltyInfo(uint256 , uint256 salePrice) external view returns (address, uint256) {
        uint256 royaltyAmount = (salePrice * percentageRoyalty) / 10000;
        return (receiver, royaltyAmount);
    }

    /**
    * @dev set the Royaty reciever for ALL tokens of this contract.
    */
    function setRoyaltyReceiver(address receiver_) external onlyOwner {  
        receiver = receiver_;
    }

    /**
     * @dev Set the base token URI
     */
    function setBaseTokenURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }


    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        require(exists(tokenId),"ERC721Creator: Token does not exists.");
        super._burn(tokenId);
        delete tokenCreators[tokenId];

    }

    /**
    * Returns the creator for a given TokenID.
    */
    function tokenCreator(uint256 tokenId) public view  returns (address) {
        return tokenCreators[tokenId];
    }

    /**
     * Returns the URI for a specific Token.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Mints a NEW Token.
     * Only allowed for adresses that have the minter role.
     */
    function mint(string memory _tokenURI) external onlyMinter
    {
        require(bytes(_tokenURI).length != 0, "ERC721Creator: Missing tokenURI");
        _lastTokenId += 1;
        _safeMint(owner(), _lastTokenId);
        _setTokenURI(_lastTokenId, _tokenURI);
        tokenCreators[_lastTokenId] = msg.sender;
    }

        /**
     * @dev Mints a NEW Token.
     * Only allowed for adresses that have the minter role.
     */
    function mint(string memory _tokenURI, address to) external onlyMinter
    {
        require(bytes(_tokenURI).length != 0, "ERC721Creator: Missing tokenURI");
        _lastTokenId += 1;
        _safeMint(to, _lastTokenId);
        _setTokenURI(_lastTokenId, _tokenURI);
        tokenCreators[_lastTokenId] = msg.sender;
    }
    /**
     * @dev allows to update the metadata of a token.
     * Only allowed for adresses that have the minter role AND are the creator/contractOwner of the token.
     * Only allowed if you still Own the token.
     */
    function updateTokenURI(uint256 tokenID, string memory _tokenURI) external onlyMinter{
        require(bytes(_tokenURI).length != 0, "ERC721Creator: Missing tokenURI.");
        require(exists(tokenID),"ERC721Creator: Token does not exists.");
        require(msg.sender==tokenCreator(tokenID) || msg.sender==owner(),"ERC721Creator: Token not created by you.");
        require(ownerOf(tokenID) == msg.sender,"ERC721Creator: You are not token owner.");
        _setTokenURI(tokenID, _tokenURI);
    }
    
    /**
     * @dev Indicates weither any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return tokenCreators[id] != address(0);
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _lastTokenId;
    }
}