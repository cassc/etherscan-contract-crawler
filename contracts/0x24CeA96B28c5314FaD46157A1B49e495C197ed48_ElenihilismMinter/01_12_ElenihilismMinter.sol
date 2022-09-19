// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";

contract ElenihilismMinter is Ownable, AccessControl {
  
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");
    address public elenihilism;
    string public metadataUri;
    uint256 public price = 0.08 ether;
    uint256 public discountedPrice = 0.06 ether;
    uint256 public currentDropIndex = 0;
    mapping(uint256 => DropInfo) public drops;

    struct DropInfo {
        // Configuration
        bool mintActive;
        uint walletLimit;
        bytes32 merkleRoot;

        // Tracking
        uint mintsAvailable;
        uint reservedMintsAvailable;
        mapping(address => uint) totalMinted;
        mapping(bytes32 => bool) reservationClaimed; 
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SUPPORT_ROLE, msg.sender);
    }

    function mint() external payable {
        DropInfo storage drop = drops[currentDropIndex];
        require(drop.mintActive, "Mint is not active");
        require(msg.value == price, "Incorrect ether amount sent");
        require(drop.mintsAvailable > 0, "No mints available");
        require(drop.totalMinted[msg.sender] < drop.walletLimit, "Over wallet limit");
        IERC721CreatorCore(elenihilism).mintBase(msg.sender, metadataUri);
        drop.mintsAvailable--;
        drop.totalMinted[msg.sender]++;
    }

    function mintWithDiscount(bytes32[] memory proof) external payable {
        DropInfo storage drop = drops[currentDropIndex];
        require(drop.mintActive, "Mint is not active");
        require(msg.value == discountedPrice, "Incorrect ether amount sent");
        require(drop.mintsAvailable > 0, "No mints available");
        require(drop.totalMinted[msg.sender] < drop.walletLimit, "Over wallet limit");
        require(drop.merkleRoot != bytes32(0), "Merkle root not set");
        require(MerkleProof.verify(proof, drop.merkleRoot, keccak256(abi.encodePacked(msg.sender, "discounted", msg.value))), "Invalid proof");
        IERC721CreatorCore(elenihilism).mintBase(msg.sender, metadataUri);
        drop.mintsAvailable--;
        drop.totalMinted[msg.sender]++;
    }

    function reservedMint(bytes32[] memory proof) external payable {
        DropInfo storage drop = drops[currentDropIndex];
        require(drop.mintActive, "Mint is not active");
        require(drop.reservedMintsAvailable > 0, "No mints available");
        require(drop.merkleRoot != bytes32(0), "Merkle root not set");
        require(drop.totalMinted[msg.sender] < drop.walletLimit, "Over wallet limit");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, "reserved", msg.value));
        require(!drop.reservationClaimed[leaf], "Reservation already claimed");
        require(MerkleProof.verify(proof, drop.merkleRoot, leaf), "Invalid proof");
        IERC721CreatorCore(elenihilism).mintBase(msg.sender, metadataUri);
        drop.reservedMintsAvailable--;
        drop.reservationClaimed[leaf] = true;
        drop.totalMinted[msg.sender]++;
    }

    function gift() external onlyRole(SUPPORT_ROLE) {
        IERC721CreatorCore(elenihilism).mintBase(msg.sender, metadataUri);
    }

    function setMetadataUri(string memory metadataUri_) external onlyRole(SUPPORT_ROLE) {
        metadataUri = metadataUri_;
    }

    function setPrice(uint256 price_) external onlyRole(SUPPORT_ROLE) {
        price = price_;
    }

    function setDiscountedPrice(uint256 discountedPrice_) external onlyRole(SUPPORT_ROLE) {
        discountedPrice = discountedPrice_;
    }

    function setElenihilism(address elenihilism_) external onlyRole(SUPPORT_ROLE) {
        elenihilism = elenihilism_;
    }

    function newDrop(
        bytes32 merkleRoot_, 
        uint256 mintsAvailable_, 
        uint256 reservedMintsAvailable_,
        uint256 walletLimit_,
        bool mintActive_) external onlyRole(SUPPORT_ROLE) {
        currentDropIndex++;
        DropInfo storage drop = drops[currentDropIndex];
        drop.merkleRoot = merkleRoot_;
        drop.mintsAvailable = mintsAvailable_;
        drop.reservedMintsAvailable = reservedMintsAvailable_;
        drop.walletLimit = walletLimit_;
        drop.mintActive = mintActive_;
    }

    function setWalletLimit(uint256 walletLimit_) external onlyRole(SUPPORT_ROLE) {
        drops[currentDropIndex].walletLimit = walletLimit_;
    }

    function setMintActive(bool mintActive_) external onlyRole(SUPPORT_ROLE) {
        drops[currentDropIndex].mintActive = mintActive_;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyRole(SUPPORT_ROLE) {
        drops[currentDropIndex].merkleRoot = merkleRoot_;
    }

    function setMintsAvailable(uint256 mintsAvailable_) external onlyRole(SUPPORT_ROLE) {
        drops[currentDropIndex].mintsAvailable = mintsAvailable_;
    }

    function setReservedMintsAvailable(uint256 reservedMintsAvailable_) external onlyRole(SUPPORT_ROLE) {
        drops[currentDropIndex].reservedMintsAvailable = reservedMintsAvailable_;
    }

    function mintsAvailable() external view returns (uint256) {
        return drops[currentDropIndex].mintsAvailable;
    }

    function mintActive() external view returns (bool) {
        return drops[currentDropIndex].mintActive;
    }

    function reservedMintsAvailable() external view returns (uint256) {
        return drops[currentDropIndex].reservedMintsAvailable;
    }

    function merkleRoot() external view returns (bytes32) {
        return drops[currentDropIndex].merkleRoot;
    }

    function totalMinted(address addr) external view returns (uint256) {
        return drops[currentDropIndex].totalMinted[addr];
    }

    function reservationClaimed(address addr, uint256 value) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr, "reserved", value));
        return drops[currentDropIndex].reservationClaimed[leaf];
    }

    function walletLimit() external view returns (uint256) {
        return drops[currentDropIndex].walletLimit;
    }

    function releaseFunds() external onlyRole(SUPPORT_ROLE) {
        uint balance = address(this).balance;
        uint eleni = balance / 100 * 85;
        uint dev = balance / 100 * 15;
        Address.sendValue(payable(0xD4dcDaaa97E3891aA8e9842A328ED739d7aF136E), eleni);
        Address.sendValue(payable(0xBc3B2d37c5B32686b0804a7d6A317E15173d10A7), dev);
    }
}