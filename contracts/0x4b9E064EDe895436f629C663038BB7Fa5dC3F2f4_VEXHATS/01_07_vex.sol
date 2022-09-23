// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract VEXHATS is Ownable, ERC721A {
    using Strings for uint256;
    using ECDSA for bytes32;
    // Addresses
    address public sender = 0xA65aae78EdEF916d4102BA7b5672068C0D35fbff;
    address private addressWithdraw;
    // Sales configs
    uint256 public maxSupply = 150;
    uint256 public maxPerAddress = 3;
    // Timeframes
    uint256 public windowOpens = 1655918414;
    // Metadata uris
    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmSdmrEAvGwGmXNmusFR7XoCoM7xMa62t1snW33YS188gA/";
    // Amount minted at phases
    mapping(uint256 => uint256) public tokenIdsUris;
    
    constructor(
    // string memory _baseURI,
    address _addressWithdraw
    ) ERC721A("VEX Hats", "VEX Hats") {
        addressWithdraw = _addressWithdraw;
    }

    modifier onlySender() {
        require((msg.sender == sender) || (msg.sender == owner()), "Only sender can use giveaway function.");
        _;
    }

    function mint(uint256 quantity, uint256 id, bytes calldata signature) external payable {
        require(block.timestamp >= windowOpens, "Purchase window closed.");
        require(verifySignature(signature), "Account not eligible for claim.");
        require(totalSupply() + quantity <= maxSupply, "This amount of tokens would surpass the max supply.");
        require(id < 3, "There isn't token id 3+");
        require(quantity + _numberMinted(msg.sender) <= maxPerAddress, "User already minted max per address");

        tokenIdsUris[totalSupply()] = id;
        _mint(msg.sender, quantity);
    }

    function giveaway(address to, uint256 id, uint256 quantity) external onlySender {
        require(totalSupply() + quantity <= maxSupply, "This amount of tokens would surpass the max supply.");
        require(quantity + _numberMinted(to) <= maxPerAddress, "User already minted max per address");
        
        tokenIdsUris[totalSupply()] = id;
        _mint(to, quantity);
    }

    function ownerMint(address to, uint256 id, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "This amount of tokens would surpass the max supply.");

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

    function verifySignature(bytes calldata signature) internal view returns (bool) {
        return sender == keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(this, msg.sender, msg.value)))).recover(signature);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = addressWithdraw.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}