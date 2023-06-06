// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BossyBaddies is ERC721A, Ownable
{
    // using Strings for string;

    uint16 public constant MAX_TOKENS = 2222;
    uint16 public PRESALE_LIMIT = 2222;
    uint16 public presaleTokensSold = 0;
    uint16 public constant NUMBER_RESERVED_TOKENS = 50;
    uint256 public PRICE = 100000000000000000; //0.1 eth
    uint16 public perAddressLimit = 2;
    
    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    bool public whitelist = true;
    bool public revealed = false;

    uint16 public reservedTokensMinted = 0;
    string private _baseTokenURI;
    string public notRevealedUri;
    bytes32 root;
    mapping(address => uint16) public addressMintedBalance;

    constructor() ERC721A("Bossy Baddies", "BBS") {}

    function mintToken(uint16 amount, bytes32[] memory proof) external payable
    {
        require(preSaleIsActive || saleIsActive, "Sale must be active to mint");

        require(!preSaleIsActive || presaleTokensSold + amount <= PRESALE_LIMIT, "Purchase would exceed max supply");
        require(!preSaleIsActive || addressMintedBalance[msg.sender] + amount <= perAddressLimit, "Max NFT per address exceeded");
        require(!whitelist || verify(proof), "Address not whitelisted");
        
        require(amount > 0 && amount <= 5, "Max 5 NFTs per transaction");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        
        if (preSaleIsActive) {
            presaleTokensSold += amount;
            addressMintedBalance[msg.sender] += amount;
        }

        _safeMint(msg.sender, amount);
    }

    //case ethereum does something crazy
    function setPrice(uint256 newPrice) external onlyOwner 
    {
        PRICE = newPrice;
    }

    function setPresaleLimit(uint16 newLimit) external onlyOwner 
    {
        PRESALE_LIMIT = newLimit;
    }

    function setPerAddressLimit(uint16 newLimit) external onlyOwner 
    {
        perAddressLimit = newLimit;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function flipSaleState() external onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() external onlyOwner 
    {
        preSaleIsActive = !preSaleIsActive;
    }

    function flipWhitelistingState() external onlyOwner 
    {
        whitelist = !whitelist;
    }

    function mintReservedTokens(address to, uint16 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        reservedTokensMinted += amount;
        _safeMint(to, amount); 
    }
    
    function withdraw() external onlyOwner
    {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function setRoot(bytes32 _root) external onlyOwner
    {
        root = _root;
    }

    function verify(bytes32[] memory proof) internal view returns (bool) 
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }
    
    ////
    //URI management part
    ////
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
}