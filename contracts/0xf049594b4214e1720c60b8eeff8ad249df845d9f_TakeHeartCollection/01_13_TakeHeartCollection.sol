// contracts/Hearts.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/*

ooooooooooooo           oooo                       ooooo   ooooo                                  .   
8'   888   `8           `888                       `888'   `888'                                .o8   
     888       .oooo.    888  oooo   .ooooo.        888     888   .ooooo.   .oooo.   oooo d8b .o888oo 
     888      `P  )88b   888 .8P'   d88' `88b       888ooooo888  d88' `88b `P  )88b  `888""8P   888   
     888       .oP"888   888888.    888ooo888       888     888  888ooo888  .oP"888   888       888   
     888      d8(  888   888 `88b.  888    .o       888     888  888    .o d8(  888   888       888 . 
    o888o     `Y888""8o o888o o888o `Y8bod8P'      o888o   o888o `Y8bod8P' `Y888""8o d888b      "888" 


Take Heart Collection

Contract made with ❤️ by Luke

*/


contract TakeHeartCollection is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // Constant variables
    // ------------------------------------------------------------------------
    uint256 public constant TOTAL_SUPPLY = 285;
    uint256 public constant MAX_PER_WALLET = 1;
    uint256 public constant PRICE = 0.1 ether;

    // Addresses
    // ------------------------------------------------------------------------
    address private constant _a1 = 0xb78843383eAA0eF9A5F9b886B3fCAED2A8b2D8aC;
    address private constant _a2 = 0x5ef6E3570a32eA63c7BfB69Bbb72fE0Cd37dFA42;

    // State variables
    // ------------------------------------------------------------------------
    bool public isPresaleActive = false;
    bool public isPublicSaleActive = false;

    // Presale arrays
    // ------------------------------------------------------------------------
    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _presaleClaimed;

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
    constructor() ERC721("Take Heart", "TAKEHEARTS") {}

    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyPresale() {
        require(isPresaleActive, "PRESALE_NOT_ACTIVE");
        _;
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

    // Mint functions
    // ------------------------------------------------------------------------
    function claimTakeHeart() external payable onlyPresale {
        require(_presaleEligible[msg.sender], "NOT_ELIGIBLE_FOR_PRESALE");
        require(_presaleClaimed[msg.sender] < 1, "PRESALE_ALREADY_CLAIMED");
        require(totalSupply() < TOTAL_SUPPLY, "SOLD_OUT");
        require(totalSupply() + 1 <= TOTAL_SUPPLY, "EXCEEDS_SUPPLY");
        require(PRICE == msg.value, "INVALID_ETH_AMOUNT");

        _presaleClaimed[msg.sender] += 1;
        _safeMint(msg.sender, totalSupply() + 1);
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
        uint _a1amount = address(this).balance * 65/100;
        uint _a2amount = address(this).balance * 35/100;

        require(payable(_a1).send(_a1amount), "FAILED_TO_SEND_TO_A1");
        require(payable(_a2).send(_a2amount), "FAILED_TO_SEND_TO_A2");
    }

    function withdrawFull() external onlyOwner {
        payable(_a1).transfer(address(this).balance);
    }
}