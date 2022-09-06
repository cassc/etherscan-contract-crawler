// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
     
contract MonsterSuitPx is ERC721A, Ownable
{
    using Strings for string;

    uint16 public LIMIT = 4;
    uint16 public MAX_SUPPLY = 2500;
    uint256 public WHITELIST_PRICE = 75000000000000000;
    uint256 public PRICE = 75000000000000000;
    
    bool public revealed = false;
    bool public freeMintIsActive = false;
    bool public whitelistSaleIsActive = false;
    bool public saleIsActive = false;

    string private _baseTokenURI;
    string public notRevealedUri;
    bytes32 aroot;
    bytes32 broot;
    bytes32 croot;
    bytes32 droot;
    bytes32 wroot;
    mapping(address => uint16) public addressMintedBalance;

    constructor() ERC721A("Monster Suit Px", "MSPX") {}

    function freeAMint(uint16 amount, bytes32[] memory proof) external
    {
        require(freeMintIsActive, "Free mint is not active");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, aroot, leaf), "Address not whitelisted");
        require(addressMintedBalance[msg.sender] + amount <= 4, "Max NFT per address exceeded");
        require(totalSupply() + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function freeBMint(uint16 amount, bytes32[] memory proof) external
    {
        require(freeMintIsActive, "Free mint is not active");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, broot, leaf), "Address not whitelisted");
        require(addressMintedBalance[msg.sender] + amount <= 3, "Max NFT per address exceeded");
        require(totalSupply() + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }
    
    function freeCMint(uint16 amount, bytes32[] memory proof) external
    {
        require(freeMintIsActive, "Free mint is not active");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, croot, leaf), "Address not whitelisted");
        require(addressMintedBalance[msg.sender] + amount <= 2, "Max NFT per address exceeded");
        require(totalSupply() + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function freeDMint(uint16 amount, bytes32[] memory proof) external
    {
        require(freeMintIsActive, "Free mint is not active");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, droot, leaf), "Address not whitelisted");
        require(addressMintedBalance[msg.sender] + amount <= 1, "Max NFT per address exceeded");
        require(totalSupply() + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function whitelistMint(uint16 amount, bytes32[] memory proof) external payable
    {
        require(whitelistSaleIsActive, "Sale is not active");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, wroot, leaf), "Address not whitelisted");
        require(addressMintedBalance[msg.sender] + amount <= LIMIT, "Max NFT per address exceeded");
        require(totalSupply() + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(msg.value >= WHITELIST_PRICE * amount, "Not enough ETH for this transaction");
        require(msg.sender == tx.origin, "Transaction from smart contract not allowed");
        
        addressMintedBalance[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function mint(uint16 amount) external payable
    {
        require(saleIsActive, "Sale is not active");
        require(addressMintedBalance[msg.sender] + amount <= LIMIT, "Max NFT per address exceeded");
        require(totalSupply() + amount <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for this transaction");
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
        PRICE = newPrice;
    }

    function setWhitelistPrice(uint256 newPrice) external onlyOwner 
    {
        WHITELIST_PRICE = newPrice;
    }

    function setLimit(uint16 newLimit) external onlyOwner 
    {
        LIMIT = newLimit;
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

    function flipFreeMintState() external onlyOwner
    {
        freeMintIsActive = !freeMintIsActive;
    }

    function flipWhitelistSaleState() external onlyOwner
    {
        whitelistSaleIsActive = !whitelistSaleIsActive;
    }

    function flipSaleState() external onlyOwner
    {
        saleIsActive = !saleIsActive;
    }

    function setARoot(bytes32 _root) external onlyOwner
    {
        aroot = _root;
    }

    function setBRoot(bytes32 _root) external onlyOwner
    {
        broot = _root;
    }

    function setCRoot(bytes32 _root) external onlyOwner
    {
        croot = _root;
    }

    function setDRoot(bytes32 _root) external onlyOwner
    {
        droot = _root;
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