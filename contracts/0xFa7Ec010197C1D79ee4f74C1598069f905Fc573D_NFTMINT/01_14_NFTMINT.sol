// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";



contract NFTMINT is ERC721, ERC721Burnable, Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIdCounter;
    using Strings for uint256;
    uint public supply = 10000;
    uint public mintRate = 0.11 ether;
    uint256 limitPerWallet = 20;
    string public uriPrefix = "ipfs://CID-HERE/";
    string public uriSuffix = ".json";


    address payable private owner_;
    constructor()  ERC721("NFT Mint", "NFT") {
        owner_ = payable(msg.sender);  
    }

    function mint(uint256 amount) public payable {
        require(msg.sender != address(0), "Zero address");
        require(balanceOf(msg.sender) + amount <= limitPerWallet, "Limit per wallet exceeded!");
        require(_tokenIdCounter.current() + amount <= supply, "No more tokens left");
        uint256 etherValue = msg.value;
        require (etherValue >= mintRate, "Insufficient balance");
        owner_.transfer(msg.value);
        for (uint i=0; i<amount; i++) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override{
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(
      _exists(_tokenId),
      "Err: ERC721Metadata - URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getTotalMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }
   
}