// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";


//░██╗░░░░░░░██╗░█████╗░██████╗░██╗░░░░░██████╗░  ░█████╗░███████╗  ░█████╗░██╗░░░░░██╗██████╗░██╗░█████╗░
//░██║░░██╗░░██║██╔══██╗██╔══██╗██║░░░░░██╔══██╗  ██╔══██╗██╔════╝  ██╔══██╗██║░░░░░██║██╔══██╗██║██╔══██╗
//░╚██╗████╗██╔╝██║░░██║██████╔╝██║░░░░░██║░░██║  ██║░░██║█████╗░░  ███████║██║░░░░░██║██║░░██║██║███████║
//░░████╔═████║░██║░░██║██╔══██╗██║░░░░░██║░░██║  ██║░░██║██╔══╝░░  ██╔══██║██║░░░░░██║██║░░██║██║██╔══██║
//░░╚██╔╝░╚██╔╝░╚█████╔╝██║░░██║███████╗██████╔╝  ╚█████╔╝██║░░░░░  ██║░░██║███████╗██║██████╔╝██║██║░░██║
//░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚═╝╚══════╝╚═════╝░  ░╚════╝░╚═╝░░░░░  ╚═╝░░╚═╝╚══════╝╚═╝╚═════╝░╚═╝╚═╝░░╚═╝
//                                       ORIGINAL DESING BY: FANNY SCHULTZ 

contract WorldOfAlidia is ERC721A, Ownable 
{

    uint public constant MAX_TOKENS = 10000;
    uint public constant NUMBER_RESERVED_TOKENS = 5300;
    uint256 public PRICE = 0.1 ether;
    uint public perAddressLimit = 30;
    
    bool public saleIsActive = false;
    bool public whitelist = true;
    bool public revealed = false;

    uint public reservedTokensMinted = 0;
    string private _baseTokenURI;
    string public notRevealedUri = "ipfs://QmVhmmnyfqoyEpRbgGPuiUko1WRCFiHpaQuCaUsPmmHRn7";
    bytes32 root = 0xee086917ca4b626a1f6c2e88f54e1c5b9c87928b9d351b73bcc40d282700806e;
    mapping(address => uint) public addressMintedBalance;

    address payable private devgirl = payable(0x810ad66bC6ecbA0b9E16CFC727C522a41c810F83);

    constructor() ERC721A("World of Alidia", "WoA") {}

    function mintToken(uint256 amount, bytes32[] memory proof) external payable
    {
        require(!whitelist || verify(proof), "Address not whitelisted");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        if (whitelist) {
            require(addressMintedBalance[msg.sender] + amount <= perAddressLimit, "Max NFT per address exceeded"); 
            addressMintedBalance[msg.sender] += amount;
        }
        _safeMint(msg.sender, amount);
    }

    function mintTo(address to, uint256 amount) external payable 
    {
        address crossmint_eth = 0xdAb1a1854214684acE522439684a145E62505233;
        require(msg.sender == crossmint_eth,"This function can be called by the Crossmint address only.");
        require(!whitelist, "Whitelist is still active");
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        _safeMint(to, amount);
    }

    function setPrice(uint256 newPrice) external onlyOwner 
    {
        PRICE = newPrice;
    }

    function setPerAddressLimit(uint newLimit) external onlyOwner 
    {
        perAddressLimit = newLimit;
    }

    function reveal() public onlyOwner 
    {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner 
    {
        notRevealedUri = _notRevealedURI;
    }

    function flipSaleState() external onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }

    function flipWhitelistingState() external onlyOwner 
    {
        whitelist = !whitelist;
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");
        reservedTokensMinted += amount;
        _safeMint(to, amount);
    }

    function withdraw() external 
    {
        require(msg.sender == devgirl || msg.sender == owner(), "Invalid sender");
        uint part1 = address(this).balance / 100 * 1;
        devgirl.transfer(part1);
        payable(owner()).transfer(address(this).balance);
    }

    function setRoot(bytes32 _root) external onlyOwner
    {
        root = _root;
    }

    function getRoot() external view returns (bytes32)
    {
        return root;
    }

    function verify(bytes32[] memory proof) internal view returns (bool) 
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }
    
    function _setBaseURI(string memory baseURI) internal virtual 
    {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) 
    {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner 
    {
        _setBaseURI(baseURI);
    }
  
    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}