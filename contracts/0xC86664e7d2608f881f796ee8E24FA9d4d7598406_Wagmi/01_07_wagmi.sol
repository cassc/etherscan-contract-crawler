// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "Strings.sol";

contract Wagmi is ERC721A, Ownable {
    using Strings for uint256;

    constructor() ERC721A("WAGMI ARMY", "WAGMI") {}
    string public baseURI = "ipfs://QmbRdiYNb4c1RjgKvGaTDQS486uJr6UPGqU3H2bsAnGxH5?";
    
    bytes32 public WLmerkleRoot = 0xbcd5081af6b1237d12b47892e081920f44ad3187fa0dc4bc387f893b6498e435;
    bytes32 public OGmerkleRoot = 0x23eee02d95abb8dcace9f769cc74ef8cf85078c8770655161cb692a38a76e195;

    uint public MAX_WAGMIS = 10000;
    
    uint public WLStartTime = 1657216800;
    uint public PublicStartTime = 9999999999;

    mapping(address => bool) public usedWL;
    mapping(address => bool) public usedOG;
    mapping(address => bool) public usedMinted;

    bool public WHITELIST_STARTED = false;

    uint public totalWagmis = 0;

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
        require(totalWagmis + 1 < MAX_WAGMIS, "All WAGMIS have already been minted!");
        require(MerkleProof.verify(_proof,WLmerkleRoot,keccak256(abi.encodePacked(msg.sender))),"Invalid proof.");
        require(!usedWL[msg.sender],"Proof already used");
        _safeMint(msg.sender, 1);

        usedWL[msg.sender] = true;
        totalWagmis++;
    }

    function OGwhitelistMint(bytes32[] calldata _proof) public {
        require(block.timestamp >= WLStartTime, "Sale not started");
        require(totalWagmis + 1 < MAX_WAGMIS, "All WAGMIS have already been minted!");
        require(MerkleProof.verify(_proof,OGmerkleRoot,keccak256(abi.encodePacked(msg.sender))),"Invalid proof.");
        require(!usedOG[msg.sender],"Proof already used");
        _safeMint(msg.sender, 2);

        usedOG[msg.sender] = true;
        totalWagmis += 2;
    }
    
    function mint() public {
        require(tx.origin == msg.sender, "Origin mismatch");
        require(block.timestamp >= PublicStartTime, "Sale not started");
        require(totalWagmis + 1 < MAX_WAGMIS, "All WAGMIS have already been minted!");
        require(!usedMinted[msg.sender],"1 per wallet");
        _safeMint(msg.sender, 1);

        usedMinted[msg.sender] = true;
        totalWagmis ++;
    }

    function ownerMint(uint amount) public onlyOwner {
        require(totalWagmis + amount < MAX_WAGMIS, "All WAGMIS have already been minted!");
        _safeMint(msg.sender,amount);
        totalWagmis += amount;
    }

}