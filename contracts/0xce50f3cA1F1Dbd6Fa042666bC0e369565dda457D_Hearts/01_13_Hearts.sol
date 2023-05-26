// contracts/Hearts.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
       XOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOX
       O:::::::::::::::::::::::::::::::::::::::::::::::::::::::O
       X:::::::::::::::::::::::::::::::::::::::::::::::::::::::X
       O::::::::::::           :::::::::           ::::::::::::O
       X:::::::::                :::::                :::::::::X
       O:::::::       *********    :    *********       :::::::O
       X:::::      *****     *****   *****     *****      :::::X
       O::::     ****           *******           ****     ::::O
       X:::     ****              ***              ****     :::X
       O:::     ****               *               ****     :::O
       X::::     ****                             ****     ::::X
       O:::::     ****                           ****     :::::O
       X:::::::     ****                       ****     :::::::X
       O:::::::::     ****                   ****     :::::::::O
       X:::::::::::     ****               ****     :::::::::::X
       O::::::::::::::     ****         ****     ::::::::::::::O
       X:::::::::::::::::     ****   ****     :::::::::::::::::X
       O::::::::::::::::::::     *****     ::::::::::::::::::::O
       X:::::::::::::::::::::::    *    :::::::::::::::::::::::X
       O:::::::::::::::::::::::::     :::::::::::::::::::::::::O
       X::::::::::::::::::::::::::: :::::::::::::::::::::::::::X
       O:::::::::::::::::::::::::::::::::::::::::::::::::::::::O
       X:::::::::::::::::::::::::::::::::::::::::::::::::::::::X
       OXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXOXO

       The Heart Project

       Contract made with ❤️
*/


