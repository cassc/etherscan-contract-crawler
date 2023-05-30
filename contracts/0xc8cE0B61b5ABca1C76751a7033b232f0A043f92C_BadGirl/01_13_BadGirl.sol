// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract BadGirl is ERC721A, Ownable {
    bool public locked = false;
    uint32 public PRE_SALE_START_DATE = 1651496390;
    uint32 public PUBLIC_SALE_DATE = 1651498190;
    uint256 public DISCOUNT_MINT_PRICE = 0.04 ether;
    uint256 public PUBLIC_MINT_PRICE = 0.05 ether;
    uint256 public MAX_SUPPLY = 3333;
    uint256 public MAX_MINT_PER_ADDR = 5;
    string public baseURI = "https://badgirls.app/.netlify/functions/nft/";
    uint256 public mintedCount = 0;

    bytes32 public highOrderMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    mapping(address => uint256) public highOrderMintCnt;
    mapping(address => uint256) public whitelistMintCnt;


    constructor(bytes32 highOrder, bytes32 whitelist) ERC721A("Bad Girl", "BG") {
        // to the deployer 
        highOrderMerkleRoot = highOrder;
        whitelistMerkleRoot = whitelist;

        _safeMint(msg.sender, 1);
    }

    function setMerkleRoot (bytes32 highOrder, bytes32 whitelist) public onlyOwner {
        highOrderMerkleRoot = highOrder;
        whitelistMerkleRoot = whitelist;
    }

    function getTreeLeaf() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender));
    }

    function airdrop (address[] calldata addrs, uint[] calldata amounts) public onlyOwner {
        for (uint i = 0; i < addrs.length; ++i) {
            _safeMint(addrs[i], amounts[i]);
            mintedCount += amounts[i];
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function toggleLock() public onlyOwner {
        locked = !locked;
    }

    modifier isValidMerkleProof( bytes32[] calldata merkleProof, bytes32 root, bytes32 leaf) {
        require( 
            MerkleProof.verify( merkleProof, root, leaf),
            "Address does not exist in whitelist !"
        );
        _;
    }

    function highOrderMint (bytes32[] calldata merkleProof, uint256 amount)
        public payable
        isValidMerkleProof(merkleProof, highOrderMerkleRoot, getTreeLeaf())
    {
        require(!locked, "mint entry closed !");
        require(block.timestamp >= PRE_SALE_START_DATE, "Whitelist mint has not yet started!");
        require(
            highOrderMintCnt[msg.sender] + amount <= 3,
            "Only allow to mint 3 at whitelist mint stage !"
        );

        require(
            numberMinted(msg.sender) + amount <= MAX_MINT_PER_ADDR,
            "A single wallet can at most mint 5 !"
        );

        require(mintedCount + amount <= MAX_SUPPLY, "Exceeded max mint range");

        uint256 totalPrice = DISCOUNT_MINT_PRICE * amount;
        require(msg.value >= totalPrice, "Insufficient eth");

        (bool sent, ) = owner().call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        _safeMint(msg.sender, amount);
        highOrderMintCnt[msg.sender] += amount;
        mintedCount += amount;
    }

    function whitelistMint (bytes32[] calldata merkleProof, uint256 amount)
        public payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot, getTreeLeaf())
    {
        require(!locked, "mint entry closed !");
        require(block.timestamp >= PRE_SALE_START_DATE, "Whitelist mint has not yet started!");
        require(
            whitelistMintCnt[msg.sender] + amount <= 2,
            "Only allow to mint 2 in whitelist mint stage !"
        );

        require(
            numberMinted(msg.sender) + amount <= MAX_MINT_PER_ADDR,
            "A single wallet can at most mint 5 !"
        );

        require(mintedCount + amount <= MAX_SUPPLY, "Exceeded max mint range");

        uint256 totalPrice = PUBLIC_MINT_PRICE * amount;
        require(msg.value >= totalPrice, "Insufficient eth");

        (bool sent, ) = owner().call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        _safeMint(msg.sender, amount);
        whitelistMintCnt[msg.sender] += amount;
        mintedCount += amount;
    }


    function batchMint(uint256 amount) public payable {
        require(!locked, "mint entry closed !");
        require(block.timestamp >= PUBLIC_SALE_DATE, "Public mint has not yet started!");
        require(
            numberMinted(msg.sender) + amount <= MAX_MINT_PER_ADDR,
            "A single wallet can at most mint 5 !"
        );
        require(mintedCount + amount <= MAX_SUPPLY, "Exceeded max mint range");

        uint256 totalPrice = PUBLIC_MINT_PRICE * amount;
        require(msg.value >= totalPrice, "Insufficient eth");

        (bool sent, ) = owner().call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        _safeMint(msg.sender, amount);
        mintedCount += amount;
    }
}