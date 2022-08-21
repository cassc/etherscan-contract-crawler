// SPDX-License-Identifier: MIT
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////// █████╗ ██████╗ ███████╗███████╗██████╗ ███████╗////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////██╔══██╗██╔══██╗██╔════╝██╔════╝██╔══██╗██╔════╝////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////███████║██████╔╝█████╗  █████╗  ██████╔╝███████╗////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////██╔══██║██╔═══╝ ██╔══╝  ██╔══╝  ██╔═══╝ ╚════██║////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////██║  ██║██║     ███████╗███████╗██║     ███████║////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝╚═╝     ╚══════╝////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                

pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Apeeps is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public PRICE = 0.003 ether;

    string private BASE_URI = '';

    constructor() ERC721A("Apeeps", "APEEPS") {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        BASE_URI = customBaseURI_;
    }

    function setPrice(uint256 price) external onlyOwner {
        PRICE = price;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount < 11, "Invalid mint amount!");
        require(currentIndex + _mintAmount < 3000, "Max supply exceeded!");
        _;
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
        uint256 price = PRICE * _mintAmount;
        require(msg.value >= price, "Insufficient funds!");
        
        _safeMint(msg.sender, _mintAmount);
    }

    function mintOwner(address _to, uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    address private constant payoutAdd =
    0x5F40a5157E1CA5C4667a02C3A136144749dE3788;

    function letuspeep() public onlyOwner nonReentrant {
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