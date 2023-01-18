// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FamePass is ERC721A, Ownable {
    using Address for address;
    using MerkleProof for bytes32[];

    // variables
    string public baseTokenURI;
    uint256 public mintPrice = 0 ether;
    uint256 public collectionSize = 8888;
    uint256 public publicMintMaxSupply = 1000;
    uint256 public whitelistMintMaxSupply = 6400;
    uint256 public reservedSize = 250;
    uint256 public maxItemsPerTx = 2;
    uint256 public maxItemsPerTxForXlist = 3;

    bool public whitelistMintPaused = true;
    bool public publicMintPaused = true;
	//first whitelist
    bytes32 whitelistMerkleRoot; 
	//new entered in whitelist
    bytes32 XlistMerkleRoot;

    mapping(address => uint256) public whitelistMintedAmount;

    // events
    event Mint(address indexed owner, uint256 tokenId);

    // constructor
    constructor() ERC721A("FamePass", "FAMEPASS", 300) {}

    // dev mint
    function ownerMintFromReserved(address to, uint256 amount)
        public
        onlyOwner
    {
        require(amount <= reservedSize, "Minting amount exceed reserved size");
        reservedSize = reservedSize - amount;
        _mintWithoutValidation(to, amount);
    }

    // whitelist mint
    function whitelistMint(bytes32[] memory proof) external payable {
        require(!whitelistMintPaused, "Whitelist mint paused");
        require(
            isAddressWhitelisted(proof, msg.sender) || isAddressXlisted(proof, msg.sender),
            "Not eligible"
        );

        uint256 limit = maxItemsPerTx;
        if (isAddressXlisted(proof, msg.sender)) {
            limit = maxItemsPerTxForXlist;
        }

        uint256 amount;
        uint256 remainder;
        if(mintPrice == 0){
            amount = 1;
        } else {
            amount = msg.value / mintPrice;
            remainder = msg.value % mintPrice;
        }
        require(amount > 0, "Amount to mint is 0");
        require(
            whitelistMintedAmount[msg.sender] + amount <= limit,
            "Exceed allowance per wallet"
        );

        require(whitelistMintMaxSupply >= amount, "Whitelist mint sold out");
        require((totalSupply() + amount) <= collectionSize - reservedSize, "Sold out");
        whitelistMintMaxSupply = whitelistMintMaxSupply - amount;

        whitelistMintedAmount[msg.sender] += amount;

        _mintWithoutValidation(msg.sender, amount);

        if (remainder > 0) {
            payable(msg.sender).transfer(remainder);
        }
    }

    // public mint
    function publicMint() external payable {
        require(!publicMintPaused, "Public mint paused");

        uint256 amount;
        uint256 remainder;

        if(mintPrice == 0){
            amount = 1;
        } else {
            amount = msg.value / mintPrice;
            remainder = msg.value % mintPrice;
        }

        require(amount > 0, "Amount to mint is 0");
        require(amount <= maxItemsPerTx, "Exceed allowance per tx");

        require(publicMintMaxSupply >= amount, "Public mint sold out");
        require((totalSupply() + amount) <= collectionSize - reservedSize, "Sold out");
        publicMintMaxSupply = publicMintMaxSupply - amount;

        _mintWithoutValidation(msg.sender, amount);

        if (remainder > 0) {
            payable(msg.sender).transfer(remainder);
        }
    }

    // helper
    function _mintWithoutValidation(address to, uint256 amount) internal {
        require((totalSupply() + amount) <= collectionSize, "Sold out");
        _safeMint(to, amount);
        emit Mint(to, amount);
    }

    function isAddressWhitelisted(bytes32[] memory proof, address _address)
        public
        view
        returns (bool)
    {
        return isAddressInMerkleRoot(whitelistMerkleRoot, proof, _address);
    }

    function isAddressXlisted(bytes32[] memory proof, address _address)
        public
        view
        returns (bool)
    {
        return isAddressInMerkleRoot(XlistMerkleRoot, proof, _address);
    }

    function isAddressInMerkleRoot(
        bytes32 merkleRoot,
        bytes32[] memory proof,
        address _address
    ) internal pure returns (bool) {
        return proof.verify(merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    // setter
    function setReservedSize(uint256 _reservedSize) public onlyOwner {
        reservedSize = _reservedSize;
    }

    function setPublicMintMaxSupply(uint256 _publicMintMaxSupply)
        public
        onlyOwner
    {
        publicMintMaxSupply = _publicMintMaxSupply;
    }

    function setPublicMintPaused(bool _publicMintPaused) public onlyOwner {
        publicMintPaused = _publicMintPaused;
    }

    function setWhitelistMintMaxSupply(uint256 _whitelistMintMaxSupply)
        public
        onlyOwner
    {
        whitelistMintMaxSupply = _whitelistMintMaxSupply;
    }

    function setWhitelistMintPaused(bool _whitelistMintPaused)
        public
        onlyOwner
    {
        whitelistMintPaused = _whitelistMintPaused;
    }

    function setWhitelistMintInfo(
        bytes32 _whitelistMerkleRoot,
        bytes32 _XlistMerkleRoot
    ) public onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
        XlistMerkleRoot = _XlistMerkleRoot;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) public onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setXlistMerkleRoot(bytes32 _XlistMerkleRoot) public onlyOwner {
        XlistMerkleRoot = _XlistMerkleRoot;
    }

    function setMintInfo(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxItemsPerTx(uint256 _maxItemsPerTx) public onlyOwner {
        maxItemsPerTx = _maxItemsPerTx;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // withdraws
    function withdraw(address to, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Exceed balance");
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    function withdrawAll(address to) external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    // view
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }
}