// SPDX-License-Identifier: MIT
// ndgtlft etm.

pragma solidity ^0.8.21;

import { Base64 } from 'base64-sol/base64.sol';
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract KURAGE100 is Ownable, ERC721A, ERC2981, ReentrancyGuard{
    constructor() ERC721A("KURAGE100", "KURAGE") {
        _setDefaultRoyalty(owner(), 1000); //royalty param setting（1000/10000 = 10%）
    }

    string public baseURI = "ipfs://bafybeibxgi7ughchmaoymze5zne2cxplxfcxghvjwuz7u5you4xd3dnw2u/";
    string public baseExtension = ".json";
    uint256 public cost = 2500000000000000; //0.0025eth
    uint256 public maxSupply = 100;
    uint256 public maxMintAmountPerTx = 2;
    uint256 public publicSaleMaxMintAmountPerAddress = 2;
    bool public paused = true;
    uint256 public saleId = 0;    
    mapping(uint256 => mapping(address => uint256)) public userMintedAmount;
    mapping(uint256 => mapping(address => uint256)) public allowlistUserAmount;
 
    //mint
    function mint(uint256 _mintAmount) public payable nonReentrant{
        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmountPerTx, "max mint amount per session exceeded");
        require(_nextTokenId() -1 + _mintAmount <= maxSupply , "max NFT limit exceeded");
        require(cost * _mintAmount <= msg.value, "insufficient funds");
        require(tx.origin == msg.sender, "not externally owned account");
        uint256 maxMintAmountPerAddress;
        maxMintAmountPerAddress = publicSaleMaxMintAmountPerAddress;
        require(_mintAmount <= maxMintAmountPerAddress - userMintedAmount[saleId][msg.sender] , "max NFT per address exceeded");
        userMintedAmount[saleId][msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    //onlyOwner
    function airdropMint(address _airdropAddress , uint256 _mintAmount) public onlyOwner{
        require(0 < _mintAmount , "need to mint at least 1 NFT");
        require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
        _safeMint(_airdropAddress, _mintAmount);
    }

    function setPause(bool _state) public onlyOwner{
        paused = _state;
    }

    function setSaleId(uint256 _saleId) public onlyOwner{
        saleId = _saleId;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner{
        maxSupply = _maxSupply;
    }

    function setPublicSaleMaxMintAmountPerAddress(uint256 _publicSaleMaxMintAmountPerAddress) public onlyOwner{
        publicSaleMaxMintAmountPerAddress = _publicSaleMaxMintAmountPerAddress;
    }

    function setCost(uint256 _newCost) public onlyOwner{
        cost = _newCost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner{
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner{
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner{
        baseExtension = _newBaseExtension;
    }

    function withdraw() public payable onlyOwner{
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function setRoyalty(uint96 _newRoyalty) external onlyOwner{
        _setDefaultRoyalty(owner(), _newRoyalty);
    }

    //view
    function getUserMintedAmountBySaleId(uint256 _saleId , address _address ) public view returns(uint256){
        return userMintedAmount[_saleId][_address];
    }

    function getUserMintedAmount(address _address ) public view returns(uint256){
        return userMintedAmount[saleId][_address];
    }

    //override
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns(bool){
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}