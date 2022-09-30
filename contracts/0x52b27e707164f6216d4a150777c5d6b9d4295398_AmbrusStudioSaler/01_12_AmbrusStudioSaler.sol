// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IMintable.sol";

contract AmbrusStudioSaler is AccessControl {
    struct SaleConfig {
        uint32 start;
        uint32 end;
        uint8 discount;
        bytes32 merkleRoot;
    }
    struct FlashSaleConfig {
        uint32 start;
        uint32 end;
        uint8 discount;
        uint16 count;
    }

    using Strings for uint256;

    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    address public nft;
    uint16 public count;
    uint256 public basePrice;

    SaleConfig public permitSaleConfig;
    SaleConfig public whitelistSaleConfig;
    FlashSaleConfig public flashSaleConfig;

    uint32 public publicSaleStart;
    uint32 public publicSaleEnd;

    uint16 public soldCount;
    uint16 public flashSaleSoldCount;

    mapping(address => uint256) public permitSaleCount;
    mapping(address => uint256) public whitelistSaleCount;

    constructor(
        address _nft,
        uint16 _count
    ) {
        nft = _nft;
        count = _count;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setBasePrice(uint256 _basePrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        basePrice = _basePrice;
    }
    function setPublicSaleTime(uint32 start, uint32 end) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicSaleStart = start;
        publicSaleEnd = end;
    }

    function permitSalePrice() external view returns (uint256) {
        return basePrice - basePrice * permitSaleConfig.discount / 100;
    }
    function setPermitSaleTime(uint32 start, uint32 end) external onlyRole(DEFAULT_ADMIN_ROLE) {
        permitSaleConfig.start = start;
        permitSaleConfig.end = end;
    }
    function setPermitSaleDiscount(uint8 discount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        permitSaleConfig.discount = discount;
    }
    function setPermitSaleMerkleRoot(bytes32 merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        permitSaleConfig.merkleRoot = merkleRoot;
    }

    function permitSale(bytes32[] calldata signature) external payable {
        require(permitSaleCount[msg.sender] < 2, "Exceeds purchase limit");
        permitSaleCount[msg.sender] += 1;
        _restrictedSale(permitSaleConfig, signature);
    }

    function whitelistSalePrice() external view returns (uint256) {
        return basePrice - basePrice * whitelistSaleConfig.discount / 100;
    }
    function setWhitelistSaleTime(uint32 start, uint32 end) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistSaleConfig.start = start;
        whitelistSaleConfig.end = end;
    }
    function setWhitelistSaleDiscount(uint8 discount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistSaleConfig.discount = discount;
    }
    function setWhitelistSaleMerkleRoot(bytes32 merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistSaleConfig.merkleRoot = merkleRoot;
    }

    function whitelistSale(bytes32[] calldata signature) external payable {
        require(whitelistSaleCount[msg.sender] < 2, "Exceeds purchase limit");
        whitelistSaleCount[msg.sender] += 1;
        _restrictedSale(whitelistSaleConfig, signature);
    }

    function _restrictedSale(SaleConfig memory config, bytes32[] calldata signature) private {
        require(block.timestamp >= config.start, "Sale not start");
        require(block.timestamp < config.end, "Sale has ended");
        require(isAccountAllowed(msg.sender, config.merkleRoot, signature), "You're not allowed to buy");
        require(msg.value == (basePrice - basePrice * config.discount / 100), "Sent value not equal to price");

        _sale();
    }
    function isAccountAllowed(address account, bytes32 merkleRoot, bytes32[] calldata signature) public pure returns (bool) {
        if (merkleRoot == "") {
            return false;
        }

        return MerkleProof.verify(signature, merkleRoot, keccak256(abi.encodePacked(account)));
    }

    function flashSalePrice() external view returns (uint256) {
        return basePrice - basePrice * flashSaleConfig.discount / 100;
    }
    function setFlashSaleTime(uint32 start, uint32 end) external onlyRole(DEFAULT_ADMIN_ROLE) {
        flashSaleConfig.start = start;
        flashSaleConfig.end = end;
    }
    function setFlashSaleDiscount(uint8 discount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        flashSaleConfig.discount = discount;
    }
    function setFlashSaleCount(uint16 _count) external onlyRole(DEFAULT_ADMIN_ROLE) {
        flashSaleConfig.count = _count;
    }

    function flashSale() external payable {
        require(block.timestamp >= flashSaleConfig.start, "Flash sale not start");
        require(block.timestamp < flashSaleConfig.end, "Flash sale has ended");
        require(flashSaleSoldCount < flashSaleConfig.count, "Flash sale sold out");
        require(msg.value == (basePrice - basePrice * flashSaleConfig.discount / 100), "Sent value not equal to price");

        flashSaleSoldCount = flashSaleSoldCount + 1;
        _sale();
    }

    function _sale() private {
        require(soldCount < count, "Sold out");

        soldCount = soldCount + 1;
        uint256 tokenId = soldCount;
        IMintable(nft).mintFor(msg.sender, 1, abi.encodePacked("{", tokenId.toString(), "}:{}"));
    }

    function mintRemaining(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(block.timestamp >= publicSaleStart, "Public sale not start");

        uint256 tokenId = soldCount + 1;
        while (tokenId <= count) {
            IMintable(nft).mintFor(account, 1, abi.encodePacked("{", tokenId.toString(), "}:{}"));
            tokenId = tokenId + 1;
        }

        soldCount = count;
    }

    function withdraw(address account) external onlyRole(WITHDRAWER_ROLE) {
        payable(account).transfer(address(this).balance);
    }

    receive() external payable { }
}