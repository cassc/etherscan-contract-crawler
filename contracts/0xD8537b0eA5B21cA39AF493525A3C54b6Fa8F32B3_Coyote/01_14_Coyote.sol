// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Coyote is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_NFTS = 10000;
    uint256 public constant PRICE_PRE_SALE = 0.1 ether;
    uint256 public constant PRICE_PUBLIC_SALE = 0.2 ether;
    uint256 public constant PRICE_FLOOR = 0.1 ether;
    uint256 public constant PRICE_TICK = 0.02 ether;
    uint256 public constant SECONDS_BETWEEN_TICK = 3600; // 1 hour
    uint256 public constant MAX_PER_MINT = 7;
    uint256 public constant PRESALE_MAX_MINT = 3;
    uint256 public constant MAX_NFTS_MINT = 70;
    uint256 public constant RESERVED_NFTS = 250;
    address public constant daoAddress = 0xa78AdA29f1c8cBECdb3FAf5f00CEa5b661ab7013;
    address public constant teamAddress = 0x2ED93945571344675038fBF92C06094E608bB2FC;
    address public constant founderAddress = 0x46391ED2FC671FF3D76cB3475C742f8691a3c9Cf;
    address public constant projectAddress = 0xb9f2eB35ed71fA2ee90Fa6b08AB16c2828b4D58D;

    uint256 private pricePublicSale = PRICE_PUBLIC_SALE;
    bool private customPrice;

    uint256 public publicSaleStartDate;

    uint256 public reservedClaimed;

    uint256 public numNftsMinted;

    string public baseTokenURI;

    bool public publicSaleStarted;
    bool public presaleStarted;

    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _totalClaimed;

    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 amountOfNfts);
    event PublicSaleMint(address minter, uint256 amountOfNfts);

    modifier whenPresaleStarted() {
        require(presaleStarted, "Presale is not open yet");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(publicSaleStarted, "Public sale is not open yet");
        _;
    }

    constructor(string memory baseURI) ERC721("Billionaire Coyote Cartel", "BCC") {
        baseTokenURI = baseURI;
    }

    function claimReserved(address recipient, uint256 amount) external onlyOwner {
        require(reservedClaimed != RESERVED_NFTS, "You have already claimed all reserved nfts");
        require(reservedClaimed + amount <= RESERVED_NFTS, "Mint exceeds max reserved nfts");
        require(recipient != address(0), "Cannot add null address");
        require(totalSupply() < MAX_NFTS, "All NFTs have been minted");
        require(totalSupply() + amount <= MAX_NFTS, "Mint exceeds max supply");

        uint256 _nextTokenId = numNftsMinted + 1;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(recipient, _nextTokenId + i);
        }
        numNftsMinted += amount;
        reservedClaimed += amount;
    }

    function addToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _presaleEligible[addresses[i]] = true;

            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }

    function getPublicSalePrice() public view returns(uint256) {
        if (!customPrice && publicSaleStarted) {
            uint256 timePassed = block.timestamp - publicSaleStartDate;
            uint256 ticks;
            if (timePassed / SECONDS_BETWEEN_TICK > PRICE_PUBLIC_SALE / PRICE_TICK) {
                ticks = PRICE_PUBLIC_SALE / PRICE_TICK;
            } else {
                ticks = timePassed / SECONDS_BETWEEN_TICK;
            }
            uint256 price = PRICE_PUBLIC_SALE - (ticks * PRICE_TICK);
            
            if (price < PRICE_FLOOR) {
                return PRICE_FLOOR;
            } else {
                return price;
            }
        } else {
            return pricePublicSale;
        }
    }

    function checkPresaleEligiblity(address addr) external view returns (bool) {
        return _presaleEligible[addr];
    }

    function amountClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Cannot add null address");

        return _totalClaimed[owner];
    }

    function mintPresale(uint256 amountOfNfts) external payable whenPresaleStarted {
        require(_presaleEligible[msg.sender], "You are not whitelisted for the presale");
        require(totalSupply() < MAX_NFTS, "All NFTs have been minted");
        require(amountOfNfts <= PRESALE_MAX_MINT, "Purchase exceeds presale limit");
        require(totalSupply() + amountOfNfts <= MAX_NFTS, "Mint exceeds max supply");
        require(_totalClaimed[msg.sender] + amountOfNfts <= PRESALE_MAX_MINT, "Purchase exceeds max allowed");
        require(amountOfNfts > 0, "Must mint at least one NFT");
        require(PRICE_PRE_SALE * amountOfNfts == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfNfts; i++) {
            uint256 tokenId = numNftsMinted + 1;

            numNftsMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PresaleMint(msg.sender, amountOfNfts);
    }
    
    function updatePrice() private {
        uint256 price = getPublicSalePrice();
        pricePublicSale = price;
    }

    function mint(uint256 amountOfNfts) external payable whenPublicSaleStarted {
        updatePrice();
        
        require(totalSupply() < MAX_NFTS, "All NFTs have been minted");
        require(amountOfNfts <= MAX_PER_MINT, "Amount exceeds NFTs per transaction");
        require(totalSupply() + amountOfNfts <= MAX_NFTS, "Mint exceeds max supply");
        require(_totalClaimed[msg.sender] + amountOfNfts <= MAX_NFTS_MINT, "Amount exceeds max NFTs per wallet");
        require(amountOfNfts > 0, "Must mint at least one NFT");
        require(pricePublicSale * amountOfNfts == msg.value, "Amount of ETH is incorrect");

        for (uint256 i = 0; i < amountOfNfts; i++) {
            uint256 tokenId = numNftsMinted + 1;

            numNftsMinted += 1;
            _totalClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }

        emit PublicSaleMint(msg.sender, amountOfNfts);
    }

    function togglePresaleStarted() external onlyOwner {
        presaleStarted = !presaleStarted;
    }
    
    function setPrice(uint256 _price) external onlyOwner {
        pricePublicSale = _price;
        
        customPrice = true;
    }

    function togglePublicSaleStarted() external onlyOwner {
        publicSaleStarted = !publicSaleStarted;
        
        if (publicSaleStarted) {
            publicSaleStartDate = block.timestamp;
            customPrice = false;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(daoAddress, ((balance * 50) / 100));
        _widthdraw(teamAddress, ((balance * 15) / 100));
        _widthdraw(founderAddress, ((balance * 15) / 100));
        _widthdraw(projectAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}