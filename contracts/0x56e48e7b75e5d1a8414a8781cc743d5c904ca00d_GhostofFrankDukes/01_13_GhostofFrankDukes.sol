// contracts/GhostofFrankDukes.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*

_____/\\\\\\\\\\\\_______/\\\\\_______/\\\\\\\\\\\\\\\__/\\\\\\\\\\\\____        
 ___/\\\//////////______/\\\///\\\____\/\\\///////////__\/\\\////////\\\__       
  __/\\\_______________/\\\/__\///\\\__\/\\\_____________\/\\\______\//\\\_      
   _\/\\\____/\\\\\\\__/\\\______\//\\\_\/\\\\\\\\\\\_____\/\\\_______\/\\\_     
    _\/\\\___\/////\\\_\/\\\_______\/\\\_\/\\\///////______\/\\\_______\/\\\_    
     _\/\\\_______\/\\\_\//\\\______/\\\__\/\\\_____________\/\\\_______\/\\\_   
      _\/\\\_______\/\\\__\///\\\__/\\\____\/\\\_____________\/\\\_______/\\\__  
       _\//\\\\\\\\\\\\/_____\///\\\\\/_____\/\\\_____________\/\\\\\\\\\\\\/___ 
        __\////////////_________\/////_______\///______________\////////////_____

The Ghost of Frank Dukes

