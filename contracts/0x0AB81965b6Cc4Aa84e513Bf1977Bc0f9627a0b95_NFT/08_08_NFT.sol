// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solmate/src/tokens/ERC721.sol";
import '@solmate/src/utils/ReentrancyGuard.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error NonTransferrable();

contract NFT is ERC721, Ownable, ReentrancyGuard {
    uint256 public currentTokenId;



    mapping(address => uint256) public userOwnedTokens;

    // ========Governance========
    string private baseTokenURI;
    bytes32 public merkleRoot;

    constructor(bytes32 _merkleRoot) ERC721("Canonicon", "JPG") {
        baseTokenURI = "https://arweave.net/someHash/";
        merkleRoot = _merkleRoot;
    }

    // ========Admin========
    mapping(address => bool) public admins;

    modifier onlyAdmin() {
        require(owner() == msg.sender || admins[msg.sender], "Must be an admin");
        _;
    }

    function toggleAdmin(address _address) external onlyOwner {
        admins[_address] = !admins[_address];
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyAdmin {
        merkleRoot = _merkleRoot;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyAdmin {
        baseTokenURI = _baseTokenURI;
    }

    function setMintCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // ========Soulbound========
    function transferFrom(address from, address to, uint256 id) public pure override {
        revert NonTransferrable();
    }

    function safeTransferFrom(address from, address to, uint256 id) public pure override {
        revert NonTransferrable();
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public pure override {
        revert NonTransferrable();
    }

    // ========Minting========
    uint256 public cost = 0;

    function allowlisted(address _wallet, bytes32[] calldata _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_wallet)));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = baseTokenURI;
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    modifier onlyAllowlisted(bytes32[] calldata _proof) {
        require(allowlisted(msg.sender, _proof), "Not allowlisted");
        _;
    }

    modifier mintCompliance() {
        require(balanceOf(msg.sender) == 0, "only 1 per wallet");
        require(msg.value == cost, "Not enough ETH sent");
        _;
    }

    function mint(bytes32[] calldata _proof) external payable onlyAllowlisted(_proof) nonReentrant mintCompliance {
        uint256 newTokenId = ++currentTokenId;
        userOwnedTokens[msg.sender] = newTokenId;
        _safeMint(msg.sender, newTokenId);
    }
}