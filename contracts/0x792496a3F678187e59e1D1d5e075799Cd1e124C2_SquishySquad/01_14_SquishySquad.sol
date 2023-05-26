// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract SquishySquad is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public MAX_SQUISHES = 8888; 
    uint256 public PRICE = 0.08 ether; 
    uint256 public MAX_SQUISHES_MINT = 24;
    uint256 public MAX_PER_TX = 8;

    uint256 public constant HANDPICKED_MAX_MINT = 2;
    uint256 public constant PRESALE_MAX_MINT = 1;
    uint256 public constant RESERVED_SQUISHES = 125; 
    address public constant founderAddress = 0x52d03A5e20551D7B0393843594D5F5465ccD8d88; 

    address private constant launchpadAddress = 0x6BCBE6c086cC66806B0b7B4A53409058d85F61c8; 
    address private constant donationAddress = 0xDfd143aE8592e8E3C13aa3E401f72E1ca7deAED0; 

    uint256 public reservedClaimed;

    uint256 public numSquishesMinted;

    string public baseTokenURI;

    bool public publicSaleStarted;
    bool public presaleStarted;

    mapping(address => bool) private _handpickedEligible;
    mapping(address => bool) private _presaleEligible;

    mapping(address => uint256) public totalClaimed;

    mapping(address => uint256) private _totalClaimedHandpicked;
    mapping(address => uint256) private _totalClaimedPresale;

    event BaseURIChanged(string baseURI);
    event HandpickedMint(address minter, uint256 amountOfSquishes);
    event PresaleMint(address minter, uint256 amountOfSquishes);
    event PublicSaleMint(address minter, uint256 amountOfSquishes);

    modifier whenPresaleStarted() {
        require(presaleStarted, "Presale has not started");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale has not started");
        _;
    }

    constructor(string memory baseURI) ERC721("Squishy Squad", "SQUISH") {
        baseTokenURI = baseURI;
    }

    function claimReserved(address recipient, uint256 amount) external onlyOwner {
        require(reservedClaimed + amount <= RESERVED_SQUISHES, "Minting would exceed max reserved squishes");
        require(recipient != address(0), "Cannot add null address");
        require(totalSupply() + amount <= MAX_SQUISHES, "Minting would exceed max supply");

        uint256 _nextTokenId = numSquishesMinted + 1;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }
        numSquishesMinted += amount;
        reservedClaimed += amount;
    }

    function addToHandpickedPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _handpickedEligible[addresses[i]] = true;
        }
    }

    function addToPartnershipPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _presaleEligible[addresses[i]] = true;
        }
    }

    function checkHandpickedEligibility(address addr) external view returns (bool) {
        return _handpickedEligible[addr];
    }

    function checkPresaleEligibility(address addr) external view returns (bool) {
        return _presaleEligible[addr];
    }

    function getHandpickedMintsClaimed(address addr) external view returns (uint256) {
        return _totalClaimedHandpicked[addr];
    }

    function getPresaleMintsClaimed(address addr) external view returns (uint256) {
        return _totalClaimedPresale[addr];
    }

    function mintPartnershipPresale() external payable whenPresaleStarted {
        require(_presaleEligible[msg.sender], "You are not eligible for the partnership presale");
        require(totalSupply() + 1 <= MAX_SQUISHES - (RESERVED_SQUISHES - reservedClaimed), "Minting would exceed max supply");
        require(_totalClaimedPresale[msg.sender] + 1 <= PRESALE_MAX_MINT, "Only 1 mint allowed");
        require(PRICE <= msg.value, "ETH amount is incorrect");

        uint256 tokenId = numSquishesMinted + 1;

        numSquishesMinted += 1;
        totalClaimed[msg.sender] += 1;
        _totalClaimedPresale[msg.sender] += 1;
        _safeMint(msg.sender, tokenId);

        emit PresaleMint(msg.sender, 1);
    }

    function mintHandpickedPresale(uint256 amountOfSquishes) external payable whenPresaleStarted {
        require(_handpickedEligible[msg.sender], "You are not eligible for the handpicked presale");
        require(totalSupply() + amountOfSquishes <= MAX_SQUISHES - (RESERVED_SQUISHES - reservedClaimed), "Minting would exceed max supply");
        require(_totalClaimedHandpicked[msg.sender] + amountOfSquishes <= HANDPICKED_MAX_MINT, "Purchase exceeds max allowed");
        require(amountOfSquishes > 0, "Must mint at least one squish");
        require(PRICE * amountOfSquishes <= msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfSquishes; i++) {
            uint256 tokenId = numSquishesMinted + 1;

            numSquishesMinted += 1;
            totalClaimed[msg.sender] += 1;
            _totalClaimedHandpicked[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit HandpickedMint(msg.sender, amountOfSquishes);
    }

    function mint(uint256 amountOfSquishes) external payable whenPublicSaleStarted {
        require(totalSupply() + amountOfSquishes <= MAX_SQUISHES - (RESERVED_SQUISHES - reservedClaimed), "Minting would exceed max supply");
        require(totalClaimed[msg.sender] + amountOfSquishes <= MAX_SQUISHES_MINT, "Purchase exceeds max allowed per address");
        require(amountOfSquishes > 0, "Must mint at least one squish");
        require(amountOfSquishes <= MAX_PER_TX, "Amount over max per transaction. ");
        require(PRICE * amountOfSquishes <= msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfSquishes; i++) {
            uint256 tokenId = numSquishesMinted + 1;

            numSquishesMinted += 1;
            totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PublicSaleMint(msg.sender, amountOfSquishes);
    }

    function bulkPurchase(uint256 amountOfSquishes) external payable {
        require(totalSupply() + amountOfSquishes <= MAX_SQUISHES - (RESERVED_SQUISHES - reservedClaimed), "Minting would exceed max supply");
        require(amountOfSquishes > 0, "Must mint at least one squish");
        require(msg.sender == launchpadAddress || msg.sender == donationAddress, "Must be launchpad or donation wallet address");
        require(msg.sender == donationAddress || PRICE * amountOfSquishes <= msg.value, "ETH amount is incorrect");
        require(amountOfSquishes <= 100, "Cannot mint over 200");

        for (uint256 i = 0; i < amountOfSquishes; i++) {
            uint256 tokenId = numSquishesMinted + 1;

            numSquishesMinted += 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    function setMaxTokens(uint256 newMax) external onlyOwner {
        MAX_SQUISHES = newMax;
    } 

    function setNewPrice(uint256 newPriceInWEI) external onlyOwner {
        PRICE = newPriceInWEI;
    }

    function setNewMaxMintPerAddress(uint256 newMax) external onlyOwner {
        MAX_SQUISHES_MINT = newMax;
    }

    function setNewMaxPerTx(uint256 newMax) external onlyOwner {
        MAX_PER_TX = newMax;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(founderAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}