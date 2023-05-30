// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// @title:  CRYPTOPUPPETS
// @desc:   LAPO FATAI ICONIC CHARACTER
// @artist: https://www.instagram.com/lapofatai
// @team:   https://cryptopuppets.io
// @author: https://medusa.dev
// @url:    https://cryptopuppets.io

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CryptoPuppets is Ownable, ERC721Enumerable, IERC2981, ReentrancyGuard {
    event PresaleEnabled();
    event PublicSaleEnabled();
    event SaleEnded();
    event MetadataRevealed();
    event TokenMinted();

    uint256 private constant MAX_SUPPLY = 111;
    uint256 private constant NUM_RESERVED = 11;
    uint256 private constant MAX_WHITELISTED = 30;

    bool private isReservedMinted;
    struct Whitelist {
        mapping(address => bool) map;
        uint256 length;
    }
    Whitelist private whitelist;
    mapping(address => bool) private hasMinted;

    uint256 public constant PRESALE_MINT_COST = 0.1 ether;
    uint256 public constant PUBLIC_SALE_MINT_COST = 0.15 ether;
    bool public isMetadataLocked;
    bool public isMetadataRevealed;
    bool public isPresale;
    bool public isPublicSale;
    bool public hasSaleEnded;
    address public royaltyReceiver;
    uint256 public royaltyPercentage;
    string public baseURI;
    string public unrevealedTokenURI;

    constructor(string memory unrevealedTokenURI_)
        ERC721("CryptoPuppets", "CPPT")
    {
        unrevealedTokenURI = unrevealedTokenURI_;
        royaltyReceiver = owner();
        royaltyPercentage = 800;
    }

    function isWhitelisted(address addr) public view returns (bool) {
        return whitelist.map[addr];
    }

    function addWhitelisted(address[] memory newWhitelisted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < newWhitelisted.length; i++) {
            if (!whitelist.map[newWhitelisted[i]]) {
                require(
                    whitelist.length + 1 <= MAX_WHITELISTED,
                    "Max whitelist length reached"
                );
                whitelist.map[newWhitelisted[i]] = true;
                whitelist.length++;
            }
        }
    }

    function didMint(address addr) public view returns (bool) {
        return hasMinted[addr];
    }

    function enablePresale() external onlyOwner {
        require(!hasSaleEnded, "Sale ended");
        require(isReservedMinted, "Reserved tokens not minted");
        isPresale = true;
        emit PresaleEnabled();
    }

    function enablePublicSale() external onlyOwner {
        require(!hasSaleEnded, "Sale ended");
        require(isPresale, "Presale still did not start");
        isPublicSale = true;
        emit PublicSaleEnabled();
    }

    function mintReserved(address[NUM_RESERVED] memory addresses)
        external
        onlyOwner
        nonReentrant
    {
        for (uint256 index = 0; index < NUM_RESERVED; index++) {
            _safeMint(addresses[index], index + 1);
        }
        isReservedMinted = true;
    }

    function whitelistedMint() external payable nonReentrant {
        require(!hasSaleEnded, "Sale ended");
        require(isPresale, "Presale is not enabled");
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        require(whitelist.map[msg.sender], "Address not whitelisted");
        require(!hasMinted[msg.sender], "Max one mint per address");
        require(msg.value >= PRESALE_MINT_COST, "Not enough ETH");

        if (totalSupply() + 1 == MAX_SUPPLY) {
            isPresale = false;
            isPublicSale = false;
            hasSaleEnded = true;
            emit SaleEnded();
        }

        hasMinted[msg.sender] = true;
        if (msg.value > PRESALE_MINT_COST) {
            payable(msg.sender).transfer(msg.value - PRESALE_MINT_COST);
        }
        _safeMint(msg.sender, totalSupply() + 1);
        emit TokenMinted();
    }

    function publicSaleMint() external payable nonReentrant {
        require(!hasSaleEnded, "Sale ended");
        require(isPublicSale, "Public sale is not enabled");
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        require(!hasMinted[msg.sender], "Max one mint per address");
        require(msg.value >= PUBLIC_SALE_MINT_COST, "Not enough ETH");

        if (totalSupply() + 1 == MAX_SUPPLY) {
            isPresale = false;
            isPublicSale = false;
            hasSaleEnded = true;
            emit SaleEnded();
        }

        hasMinted[msg.sender] = true;
        if (msg.value > PUBLIC_SALE_MINT_COST) {
            payable(msg.sender).transfer(msg.value - PUBLIC_SALE_MINT_COST);
        }
        _safeMint(msg.sender, totalSupply() + 1);
        emit TokenMinted();
    }

    function endSale() external onlyOwner {
        require(!hasSaleEnded, "Sale already ended");

        while (totalSupply() < MAX_SUPPLY) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
        isPresale = false;
        isPublicSale = false;
        hasSaleEnded = true;
        emit SaleEnded();
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(msg.sender).transfer(balance);
    }

    function lockMetadata() external onlyOwner {
        require(!isMetadataLocked, "Metadata are already locked");
        require(isMetadataRevealed, "Metadata are not revealed");
        isMetadataLocked = true;
    }

    function revealMetadata() external onlyOwner {
        require(!isMetadataRevealed, "Metadata are already revealed");
        isMetadataRevealed = true;
        emit MetadataRevealed();
    }

    function setRoyaltyReceiver(address royaltyReceiver_) external onlyOwner {
        royaltyReceiver = royaltyReceiver_;
    }

    function setRoyaltyPercentage(uint256 royaltyPercentage_)
        external
        onlyOwner
    {
        require(royaltyPercentage_ <= 10000, "Royalty percentage Too high");
        royaltyPercentage = royaltyPercentage_;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (royaltyReceiver, (salePrice * royaltyPercentage) / 10000);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return
            isMetadataRevealed ? super.tokenURI(tokenId) : unrevealedTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        require(!isMetadataLocked, "Metadata are locked");
        baseURI = baseURI_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}