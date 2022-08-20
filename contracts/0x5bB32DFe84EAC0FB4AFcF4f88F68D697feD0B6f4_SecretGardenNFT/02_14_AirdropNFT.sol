//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract AirdropNFT is ERC721, IERC2981 {

    uint256 public totalDropped;
    address private royaltyContract;
    address public owner;
    string private customBaseURI;

    constructor(address royaltyContract_, string memory customBaseURI_, string memory tokenName, string memory tokenSymbol) 
        ERC721(tokenName, tokenSymbol) 
    {
        royaltyContract = royaltyContract_;
        customBaseURI = customBaseURI_;
        owner = msg.sender;
    }

    function drop(address to)
        public
    {
        require(msg.sender == owner, "only owner");
        uint256 _totalDropped = ++totalDropped;
        _mint(to, _totalDropped);
    }

    function dropMany(address[] memory to)
        public
    {
        require(msg.sender == owner, "only owner");
        for (uint i = 0; i < to.length; i++) {
             uint256 _totalDropped = ++totalDropped;
            _mint(to[i], _totalDropped); 
        }
    }

     /**********
        supported interfaces 
    */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721, IERC165) returns (bool) 
    {   
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /***********
        IERC2981 interface
    */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        override
        view
        returns (address receiver, uint256 royaltyAmount) 
    {    
        royaltyAmount = (salePrice * 1000) / 10000;
        receiver = royaltyContract;

        return (receiver, royaltyAmount);
    }

     /*****************
        token uri
    */
    function baseTokenURI() 
        public 
        view 
        returns (string memory) 
    {
        return customBaseURI;
    }

    function setBaseURI(string memory customBaseURI_) 
        external 
    {
        require(msg.sender == owner, "only owner");
        customBaseURI = customBaseURI_;
    }

    function _baseURI() 
        internal 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        return customBaseURI;
    }
}