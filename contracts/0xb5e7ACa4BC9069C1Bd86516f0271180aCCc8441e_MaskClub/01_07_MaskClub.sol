// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MaskClub is Ownable, ERC721A, ReentrancyGuard {
    uint256 internal immutable collectionSize = 6000;
    uint256 internal immutable viplistMaxSize = 500;
    uint256 internal immutable allowlistMaxSize = 4500;

    uint256 public immutable maxPerAddressDuringMint = 2;

    struct SaleConfig {
        uint64 viplistPrice;
        uint32 viplistSaleStartTime;
        uint32 viplistSaleEndTime;
        uint64 allowlistPrice;
        uint32 allowlistSaleStartTime;
        uint32 allowlistSaleEndTime;
        uint64 publicPrice;
        uint32 publicSaleStartTime;
    }

    SaleConfig public saleConfig;
    mapping(address => uint256) public viplist;
    mapping(address => uint256) public allowlist;
    mapping(address => uint256) private _pubilcMintData;

    constructor() ERC721A("MaskClub", "MASKCLUB") {
        saleConfig.viplistPrice = 0.04 ether;
        saleConfig.viplistSaleStartTime = 1662188400;
        saleConfig.viplistSaleEndTime = 1662195600;
        saleConfig.allowlistPrice = 0.08 ether;
        saleConfig.allowlistSaleStartTime = 1662210000;
        saleConfig.allowlistSaleEndTime = 1662220800;
        saleConfig.publicPrice = 0.12 ether;
        saleConfig.publicSaleStartTime = 1662296400;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function vipMint() external payable callerIsUser {
        uint256 price = uint256(saleConfig.viplistPrice);
        uint256 viplistSaleStartTime = uint256(saleConfig.viplistSaleStartTime);
        uint256 viplistSaleEndTime = uint256(saleConfig.viplistSaleEndTime);
        require(price != 0, "vip sale has not begun yet");
        require(
            block.timestamp >= viplistSaleStartTime,
            "viplist sale has not begun yet"
        );
        require(
            block.timestamp <= viplistSaleEndTime,
            "viplist sale has ended"
        );
        require(viplist[msg.sender] > 0, "not eligible for vip mint");
        require(
            totalSupply() + 1 <= viplistMaxSize,
            "reached max viplist supply"
        );
        viplist[msg.sender]--;
        _safeMint(msg.sender, 1);
        refundIfOver(price);
    }

    function allowlistMint(uint256 quantity) external payable callerIsUser {
        uint256 price = uint256(saleConfig.allowlistPrice);
        uint256 allowlistSaleStartTime = uint256(
            saleConfig.allowlistSaleStartTime
        );
        uint256 allowlistSaleEndTime = uint256(saleConfig.allowlistSaleEndTime);
        require(price != 0, "allowlist sale has not begun yet");
        require(
            block.timestamp >= allowlistSaleStartTime,
            "allowlist sale has not begun yet"
        );
        require(
            block.timestamp <= allowlistSaleEndTime,
            "allowlist sale has ended"
        );
        require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
        require(
            allowlist[msg.sender] >= quantity,
            "not eligible for allowlist mint"
        );
        require(
            totalSupply() + quantity <= allowlistMaxSize,
            "reached max allowlist supply"
        );
        allowlist[msg.sender] = allowlist[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(price * quantity);
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 publicPrice = uint256(config.publicPrice);
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);

        require(
            isPublicSaleOn(publicPrice, publicSaleStartTime),
            "public sale has not begun yet"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
            publicMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
        uint256 publicMintedNum = _pubilcMintData[msg.sender];
        _pubilcMintData[msg.sender] = publicMintedNum + quantity;
        refundIfOver(publicPrice * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function seedViplist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            viplist[addresses[i]] = 1;
        }
    }

    function seedAllowlist(
        address[] memory addresses,
        uint256[] memory numSlots
    ) external onlyOwner {
        require(
            addresses.length == numSlots.length,
            "addresses does not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    function isPublicSaleOn(uint256 publicPriceWei, uint256 publicSaleStartTime)
        public
        view
        returns (bool)
    {
        return publicPriceWei != 0 && block.timestamp >= publicSaleStartTime;
    }

    function setupViplistSaleInfo(
        uint64 viplistPriceWei,
        uint32 viplistSaleStartTime,
        uint32 viplistSaleEndTime
    ) external onlyOwner {
        saleConfig.viplistPrice = viplistPriceWei;
        saleConfig.viplistSaleStartTime = viplistSaleStartTime;
        saleConfig.viplistSaleEndTime = viplistSaleEndTime;
    }

    function setupAllowlistSaleInfo(
        uint64 allowlistPriceWei,
        uint32 allowlistSaleStartTime,
        uint32 allowlistSaleEndTime
    ) external onlyOwner {
        saleConfig.allowlistPrice = allowlistPriceWei;
        saleConfig.allowlistSaleStartTime = allowlistSaleStartTime;
        saleConfig.allowlistSaleEndTime = allowlistSaleEndTime;
    }

    function setupPublicSaleInfo(
        uint64 publicPriceWei,
        uint32 publicSaleStartTime
    ) external onlyOwner {
        saleConfig.publicPrice = publicPriceWei;
        saleConfig.publicSaleStartTime = publicSaleStartTime;
    }

    // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = payable(0x8B8f502D1C74Df89b1C274669926707EA9E8daB5)
            .call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function publicMinted(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "number minted query for the zero address"
        );
        return uint256(_pubilcMintData[owner]);
    }
}