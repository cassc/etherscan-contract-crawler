//SPDX-License-Identifier: Unlicense
// Creator: Pixel8 Labs
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./lib/ERC721Base.sol";
import "./lib/MerkleTree.sol";

contract WZKD is ERC721Base, PaymentSplitter, Ownable, AccessControl, Pausable, ReentrancyGuard, MerkleTree {
    uint private maxTotalSupply = 5678;
    uint private maxPrivateMint = 10;
    uint private maxPublicMint = 6;
    IERC721 private apeLiquidContract;
    mapping(address => uint) privateClaimed;
    mapping(address => uint) publicClaimed;

    // Toggle
    bool public isPublic;
    bool public isPrivate;

    // Pricing
    uint256 public price = 0.068 ether;
    uint256 public wlPrice = 0.048 ether;
    address[] public _payees = [
        0x2961dA73F6e08EeE37EC3F488e9008004F90BbDC,
        0x9B0C5c21BA4D452934Ad4c1cb314fbcfCA132c7A,
        0x0B0237aD59e1BbCb611fdf0c9Fa07350C3f41e87
    ];
    uint256[] private _shares = [5, 85, 10];

    constructor (
        string memory tokenURI_
    ) ERC721Base(tokenURI_, "WZKD", "WZKD")
    PaymentSplitter(_payees, _shares) {
        _transferOwnership(0x9B0C5c21BA4D452934Ad4c1cb314fbcfCA132c7A);
        isPublic = false;
        isPrivate = false;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function privateMint(uint amount, bytes32[] calldata _proof) 
        external payable whenNotPaused nonReentrant {
        uint256 supply = totalSupply();
        require(privateClaimed[msg.sender] + amount <= maxPrivateMint, "amount exceeded maximum");
        require(msg.value == wlPrice * amount, "insufficient fund");
        require(isPrivate, "not open yet");
        require(isAllowed(_proof, msg.sender) || apeLiquidContract.balanceOf(msg.sender) > 0, "not allowed");
        require(amount > 0, "amount too little");
        require(msg.sender != address(0), "empty address");
        require(supply + amount <= maxTotalSupply, "exceed max supply");

        privateClaimed[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function publicMint(uint amount) external payable whenNotPaused nonReentrant {
        uint256 supply = totalSupply();
        require(publicClaimed[msg.sender] + amount <= maxPublicMint, "mint quota reached");
        require(msg.value == price * amount, "insufficient fund");
        require(isPublic, "not open yet");
        require(amount > 0, "amount too little");
        require(msg.sender != address(0), "empty address");
        require(supply + amount <= maxTotalSupply, "exceed max supply");

        publicClaimed[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    // APE LIQUID
    uint private apeLiquid;
    uint constant private APE_LIQUID_MAX = 567;
    address private apeLiquidWallet = 0x0B0237aD59e1BbCb611fdf0c9Fa07350C3f41e87;

    function setApeLiquidWallet(address value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        apeLiquidWallet = value;
    }

    function freeMint(uint amount) external {
        uint256 supply = totalSupply();
        require(amount > 0, "amount too little");
        require(apeLiquid + amount <= APE_LIQUID_MAX, "mint quota reached");
        require(msg.sender == apeLiquidWallet, "not allowed");
        require(supply + amount <= maxTotalSupply, "exceed max supply");
        apeLiquid += amount;
        _safeMint(msg.sender, amount);
    }

    // Admin
    function airdrop(address wallet, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 supply = totalSupply();
        require(amount > 0, "amount too little");
        require(wallet != address(0), "not allowed");
        require(supply + amount <= maxTotalSupply, "exceed max supply");

        _safeMint(wallet, amount);
    }

    // Minting fee
    function setPrice(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        price = amount;
    }
    function setPublic(bool value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPublic = value;
    }
    function setWlPrice(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        wlPrice = amount;
    }
    function setPrivate(bool value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPrivate = value;
    }
    function setApeLiquidContract(address value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        apeLiquidContract = IERC721(value);
    }

    // Max Settings
    function setMaxSupply(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxTotalSupply = amount;
    }
    function setMaxPrivateMint(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxPrivateMint = amount;
    }
    function setMaxPublicMint(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxPublicMint = amount;
    }

    // Payment
    function claim() external {
        release(payable(msg.sender));
    }

    // Allowlist
    function setMerkleRoot(bytes32 root) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMerkleRoot(root);
    }
    function setRequireAllowlist(bool value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRequireAllowlist(value);
    }

    // Metadata
    function setTokenURI(string calldata uri_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenURI(uri_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Base, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}