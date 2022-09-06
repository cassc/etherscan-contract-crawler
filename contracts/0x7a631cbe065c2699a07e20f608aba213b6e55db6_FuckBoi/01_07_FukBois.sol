// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "Strings.sol";

contract FuckBoi is ERC721A, Ownable {
    using Strings for uint256;

    constructor() ERC721A("FUCKBOI", "FUCKBOI") {}
    string public baseURI = "ipfs://QmNxnSj9i3BMSchu5nrGtLP4bQzxa5omZYi5TRTLBLNGJe?";
    
    bytes32 public OGmerkleRoot = 0x761b708fa8f453fd3acae490882a39b5d6effc59704c2fe2c8659cee2c1e3fba;
    bytes32 public WLmerkleRoot = 0x7ea15741348579e387b00eee1d25738c327ee36a96fcb71c0aa3f1aba08e6aa7;

    uint public MAX_FUCKBOIS = 5454;
    
    uint public WLStartTime = 9999999999;
    uint public PublicStartTime = 9999999999;

    mapping(address => bool) public usedWL;
    mapping(address => bool) public usedOG;
    mapping(address => bool) public usedMinted;

    bool public WHITELIST_STARTED = false;

    uint public totalFuckbois = 0;

    function setBaseURI(string memory base) public onlyOwner {
        baseURI = base;
    }
        
    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function setWLStartTime(uint _newWLStartTime) public onlyOwner {
        WLStartTime = _newWLStartTime;
    }

    function setPublicStartTime(uint _newPublicStartTime) public onlyOwner {
        PublicStartTime = _newPublicStartTime;
    }

    function setMerkleRoot(bytes32 _WLroot, bytes32 _OGroot) public onlyOwner {
        WLmerkleRoot = _WLroot;
        OGmerkleRoot = _OGroot;
    }

    function whitelistMint(bytes32[] calldata _proof) public {
        require(block.timestamp >= WLStartTime, "Sale not started");
        require(totalFuckbois + 1 <= MAX_FUCKBOIS, "All FUCKBOIS have already been minted!");
        require(MerkleProof.verify(_proof,WLmerkleRoot,keccak256(abi.encodePacked(msg.sender))),"Invalid proof.");
        require(!usedWL[msg.sender],"Proof already used");
        _safeMint(msg.sender, 1);

        usedWL[msg.sender] = true;
        totalFuckbois++;
    }

    function OGwhitelistMint(bytes32[] calldata _proof) public {
        require(block.timestamp >= WLStartTime, "Sale not started");
        require(totalFuckbois + 1 <= MAX_FUCKBOIS, "All FUCKBOIS have already been minted!");
        require(MerkleProof.verify(_proof,OGmerkleRoot,keccak256(abi.encodePacked(msg.sender))),"Invalid proof.");
        require(!usedOG[msg.sender],"Proof already used");
        _safeMint(msg.sender, 2);

        usedOG[msg.sender] = true;
        totalFuckbois += 2;
    }
    
    function mint() public {
        require(tx.origin == msg.sender, "Origin mismatch");
        require(block.timestamp >= PublicStartTime, "Sale not started");
        require(totalFuckbois + 1 <= MAX_FUCKBOIS, "All FUCKBOIS have already been minted!");
        require(!usedMinted[msg.sender],"1 per wallet");
        _safeMint(msg.sender, 1);

        usedMinted[msg.sender] = true;
        totalFuckbois ++;
    }

    function ownerMint(uint amount) public onlyOwner {
        require(totalFuckbois + amount <= MAX_FUCKBOIS, "All FUCKBOIS have already been minted!");
        _safeMint(msg.sender,amount);
        totalFuckbois += amount;
    }

}