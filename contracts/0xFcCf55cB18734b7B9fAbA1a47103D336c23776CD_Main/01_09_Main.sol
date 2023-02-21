// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/iNft.sol";

contract Main is Ownable, Pausable, ReentrancyGuard {

    constructor() {
        _pause();
    }

    /** CONTRACTS */
    iNft public nftContract;

    /** EVENTS */
    event ManyNftsMinted(address indexed owner, uint16[] tokenIds);

    /** PUBLIC VARS */
    uint256 public mintPriceType1 = 0.00001 ether;
    uint256 public mintPriceType2 = 0.00003 ether;

    bool public PRE_SALE_STARTED;
    // maximum nfts on sale at pre-sale
    uint256 public MAX_PRE_SALE_MINTS = 381; // 81 are for the team and marketing & 300 for pre-sale

    bool public PUBLIC_SALE_STARTED;
    uint8 public MAX_PUBLIC_SALE_MINTS_PER_WALLET = 3;

    address public projectWallet;

    /** PRIVATE VARS */
    mapping(address => bool) private _admins;
    mapping(address => uint8) private _preSaleAddresses;
    mapping(address => uint8) private _preSaleMints;
    mapping(address => uint8) private _publicSaleMints;
    
    /** MODIFIERS */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "Main: Only admins can call this");
        _;
    }

    modifier onlyEOA() {
        require(tx.origin == _msgSender(), "Main: Only EOA");
        _;
    }

    modifier requireVariablesSet() {
        require(address(nftContract) != address(0), "Main: Nft contract not set");
        require(address(projectWallet) != address(0), "Main: Project wallet address must be set");
        _;
    }

    /** PUBLIC FUNCTIONS */
    function mint(uint256 amount, uint8 tokenType) external payable whenNotPaused nonReentrant onlyEOA {
        require(PRE_SALE_STARTED || PUBLIC_SALE_STARTED, "Main: Sale has not started yet");
        if (PRE_SALE_STARTED) {
            require(_preSaleAddresses[_msgSender()] > 0, "Main: You are not on the whitelist");
            require(_preSaleMints[_msgSender()] + amount <= _preSaleAddresses[_msgSender()], "Main: You cannot mint more during pre-sale");
            require(nftContract.totalMinted() + amount <= MAX_PRE_SALE_MINTS, "Main: All pre-sale nfts minted");
        } else {
            require(_publicSaleMints[_msgSender()] + amount <= MAX_PUBLIC_SALE_MINTS_PER_WALLET, "Main: You cannot mint more");
        }
        require(tokenType == 1 || tokenType == 2, "Main: Token type must be either 1 or 2");

        uint256 mintPrice = mintPriceType1;
        if (tokenType == 2) mintPrice = mintPriceType2;
        require(mintPrice > 0, "Main: Mint price cannot be 0");

        require(msg.value >= amount * mintPrice, "Main: Invalid payment amount");

        uint16[] memory tokenIds = new uint16[](amount);

        for (uint i = 0; i < amount; i++) {
            if (PRE_SALE_STARTED) {
                _preSaleMints[_msgSender()]++;
            } else {
                _publicSaleMints[_msgSender()]++;
            }

            nftContract.mint(_msgSender(), tokenType);
            tokenIds[i] = nftContract.totalMinted();
        }

        emit ManyNftsMinted(_msgSender(), tokenIds);
    }

    function getRemainingPreSaleMints(address addr) public view returns (uint8) {
        if (_preSaleAddresses[addr] >= _preSaleMints[addr]) {
            return _preSaleAddresses[addr] - _preSaleMints[addr];
        } 
        return 0;
    }

    function getRemainingPublicSaleMints(address addr) public view returns (uint8) {
        if (MAX_PUBLIC_SALE_MINTS_PER_WALLET >= _publicSaleMints[addr]) {
            return MAX_PUBLIC_SALE_MINTS_PER_WALLET - _publicSaleMints[addr];
        } 
        return 0;
    }

    /** ADMIN ONLY FUNCTIONS */
    function addToPresale(address[] memory addresses, uint8 allowedToMint) external onlyAdmin {
         for (uint i = 0; i < addresses.length; i++) {
            _preSaleAddresses[addresses[i]] = allowedToMint;
         }
    }

    function setMintPriceType1(uint256 number) external onlyAdmin {
        mintPriceType1 = number;
    }

    function setMintPriceType2(uint256 number) external onlyAdmin {
        mintPriceType2 = number;
    }

    function setPreSaleStarted(bool started) external onlyAdmin {
        PRE_SALE_STARTED = started;
        if (PRE_SALE_STARTED) PUBLIC_SALE_STARTED = false;
    }

    function setMaxPreSaleMints(uint8 number) external onlyAdmin {
        MAX_PRE_SALE_MINTS = number;
    }

    function setPublicSaleStarted(bool started) external onlyAdmin {
        PUBLIC_SALE_STARTED = started;
        if (PUBLIC_SALE_STARTED) PRE_SALE_STARTED = false;
    }

    function setMaxPublicSaleMintsPerWallet(uint8 number) external onlyAdmin {
        MAX_PUBLIC_SALE_MINTS_PER_WALLET = number;
    }

    function isAdmin(address addr) external view onlyAdmin returns(bool) {
        if (_admins[addr]) return true;
        return false;
    }

    /** OWNER ONLY FUNCTIONS */
    function setContracts(address _nftContract) external onlyOwner {
        nftContract = iNft(_nftContract);
    }

    function setPaused(bool _paused) external requireVariablesSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function mintForTeam(address receiver, uint256 amount, uint8 tokenType) external whenNotPaused onlyOwner {
        require(tokenType == 1 || tokenType == 2, "Main: Token type must be either 1 or 2");
        for (uint i = 0; i < amount; i++) {
            nftContract.mint(receiver, tokenType);
        }
    }

    function withdraw() external onlyOwner {
        uint256 totalAmount = address(this).balance;

        bool sent;
        (sent, ) = projectWallet.call{value: totalAmount}("");
        require(sent, "Main: Failed to send funds to projectWallet");
    }

    function setProjectWallet(address addr) external onlyOwner {
        projectWallet = addr;
    }

    function addAdmin(address addr) external onlyOwner {
        _admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        delete _admins[addr];
    }
}