contract Hearts is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // Constant variables
    // ------------------------------------------------------------------------
    uint256 public constant TOTAL_SUPPLY = 10000; // Total amount of Hearts
    uint256 public constant RESERVED_SUPPLY = 420; // Amount of Hearts reserved for the contract
    uint256 public constant MAX_SUPPLY = TOTAL_SUPPLY - RESERVED_SUPPLY; // Maximum amount of Hearts
    uint256 public constant PRESALE_SUPPLY = 6000; // Presale supply

    uint256 public constant MAX_PER_TX = 2; // Max amount of Hearts per tx (public sale)
    uint256 public constant MAX_PER_WALLET_PUBLIC = 4; // Max amount of hearts per wallet during public sale.

    uint256 public constant PRICE = 0.08888 ether;


    // Team addresses
    // ------------------------------------------------------------------------
    address private constant _a1 = 0xB08F6d5f8C46D3E6342b27a6985E7073358d0e1E;
    address private constant _a2 = 0xedc3867EC7b08eab60c22D879Ee4d4A433e436aF;
    address private constant _a3 = 0x6b6cAb32fc38C7C12247700A9ea5Eb1929BAc3f8;
    address private constant _a4 = 0x02e8cd72529528Fb478b85AC9802070CafA900dD;
    address private constant _a5 = 0x37a18FD0c70A8FcF5984CF886bC75D82085290b4;
    address private constant _a6 = 0x551fc3F7DcA7D3D70fBb0c470ef3f6551bBC18dB;
    address private constant _a7 = 0x724Eec73D48dE3f8Ca22f721A816C7e325F45415;
    address private constant _a8 = 0x19dB526f501240A5Ce19A6c812a9593203CDeFA1;
    

    // State variables
    // ------------------------------------------------------------------------
    bool public isPresaleActive = false;
    bool public isPublicSaleActive = false;


    // Presale arrays
    // ------------------------------------------------------------------------
    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _presaleClaimed;
    mapping(address => uint256) private _totalClaimed;


    // URI variables
    // ------------------------------------------------------------------------
    string private _contractURI;
    string private _baseTokenURI;


    // Events
    // ------------------------------------------------------------------------
    event BaseTokenURIChanged(string baseTokenURI);
    event ContractURIChanged(string contractURI);


    // Constructor
    // ------------------------------------------------------------------------
    constructor() ERC721("The Heart Project", "HEARTS") {}


    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyPresale() {
        require(isPresaleActive, "PRESALE_NOT_ACTIVE");
        _;
    }

    modifier onlyPublicSale() {
        require(isPublicSaleActive, "PUBLIC_SALE_NOT_ACTIVE");
        _;
    }


    // Anti-bot functions
    // ------------------------------------------------------------------------
    function isDelegatedCall () internal view returns (bool) {
        return address (this) != 0xce50f3cA1F1Dbd6Fa042666bC0e369565dda457D;
    }

    function isContractCall(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }


    // Presale functions
    // ------------------------------------------------------------------------
    function addToPresaleList(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "NULL_ADDRESS");
            require(!_presaleEligible[addresses[i]], "DUPLICATE_ENTRY");

            _presaleEligible[addresses[i]] = true;
            _presaleClaimed[addresses[i]] = 0;
        }
    }

    function removeFromPresaleList(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "NULL_ADDRESS");
            require(_presaleEligible[addresses[i]], "NOT_IN_PRESALE");

            _presaleEligible[addresses[i]] = false;
        }
    }

    function isEligibleForPresale(address addr) external view returns (bool) {
        require(addr != address(0), "NULL_ADDRESS");
        
        return _presaleEligible[addr];
    }

    function hasClaimedPresale(address addr) external view returns (bool) {
        require(addr != address(0), "NULL_ADDRESS");

        return _presaleClaimed[addr] == 1;
    }

    function togglePresaleStatus() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function togglePublicSaleStatus() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }


    // Mint functions
    // ------------------------------------------------------------------------
    function claimReservedHeart(uint256 quantity, address addr) external onlyOwner {
        require(totalSupply() >= MAX_SUPPLY, "MUST_REACH_MAX_SUPPLY");
        require(totalSupply() < TOTAL_SUPPLY, "SOLD_OUT");
        require(totalSupply() + quantity <= TOTAL_SUPPLY, "EXCEEDS_TOTAL_SUPPLY");

        _safeMint(addr, totalSupply() + 1);
    }

    function claimPresaleHeart() external payable onlyPresale {
        uint256 quantity = 1;

        require(_presaleEligible[msg.sender], "NOT_ELIGIBLE_FOR_PRESALE");
        require(_presaleClaimed[msg.sender] < 1, "ALREADY_CLAIMED");

        require(totalSupply() < PRESALE_SUPPLY, "PRESALE_SOLD_OUT");
        require(totalSupply() + quantity <= PRESALE_SUPPLY, "EXCEEDS_PRESALE_SUPPLY");

        require(PRICE * quantity == msg.value, "INVALID_ETH_AMOUNT");

        for (uint256 i = 0; i < quantity; i++) {
            _presaleClaimed[msg.sender] += 1;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function mint(uint256 quantity) external payable onlyPublicSale {
        require(tx.origin == msg.sender, "GO_AWAY_BOT_ORIGIN");
        require(!isDelegatedCall(), "GO_AWAY_BOT_DELEGATED");
        require(!isContractCall(msg.sender), "GO_AWAY_BOT_CONTRACT");

        require(totalSupply() < MAX_SUPPLY, "SOLD_OUT");
        require(quantity > 0, "QUANTITY_CANNOT_BE_ZERO");
        require(quantity <= MAX_PER_TX, "EXCEEDS_MAX_MINT");
        require(totalSupply() + quantity <= MAX_SUPPLY, "EXCEEDS_MAX_SUPPLY");

        require(_totalClaimed[msg.sender] + quantity <= MAX_PER_WALLET_PUBLIC, "EXCEEDS_MAX_ALLOWANCE");
        
        require(PRICE * quantity == msg.value, "INVALID_ETH_AMOUNT");

        for (uint256 i = 0; i < quantity; i++) {
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }


    // Base URI Functions
    // ------------------------------------------------------------------------
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
        emit ContractURIChanged(URI);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function setBaseTokenURI(string calldata URI) external onlyOwner {
        _baseTokenURI = URI;
        emit BaseTokenURIChanged(URI);
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }


    // Withdrawal functions
    // ------------------------------------------------------------------------
    function withdrawAll() external onlyOwner {
        uint _a1amount = address(this).balance * 20/100;
        uint _a2amount = address(this).balance * 20/100;
        uint _a3amount = address(this).balance * 20/100;
        uint _a4amount = address(this).balance * 10/100;
        uint _a5amount = address(this).balance * 14/100;
        uint _a6amount = address(this).balance * 2/100;
        uint _a7amount = address(this).balance * 10/100;
        uint _a8amount = address(this).balance * 4/100;

        require(payable(_a1).send(_a1amount), "FAILED_TO_SEND_TO_A1");
        require(payable(_a2).send(_a2amount), "FAILED_TO_SEND_TO_A2");
        require(payable(_a3).send(_a3amount), "FAILED_TO_SEND_TO_A3");
        require(payable(_a4).send(_a4amount), "FAILED_TO_SEND_TO_A4");
        require(payable(_a5).send(_a5amount), "FAILED_TO_SEND_TO_A5");
        require(payable(_a6).send(_a6amount), "FAILED_TO_SEND_TO_A6");
        require(payable(_a7).send(_a7amount), "FAILED_TO_SEND_TO_A7");
        require(payable(_a8).send(_a8amount), "FAILED_TO_SEND_TO_A8");
    }

    function emergencyWithdraw() external onlyOwner {
        payable(_a3).transfer(address(this).balance);
    }
}