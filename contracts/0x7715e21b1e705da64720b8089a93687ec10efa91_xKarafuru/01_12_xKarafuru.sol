// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract xKarafuru is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public PRICE = 0.01 ether;
    uint256 public MAX_SUPPLY = 5555;
    
    uint256 public MAX_MINT_AMOUNT_PER_TX = 20;

    string private BASE_URI = '';

    bool public IS_SALE_ACTIVE = true;
    bool public REVEAL_STATUS = false;
    uint256 public FREE_MINT_IS_ALLOWED_UNTIL = 1000;

    constructor() ERC721A("0xKarafuru", "0xKarafuru") {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setPrice(uint256 customPrice) external onlyOwner {
        PRICE = customPrice;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        BASE_URI = customBaseURI_;
    }

    function setMaxMintPerTx(uint256 maxMintPerTx) external onlyOwner {
        MAX_MINT_AMOUNT_PER_TX = maxMintPerTx;
    }

    function setSaleActive(bool saleIsActive) external onlyOwner {
        IS_SALE_ACTIVE = saleIsActive;
    }

    function setFreeMintAllowedUntil(uint256 freeMintIsAllowedUntil) external onlyOwner {
        FREE_MINT_IS_ALLOWED_UNTIL = freeMintIsAllowedUntil;
    }

    function setRevealStatus(bool revealStatus) external onlyOwner {
        REVEAL_STATUS = revealStatus;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= MAX_MINT_AMOUNT_PER_TX, "Invalid mint amount!");
        require(currentIndex + _mintAmount <= MAX_SUPPLY, "Max supply exceeded!");
        _;
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
        require(IS_SALE_ACTIVE, "Sale is not active!");
        if (currentIndex + _mintAmount > FREE_MINT_IS_ALLOWED_UNTIL) {
            uint256 price = PRICE * _mintAmount;
            require(msg.value >= price, "Insufficient funds!");
        }
        _safeMint(msg.sender, _mintAmount);
    }

    function mintOwner(address _to, uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_to, _mintAmount);
    }

    address private constant payoutAddress1 =
    0xa73BC8CC76E5D43166d4b21fAE94B095f17bC747;

    address private constant payoutAddress2 =
    0x43C951cc7eEC446EAae31e6fB1679A701A6EeB25;

    function genzai() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(payoutAddress1), balance / 2);
        Address.sendValue(payable(payoutAddress2), balance / 2);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory) 
    {
        require(_exists(tokenId), "Non-existent token!");
        if(REVEAL_STATUS) {
            string memory baseURI = BASE_URI;
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
        } else {
            return 'https://ipfs.io/ipfs/QmQzyd6tf5dD6fvA6BtMYZZp2KM43jVegnXVdSmhwcwsBy';
        }
    }
}