developed by Luke Davis (http://luke.onl)

*/


contract GhostofFrankDukes is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // Constant variables
    // ------------------------------------------------------------------------
    uint256 public constant TOTAL_SUPPLY = 9999; // Total amount of Hearts
    uint256 public constant RESERVED_SUPPLY = 222; // Amount of Hearts reserved for the contract
    uint256 public constant MAX_SUPPLY = TOTAL_SUPPLY - RESERVED_SUPPLY; // Maximum amount of Hearts

    uint256 public constant MAX_PER_TX = 3; // Max amount of Hearts per tx (public sale)
    uint256 public constant MAX_PER_WALLET = 3; // Max amount of hearts per wallet during public sale.

    uint256 public constant PRICE = 0.11 ether;

    address private constant _a1 = 0x8cAfe4832741771fFaaFdb20d719F54D2A2C498f; // 0.55%
    address private constant _a2 = 0x54B11C5BEC846b0ba9a74bE8402676a594D0C78d; // 0.18%
    address private constant _a3 = 0x5857F73A69Ff7c59d4E219Ab186CAc1aF91243eD; // 0.06%
    address private constant _a4 = 0x3c93Cf5F58D40d25Cd9E08075B0272355929441e; // 0.09%
    address private constant _a5 = 0x90B5e462B0bA7A60C6E5d4E90be85444A4566967; // 0.09%
    address private constant _a6 = 0x5616dE68F03f05A7a5beb6d59B850BCA086Eb0D2; // 0.19%
    address private constant _a7 = 0x8F885C3549aCfDE9Fc642A57c338796f0d576841; // 0.09%
    address private constant _a8 = 0x2495f410271d62c9d0b28053D9A3e74e93635fb5; // 1.25%
    address private constant _a9 = 0xCE95E48Bb08346798b56dFdEbecB5DAD5cC8b273; // 7.50%
    address private constant _a10 = 0x5ef6E3570a32eA63c7BfB69Bbb72fE0Cd37dFA42; // 15%
    address private constant _a11 = 0x5d6B10678AdE8b13F5CaD1840A133BD6a549ACe5; // 75%
    

    // State variables
    // ------------------------------------------------------------------------
    bool public isPresaleActive = false;
    bool public isPublicSaleActive = false;


    // Presale arrays
    // ------------------------------------------------------------------------
    mapping(address => bool) private _presaleEligible;
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
    constructor() ERC721("The Ghost of Frank Dukes", "GHOST") {}


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

    // Presale functions
    // ------------------------------------------------------------------------
    function addToPresaleList(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "NULL_ADDRESS");
            require(!_presaleEligible[addresses[i]], "DUPLICATE_ENTRY");

            _presaleEligible[addresses[i]] = true;
            _totalClaimed[addresses[i]] = 0;
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

    function hasMinted(address addr) external view returns (bool) {
        require(addr != address(0), "NULL_ADDRESS");

        return _totalClaimed[addr] > 1;
    }

    function togglePresaleStatus() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function togglePublicSaleStatus() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }


    // Mint functions
    // ------------------------------------------------------------------------
    function claimReserved(address addr, uint256 quantity) external onlyOwner {
        require(totalSupply() < TOTAL_SUPPLY, "SOLD_OUT");
        require(totalSupply() + quantity < TOTAL_SUPPLY, "EXCEEDS_TOTAL_SUPPLY");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(addr, totalSupply() + 1);
        }
    }

    function claimPresaleGhost(uint256 quantity) external payable onlyPresale {
        require(_presaleEligible[msg.sender], "NOT_ELIGIBLE_FOR_PRESALE");
        require(_totalClaimed[msg.sender] <= MAX_PER_WALLET, "LIMIT_REACHED");
        require(_totalClaimed[msg.sender] + quantity <= MAX_PER_WALLET, "EXCEEDS_LIMIT");

        require(quantity > 0, "QUANTITY_CANNOT_BE_ZERO");
        require(quantity <= MAX_PER_TX, "EXCEEDS_MAX_PER_TX");

        require(totalSupply() < MAX_SUPPLY, "SOLD_OUT");
        require(totalSupply() + quantity <= MAX_SUPPLY, "EXCEEDS_MAX_SUPPLY");

        require(PRICE * quantity == msg.value, "INVALID_ETH_AMOUNT");

        for (uint256 i = 0; i < quantity; i++) {
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function mint(uint256 quantity) external payable onlyPublicSale {
        require(tx.origin == msg.sender, "GO_AWAY_BOT");
        
        require(quantity > 0, "QUANTITY_CANNOT_BE_ZERO");
        require(quantity <= MAX_PER_TX, "EXCEEDS_MAX_PER_TX");

        require(totalSupply() < MAX_SUPPLY, "SOLD_OUT");
        require(totalSupply() + quantity <= MAX_SUPPLY, "EXCEEDS_MAX_SUPPLY");
        
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
        uint _a1amount = address(this).balance * 55/10000;
        uint _a2amount = address(this).balance * 18/10000;
        uint _a3amount = address(this).balance * 6/10000;
        uint _a4amount = address(this).balance * 9/10000;
        uint _a5amount = address(this).balance * 9/10000;
        uint _a6amount = address(this).balance * 19/10000;
        uint _a7amount = address(this).balance * 9/10000;
        uint _a8amount = address(this).balance * 125/10000;
        uint _a9amount = address(this).balance * 750/10000;
        uint _a10amount = address(this).balance * 1500/10000;
        uint _a11amount = address(this).balance * 7500/10000;

        require(payable(_a1).send(_a1amount), "FAILED_TO_SEND_TO_A1");
        require(payable(_a2).send(_a2amount), "FAILED_TO_SEND_TO_A2");
        require(payable(_a3).send(_a3amount), "FAILED_TO_SEND_TO_A3");
        require(payable(_a4).send(_a4amount), "FAILED_TO_SEND_TO_A4");
        require(payable(_a5).send(_a5amount), "FAILED_TO_SEND_TO_A5");
        require(payable(_a6).send(_a6amount), "FAILED_TO_SEND_TO_A6");
        require(payable(_a7).send(_a7amount), "FAILED_TO_SEND_TO_A7");
        require(payable(_a8).send(_a8amount), "FAILED_TO_SEND_TO_A8");
        require(payable(_a9).send(_a9amount), "FAILED_TO_SEND_TO_A9");
        require(payable(_a10).send(_a10amount), "FAILED_TO_SEND_TO_A10");
        require(payable(_a11).send(_a11amount), "FAILED_TO_SEND_TO_A11");
    }

    function emergencyWithdraw() external onlyOwner {
        payable(_a11).transfer(address(this).balance);
    }
}