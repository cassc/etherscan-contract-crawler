//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract YINJAClubV2 is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;
    using AddressUpgradeable for address;

    function initialize(
        uint256 _maxSupplyAmount,
        uint256 _amountForTeam,
        address _team
    ) public initializer {
        _nextId = 1;
        team = _team;
        amountForTeam = _amountForTeam;
        maxSupplyAmount = _maxSupplyAmount;

        __ERC721_init("YINJA Club", "YINJA");
        __Ownable_init();
        __ERC721Enumerable_init();
        __ReentrancyGuard_init();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "YINJA Club: URI query for nonexistent token"
        );
        if (tokenId > revealConfig.idx) {
            return revealConfig.uri;
        }
        string memory baseURI;
        if (tokenId <= 1000) {
            baseURI = baseTokenURIs[0];
        } else if (tokenId <= 2000) {
            baseURI = baseTokenURIs[1];
        } else if (tokenId <= 3000) {
            baseURI = baseTokenURIs[2];
        } else if (tokenId <= 4000) {
            baseURI = baseTokenURIs[3];
        } else if (tokenId <= 5000) {
            baseURI = baseTokenURIs[4];
        } else if (tokenId <= 6000) {
            baseURI = baseTokenURIs[5];
        } else if (tokenId <= 7000) {
            baseURI = baseTokenURIs[6];
        } else if (tokenId <= 8000) {
            baseURI = baseTokenURIs[7];
        } else if (tokenId <= 9000) {
            baseURI = baseTokenURIs[8];
        } else {
            baseURI = baseTokenURIs[9];
        }
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setTeamAddress(address _team) external onlyOwner {
        team = _team;
    }

    function setSaleSupplyAmount(uint256 _amount) external onlyOwner {
        saleSupplyAmount = _amount;
    }

    function setBaseTokenURIs(string[] memory _baseTokenURIs)
        external
        onlyOwner
    {
        require(
            _baseTokenURIs.length == 10,
            "YINJA Club: setBaseTokenURIs failed"
        );
        for (uint256 idx = 0; idx < _baseTokenURIs.length; idx++) {
            baseTokenURIs.push(_baseTokenURIs[idx]);
        }
    }

    function setFreemintSaleConfig(WhitelistSaleConfig memory config)
        external
        onlyOwner
    {
        freemintSaleConfig.saleStartTime = config.saleStartTime;
        freemintSaleConfig.maxPerAddressDuringMint = config
            .maxPerAddressDuringMint;
        freemintSaleConfig.price = config.price;
        freemintSaleConfig.merkleRoot = config.merkleRoot;
    }

    function setDiscountSaleConfig(WhitelistSaleConfig memory config)
        external
        onlyOwner
    {
        require(config.price > 0, "YINJA Club: config price 0");
        discountSaleConfig.saleStartTime = config.saleStartTime;
        discountSaleConfig.maxPerAddressDuringMint = config
            .maxPerAddressDuringMint;
        discountSaleConfig.price = config.price;
        discountSaleConfig.merkleRoot = config.merkleRoot;
    }

    function setFullpriceSaleConfig(WhitelistSaleConfig memory config)
        external
        onlyOwner
    {
        require(config.price > 0, "YINJA Club: config price 0");
        fullpriceSaleConfig.saleStartTime = config.saleStartTime;
        fullpriceSaleConfig.maxPerAddressDuringMint = config
            .maxPerAddressDuringMint;
        fullpriceSaleConfig.price = config.price;
        fullpriceSaleConfig.merkleRoot = config.merkleRoot;
    }

    function setRevealConfig(RevealConfig memory config) external onlyOwner {
        revealConfig.idx = config.idx;
        revealConfig.uri = config.uri;
    }

    function setPublicSaleConfig(PublicSaleConfig memory config)
        external
        onlyOwner
    {
        require(config.price > 0, "YINJA Club: config price 0");
        publicSaleConfig.saleStartTime = config.saleStartTime;
        publicSaleConfig.maxPerAddressDuringMint = config
            .maxPerAddressDuringMint;
        publicSaleConfig.price = config.price;
    }

    function freeMintForEveryOne() external nonReentrant {
        // feel free to mint, enjoy it!
        require(
            totalSupply() + 1 <= saleSupplyAmount,
            "YINJAClub: maximum mint number"
        );
        require(
            numberMinted[msg.sender] == 0,
            "YINJAClub: everyone can only freemint once"
        );
        numberMinted[msg.sender] += 1;
        _safeMint(msg.sender, _nextId++);

        emit FreeMintForEveryOne(msg.sender);
    }

    function refundIfOver(uint256 amount) private {
        require(msg.value >= amount, "YinJa Club: need to send more ETH");
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);
        }
    }

    function withdrawFund() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(team).transfer(balance);
        }
    }

    uint256 private _nextId;

    uint256 public whitelistSaleStartTime;
    uint256 public whitelistMaxPerMinted;
    uint256 whitelistSalePrice;
    bytes32 whitelistMerkleRoot;

    uint256 private maxSupplyAmount;
    uint256 private amountForTeam;
    string baseTokenURI;
    address private team;

    uint256 revealStartTime;
    string revealedURI;

    // new variables and useful
    struct WhitelistSaleConfig {
        uint256 saleStartTime;
        uint256 maxPerAddressDuringMint;
        uint256 price;
        bytes32 merkleRoot;
    }

    struct RevealConfig {
        uint256 idx;
        string uri;
    }

    struct PublicSaleConfig {
        uint256 saleStartTime;
        uint256 maxPerAddressDuringMint;
        uint256 price;
    }

    enum AddressMintType {
        PUBLIC_SALE_MINT, // placeholder
        WL_FREE_MINT,
        WL_DISCOUNT_MINT,
        WL_FULL_PRICE_MINT
    }

    PublicSaleConfig public publicSaleConfig;
    WhitelistSaleConfig public discountSaleConfig;
    WhitelistSaleConfig public freemintSaleConfig;
    WhitelistSaleConfig public fullpriceSaleConfig;
    RevealConfig public revealConfig;
    string[] private baseTokenURIs;
    mapping(address => uint256) public numberMinted;
    uint256 public saleSupplyAmount;

    event WhitelistMinted(
        bool isFreemint,
        bool isDiscount,
        address user,
        uint256 quantity
    );
    event TeamMinted(address user, uint256 quantity);
    event PublicMinted(address user, uint256 quantity);
    event AirdropMinted(address user);
    event FreeMintForEveryOne(address user);

    receive() external payable {}
}