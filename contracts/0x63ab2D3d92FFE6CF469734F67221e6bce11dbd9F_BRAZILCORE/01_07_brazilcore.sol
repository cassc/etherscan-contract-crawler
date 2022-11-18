// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BRAZILCORE is Ownable, ERC721A {
    using Strings for uint256;
    using ECDSA for bytes32;
    // Addresses
    address public sender = 0xA65aae78EdEF916d4102BA7b5672068C0D35fbff;
    address public crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;
    address private addressWithdraw = 0xd29eeEF7d210a4cB65CaC432662F8C56f4112Ccb;
    // Sales configs
    uint256 public maxSupply = 19;
    uint256 public maxPerAddress = 5;
    // Timeframes
    uint256 public windowOpens = 1668718800;
    // Metadata uris
    string public baseURI = "https://55unity.mypinata.cloud/ipfs/QmYbNTrQNfENCqDmsPtYp5JeE6guwrcyoLHyyvBcERABAo/";
    // Amount minted at phases
    mapping(uint256 => uint256) public tokenIdsUris;
    
    constructor(
    ) ERC721A("Brazil Core by VEX", "Brazil Core by VEX") {
    }

    modifier onlySender() {
        require((msg.sender == sender) || (msg.sender == owner()), "Only sender can use giveaway function.");
        _;
    }

    function mint(uint256 quantity, uint256 id, bytes calldata signature) external payable {
        require(block.timestamp >= windowOpens, "Purchase window closed.");
        require(verifySignature(signature, msg.sender), "Account not eligible for claim.");
        require(totalSupply() + quantity <= maxSupply, "This amount of tokens would surpass the max supply.");
        require(quantity + _numberMinted(msg.sender) <= maxPerAddress, "User already minted max per address");

        tokenIdsUris[totalSupply()] = id;
        _mint(msg.sender, quantity);
    }

    function crossmint(address to, address user, uint256 quantity, uint256 id, bytes calldata signature) external payable  {
        require(block.timestamp >= windowOpens, "Purchase window closed.");
        require(msg.sender == crossmintAddress, "This function is for Crossmint only.");
        require(verifySignature(signature, user), "Account not eligible for claim.");
        require(totalSupply() + quantity <= maxSupply, "This amount of tokens would surpass the max supply.");
        require(quantity + balanceOf(user) <= maxPerAddress, "User already minted max per address");

        tokenIdsUris[totalSupply()] = id;
        _mint(to, quantity);
    }

    function giveaway(address to, uint256 id, uint256 quantity) external onlySender {
        require(totalSupply() + quantity <= maxSupply, "This amount of tokens would surpass the max supply.");
        require(quantity + _numberMinted(to) <= maxPerAddress, "User already minted max per address");
        
        for (uint256 index = 0; index < quantity; index++) {
            tokenIdsUris[totalSupply() + index] = id;
        }

        _mint(to, quantity);
    }
    
    // Uri token functions
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");    

        return string(abi.encodePacked(baseURI, tokenIdsUris[tokenId].toString(), ".json"));  
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // Functions to change contract settings
    function setMaxSupply( uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

        // Functions to change contract settings
    function setMaxPerAddress( uint256 _max) external onlyOwner {
        maxPerAddress = _max;
    }
    
    function setWindows(uint256 _windowOpens)  external onlyOwner {
        windowOpens = _windowOpens;
    }

    function verifySignature(bytes calldata signature, address to) internal view returns (bool) {
        return sender == keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(this, to, msg.value)))).recover(signature);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = addressWithdraw.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}