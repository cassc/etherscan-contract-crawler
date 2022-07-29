// SPDX-License-Identifier: MIT
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////█░█ █▀▀█ █▀▀█ █▀▀█ █▀▀ █░░█ █▀▀█ █░░█ █▀▀█ █▀▀█ ▀▀█▀▀   ░ ░   █▀▀▀ █▀▀ █▀▀▄ █▀▀ █▀▀ ░▀░ █▀▀///////////
////////////█▀▄ █▄▄█ █▄▄▀ █▄▄█ █▀▀ █░░█ █▄▄▀ █░░█ █▄▄█ █▄▄▀ ░░█░░   ▀ ▀   █░▀█ █▀▀ █░░█ █▀▀ ▀▀█ ▀█▀ ▀▀█///////////
////////////▀░▀ ▀░░▀ ▀░▀▀ ▀░░▀ ▀░░ ░▀▀▀ ▀░▀▀ ░▀▀▀ ▀░░▀ ▀░▀▀ ░░▀░░   ░ ░   ▀▀▀▀ ▀▀▀ ▀░░▀ ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀///////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// @author: KarafuruArt DevTeam
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract KarafuruArtGenesis is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string private BASE_URI = '';

    uint256 public PRICE = 0 ether; // Free mint :P

    constructor() ERC721A("KarafuruArtGenesis", "KAG") {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        BASE_URI = customBaseURI_;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        // max 5 mints per txn
        require(_mintAmount > 0 && _mintAmount < 6, "Invalid mint amount!");
        // max supply is 1555
        require(currentIndex + _mintAmount < 1555, "Max supply exceeded!");
        _;
    }

    // for minters
    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
        uint256 _totalMintAmount = currentIndex + _mintAmount;
        if(_totalMintAmount >= 50 && _totalMintAmount <700) {
            PRICE = 0.025 ether;
        } else if(_totalMintAmount >=700 && _totalMintAmount <1200){
            PRICE = 0.05 ether;
        } else if(_totalMintAmount >= 1200){
            PRICE = 0.075 ether;
        }

        uint256 price = PRICE * _mintAmount;
        require(msg.value >= price, "You have Insufficient funds!");
        
        _safeMint(msg.sender, _mintAmount);
    }

    // official use only - airdrops & giveaways
    function mintOwner(address _to, uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    address private constant payoutAdd =
    0xe1598c797b269b203191FdcB9676A22F20Eb807d;

    function ikz() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(payoutAdd), balance);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Non-existent token!");
        string memory baseURI = BASE_URI;
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
        
    }
}