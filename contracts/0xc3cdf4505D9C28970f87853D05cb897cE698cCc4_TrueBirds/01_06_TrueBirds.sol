// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TrueBirds is ERC721A , Ownable{
    using Strings for uint256;

    string private uriPrefix = "https://gateway.pinata.cloud/ipfs/QmPuoWATPEz59ujix5zYxVNEosjs1fM4iVHbE3xLeqyibz/";
    string public uriSuffix=".json";
    uint256 public cost = 0.005 ether;
    uint256 public maxSupply = 317;
    uint256 public maxMint = 5;
    uint256 public totalMaxMint = 5;
    uint256 public freeMaxMintAmount = 0;
    bool public paused = false;
    bool public publicSale = true;
    
    mapping(address => uint256) public addressMintedBalance;

    constructor () ERC721A("True Birds", "HOOT") {}

    modifier mintVerification(uint256 _mintAmount){
        if(msg.sender != owner()) {
            require(_mintAmount > 0 && _mintAmount <= maxMint, 'Invalid mint amount');
        }
        require(totalSupply() + _mintAmount <= maxSupply, 'Max Suppley exceeded!');
        _;
    }

    modifier mintPriceVerification(uint256 _mintAmount){
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];

        if(ownerMintedCount >= freeMaxMintAmount){
            require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
        }
        _;
    }

    function mint(uint256 _mintAmount) public payable mintVerification(_mintAmount) mintPriceVerification(_mintAmount) {
        require(!paused , 'The contract is paused');
        require(publicSale, "Not open to public yet");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];

        if(ownerMintedCount < freeMaxMintAmount) {
            require(ownerMintedCount + _mintAmount <= freeMaxMintAmount, "Exceeded Free Mint Limit");
        } else if(ownerMintedCount >= freeMaxMintAmount){
            require(ownerMintedCount + _mintAmount <= totalMaxMint, "Exceeded Mint Limit");
        }

        _safeMint(msg.sender, _mintAmount);
        for (uint256 i = 1; i <= _mintAmount; i++){
            addressMintedBalance[msg.sender]++;
        }
    }

    function ownerMint(uint256 _mintAmount) public payable onlyOwner{
        require(_mintAmount > 0 , "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded");
        _safeMint(msg.sender, _mintAmount);
    }
    

    function mintForAddress(uint256 _mintAmount, address _receiver) public mintVerification(_mintAmount) onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : '';
    }

    function setFreeMax(uint256 _amount) public onlyOwner{
        freeMaxMintAmount = _amount;
    }
    
    function setCost(uint256 _cost) public onlyOwner{
        cost = _cost;
    }

    function setTotalMintMax(uint256 _amount) public onlyOwner{
        maxMint = _amount;
    }

    function setUriPreffix(string memory _uriPreffix) public onlyOwner{
        uriPrefix = _uriPreffix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner{
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner{
        paused = _state;
    }

    function setPublicSale(bool _state) public onlyOwner{
        publicSale = _state;
    }

    function withdraw() public payable onlyOwner {
  
        (bool os, ) = payable(owner()).call{value: address(this).balance}(""); 
        require(os);
   
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}