// SPDX-License-Identifier: MIT

/*      /   |  _________ ___  (_)___     _   ______ _____     / __ )__  ____  __________  ____
 *     / /| | / ___/ __ `__ \/ / __ \   | | / / __ `/ __ \   / __  / / / / / / / ___/ _ \/ __ \
 *    / ___ |/ /  / / / / / / / / / /   | |/ / /_/ / / / /  / /_/ / /_/ / /_/ / /  /  __/ / / /
 *   /_/ _|_/_/ _/_/ /_/_/_/_/_/ /_/    |___/\__,_/_/ /_/  /_____/\__,_/\__,_/_/   \___/_/ /_/
 *       /   |  /   |  /   |
 *      / /| | / /| | / /| |
 *     / ___ |/ ___ |/ ___ |
 *    /_/  |_/_/  |_/_/  |_|
 */ 

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DefaultOperatorFilterer} from "./filter/DefaultOperatorFilterer.sol";
import "./ERC721A.sol";

contract ArminAAA is Ownable, ERC721A, ReentrancyGuard, DefaultOperatorFilterer {
    uint256 public MAX_SUPPLY = 2500;
    uint256 public PRICE = 0.15 ether;
    uint256 public ALLOWLIST_PRICE = 0.15 ether;

    // per wallet allowance for public and allowlist
    uint256 public maxPublic = 10;
    uint256 public maxAllowlist = 2;

    bool public _publicActive = false;
    bool public _allowlistActive = false;

    // per wallet counters
    mapping(address => uint8) public _allowlistCounter;
    mapping(address => uint8) public _publicCounter;

    // counter for allowlist mints
    uint256 public allowlistMinted;

    // merkle root
    bytes32 public allowlistRoot;

    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {}

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // setters
    function setPublicActive(bool isActive) external onlyOwner {
        _publicActive = isActive;
    }

    function setAllowlistActive(bool isActive) external onlyOwner {
        _allowlistActive = isActive;
    }

    function setMaxAllowlist(uint256 _maxAllowlist) external onlyOwner {
        maxAllowlist = _maxAllowlist;
    }

    function setMaxPublic(uint256 _maxPublic) external onlyOwner {
        maxPublic = _maxPublic;
    }

    function setAllowlistRoot(bytes32 _root) external onlyOwner {
        allowlistRoot = _root;
    }

    function setSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function setAllowlistPrice(uint256 _price) external onlyOwner {
        ALLOWLIST_PRICE = _price;
    }

    // getters
    function getERC20balance(address tokenAddress)
        public
        view
        returns (uint256)
    {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // Internal for marketing, devs, etc
    function internalMint(uint256 quantity, address to)
        external
        onlyOwner
        nonReentrant
    {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "would exceed max supply"
        );
        _safeMint(to, quantity);
    }

    // airdrop
    function airdrop(address[] calldata _addresses)
        external
        onlyOwner
        nonReentrant
    {
        require(
            totalSupply() + _addresses.length <= MAX_SUPPLY,
            "would exceed max supply"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            _safeMint(_addresses[i], 1);
        }
    }

    // metadata URI
    string private _baseTokenURI;

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Allowlist
    function allowlistMint (
        address to,
        uint8 quantity,
        bytes32[] calldata _merkleProof
    ) external payable callerIsUser nonReentrant {
        require(_allowlistActive, "allowlist is not active");
        require(
            _allowlistCounter[to] + quantity <= maxAllowlist,
            "Exceeded max available to purchase"
        );
        require(quantity > 0, "Must mint more than 0 tokens");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Purchase would exceed max supply of Tokens"
        );
        require(ALLOWLIST_PRICE * quantity == msg.value, "Incorrect funds");

        // check proof & mint
        bytes32 leaf = keccak256(abi.encodePacked(to));
        require(
            MerkleProof.verify(_merkleProof, allowlistRoot, leaf),
            "Invalid MerkleProof"
        );
        _allowlistCounter[to] = _allowlistCounter[to] + quantity;
        allowlistMinted = allowlistMinted + quantity;
        _safeMint(to, quantity);
    }

    // public mint
    function publicMint(address to, uint8 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        require(quantity > 0, "Must mint more than 0 tokens");
        require(_publicActive, "public sale has not begun yet");
        require(PRICE * quantity == msg.value, "Incorrect funds");
        require(totalSupply() + quantity <= MAX_SUPPLY, "reached max supply");
        require(
            _publicCounter[to] + quantity <= maxPublic,
            "Exceeded max available to purchase"
        );
        _publicCounter[to] = _publicCounter[to] + quantity;
        _safeMint(to, quantity);
    }

    // backup withdraw to owner wallet - only to be used if splits change later
    function withdrawToOwner() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // payment splits
    function withdrawSplits() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Token balance must be greater than 0");
        payable(0x0aaDEEf83545196CCB2ce70FaBF8be1Afa3C9B87).transfer(
            (balance * 10000) / 100000
        );
        payable(0x95C62Cfc4dcf2615b6D0Ee27CE17578B8b446C64).transfer(
            (balance * 27500) / 100000
        );
        payable(0x8E245915AE95a14c235FBDA3946d2A12048F92f2).transfer(
            (balance * 31250) / 100000
        );
        payable(0x4d85c1A432213D965aDCba935520A024399D26c0).transfer(
            (balance * 15625) / 100000
        );
        payable(0xF69503e221117e7619E9FDdb9665417E7D643BeE).transfer(
            (balance * 15625) / 100000
        );
    }

    // withdraw WETH for looksrare royalties
    function withdrawERC20Splits(address tokenAddress) external onlyOwner {
        uint256 balance = getERC20balance(tokenAddress);
        require(balance > 0, "Token balance must be greater than 0");
        IERC20 tokenContract = IERC20(tokenAddress);
        tokenContract.transfer(
            0x0aaDEEf83545196CCB2ce70FaBF8be1Afa3C9B87,
            (balance * 10000) / 100000
        );
        tokenContract.transfer(
            0x95C62Cfc4dcf2615b6D0Ee27CE17578B8b446C64,
            (balance * 27500) / 100000
        );
        tokenContract.transfer(
            0x8E245915AE95a14c235FBDA3946d2A12048F92f2,
            (balance * 31250) / 100000
        );
        tokenContract.transfer(
            0x4d85c1A432213D965aDCba935520A024399D26c0,
            (balance * 15625) / 100000
        );
        tokenContract.transfer(
            0xF69503e221117e7619E9FDdb9665417E7D643BeE,
            (balance * 15625) / 100000
        );
    }

    // OperatorFilter
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}