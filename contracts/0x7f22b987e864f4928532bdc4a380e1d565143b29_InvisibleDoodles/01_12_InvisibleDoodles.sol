// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract InvisibleDoodles is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public PRICE = 0.02 ether;
    uint256 public MAX_SUPPLY = 10001;
    
    uint256 public MAX_MINT_AMOUNT_PER_TX = 21;

    string private BASE_URI = '';

    bool public IS_SALE_ACTIVE = false;
    uint256 public FREE_MINT_IS_ALLOWED_UNTIL = 1000;

    constructor() ERC721A("InvisibleDoodles", "IDOOD") {
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

    function setSaleStatus(bool isActive) external onlyOwner {
        IS_SALE_ACTIVE = isActive;
    }

    function setFreeMintAllowedUntil(uint256 freeMintIsAllowedUntil) external onlyOwner {
        FREE_MINT_IS_ALLOWED_UNTIL = freeMintIsAllowedUntil;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount < MAX_MINT_AMOUNT_PER_TX, "Invalid mint amount!");
        require(currentIndex + _mintAmount < MAX_SUPPLY, "Max supply exceeded!");
        _;
    }

    function degenMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
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

    address private constant payoutAddress =
    0x95e88c55Ec0C5C8a29e94b4630E0986a91E40a15;

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(payoutAddress).transfer(balance);
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