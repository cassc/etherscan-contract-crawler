// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
     
contract SmallCuteCat is ERC721A, Ownable
{
    using Strings for string;

    uint16 public PUBLIC_LIMIT = 2;
    uint16 public WHITELIST_LIMIT = 2;
    uint16 public MAX_SUPPLY = 1000;
    uint256 public WHITELIST_PRICE = 50000000000000000;
    uint256 public PUBLIC_PRICE = 75000000000000000;
    
    bool public revealed = false;
    bool public saleIsActive = false;

    string private _baseTokenURI;
    string public notRevealedUri;
    bytes32 wroot;
    mapping(address => uint16) public addressMintedBalance;

    constructor() ERC721A("Small Cute Cat", "SCC") {}

    function publicSaleMint(uint16 amount) external payable
    {
        require(saleIsActive, "Sale is not active");
        require(addressMintedBalance[msg.sender] + amount <= PUBLIC_LIMIT, "Max NFT per address exceeded");
        require(totalSupply() + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(msg.value >= PUBLIC_PRICE * amount, "Not enough ETH for this transaction");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function whitelistMint(uint16 amount, bytes32[] memory proof) external payable
    {
        require(saleIsActive, "Sale is not active");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, wroot, leaf), "Address not whitelisted");
        require(addressMintedBalance[msg.sender] + amount <= WHITELIST_LIMIT, "Max NFT per address exceeded");
        require(totalSupply() + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(msg.value >= WHITELIST_PRICE * amount, "Not enough ETH for this transaction");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function adminMint(address to, uint16 amount) external onlyOwner 
    {
        _safeMint(to, amount); 
    }

    function setPublicPrice(uint256 newPrice) external onlyOwner 
    {
        PUBLIC_PRICE = newPrice;
    }

    function setWhitelistPrice(uint256 newPrice) external onlyOwner 
    {
        WHITELIST_PRICE = newPrice;
    }


    function setPublicLimit(uint16 newLimit) external onlyOwner 
    {
        PUBLIC_LIMIT = newLimit;
    }

    function setWhitelistLimit(uint16 newLimit) external onlyOwner 
    {
        WHITELIST_LIMIT = newLimit;
    }

    function setSupply(uint16 newSupply) external onlyOwner 
    {
        MAX_SUPPLY = newSupply;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function flipRevealState() public onlyOwner {
        revealed = !revealed;
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }
    
    function setWRoot(bytes32 _root) external onlyOwner
    {
        wroot = _root;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
  
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false) 
        {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }

    function withdraw() external onlyOwner
    {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}