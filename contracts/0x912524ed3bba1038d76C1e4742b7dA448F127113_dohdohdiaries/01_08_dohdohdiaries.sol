// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract dohdohdiaries is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    uint256 public immutable MAX_SUPPLY = 5000;
    uint256 public FREE_SUPPLY;
    uint256 public MAX_PUBLIC_SUPPLY;

    uint256 public price = .005 ether;

    uint256 public maxFreePublic = 2; //max for free public
    uint256 public maxPaidPublic = 10; //max for paid public

    bool public _isFreeActive = false;
    bool public _isPaidActive = false;
    bool public _isAllowlistActive = false;

    mapping(address => uint256) public _freeCounter;
    mapping(address => uint256) public _paidCounter;
    mapping(address => uint256) public _allowlistCounter;
    uint256 public _teamCounter;

    bytes32 public merkleRoot; // merkle root

    constructor() ERC721A("doh doh diaries", "DOHDOH") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    //accessors
    function setFreeActive(bool _isActive) external onlyOwner {
        _isFreeActive = _isActive;
    }

    function setPaidActive(bool _isActive) external onlyOwner {
        _isPaidActive = _isActive;
    }

    function setAllowlistActive(bool _isActive) external onlyOwner {
        _isAllowlistActive = _isActive;
    }

    function setMaxFreeSupply(uint256 _maxFreeSupply) external onlyOwner {
        FREE_SUPPLY = _maxFreeSupply;
    }

    function setMaxPublicSupply(uint256 _maxPublicSupply) external onlyOwner {
        MAX_PUBLIC_SUPPLY = _maxPublicSupply;
    }

    function setMaxFreeMints(uint256 _maxFreeMints) external onlyOwner {
        maxFreePublic = _maxFreeMints;
    }

    function setMaxPaidMints(uint256 _maxPaidMints) external onlyOwner {
        maxPaidPublic = _maxPaidMints;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function alreadyMintedFree(address addr) public view returns (uint256) {
        return _freeCounter[addr];
    }

    function alreadyMintedPaid(address addr) public view returns (uint256) {
        return _paidCounter[addr];
    }

    function alreadyMintedAllowlist(address addr)
        public
        view
        returns (uint256)
    {
        return _allowlistCounter[addr];
    }

    // metadata URI
    string private baseURI;

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // internal mints for team
    function internalMint(uint256 amount, address to) external onlyOwner {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "would exceed max supply"
        );
        _safeMint(to, amount);
        _teamCounter = _teamCounter + amount;
    }

    // free public mint
    function freePublicMint(uint256 amount) external callerIsUser nonReentrant {
        require(amount > 0, "Must mint more than 0 tokens");
        require(_isFreeActive, "Free public mint is closed");
        require(
            _freeCounter[msg.sender] + amount <= maxFreePublic,
            "Exceeds max free per address"
        );
        require(
            totalSupply() + amount <= FREE_SUPPLY,
            "Reached max supply for free mints"
        );
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "Reached max total supply"
        );

        _freeCounter[msg.sender] = _freeCounter[msg.sender] + amount;
        _safeMint(msg.sender, amount);
    }

    // paid public mint
    function paidPublicMint(uint256 amount)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(amount > 0, "Must mint more than 0 tokens");
        require(_isPaidActive, "Paid public mint is closed");
        require(
            _paidCounter[msg.sender] + amount <= maxPaidPublic,
            "Exceeds max per address"
        );
        require(price * amount == msg.value, "Incorrect funds");
        require(
            totalSupply() + amount <= MAX_PUBLIC_SUPPLY,
            "Reached max public supply"
        );
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "Reached max total supply"
        );

        _paidCounter[msg.sender] = _paidCounter[msg.sender] + amount;
        _safeMint(msg.sender, amount);
    }

    // allowlist mint
    function mintAllowlist(
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 maxAmount
    ) public callerIsUser nonReentrant {
        address sender = _msgSender();

        require(_isAllowlistActive, "Allowlist mint is closed");
        require(
            amount <= maxAmount - _allowlistCounter[sender],
            "You have insufficient allowlist mints left"
        );
        require(amount > 0, "Must mint more than 0 tokens");
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "Purchase would exceed max supply of tokens"
        );
        require(_verify(merkleProof, sender, maxAmount), "Invalid proof");

        _allowlistCounter[sender] += amount;
        _safeMint(sender, amount);
    }

    function _verify(
        bytes32[] calldata merkleProof,
        address sender,
        uint256 maxAmount
    ) private view returns (bool) {
        bytes32 leaf = keccak256(
            abi.encodePacked(sender, maxAmount.toString())
        );
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    //withdraw to owner wallet
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}