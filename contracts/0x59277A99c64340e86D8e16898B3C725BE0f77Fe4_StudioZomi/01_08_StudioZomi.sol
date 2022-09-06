// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract StudioZomi is ERC721A, Ownable {
    struct WalletInfo {
        uint64 whitelistMints;
        uint64 friendsMints;
        uint64 publicMints;
    }

    uint256 public constant MAX_SUPPLY = 6666;
    uint256 public constant MAX_FRIEND_MINTS = 5266;
    uint256 public constant MAX_PUBLIC_MINT = 3;
    uint256 public constant WHITELIST_PRICE = 0.05 ether;
    uint256 public constant PUBLIC_PRICE = 0.075 ether;

    mapping(address => WalletInfo) public walletInfo;

    string public baseURI;
    bool public isCollectionSealed;
    uint256 public friendMints;
    bytes32 public whitelistMerkleRoot;
    bytes32 public zomiFriendsMerkleRoot;
    uint256 public privateSaleStartTime = type(uint256).max;
    uint256 public publicSaleStartTime = type(uint256).max;
    uint256 public mintCloseTime = type(uint256).max;

    constructor() ERC721A("Studio Zomi", "ZOMI") {
        _mintBanner(msg.sender, 100);
    }

    function whitelistMint(
        uint64 amount,
        uint64 maxAmount,
        bytes32[] calldata proof
    ) external payable {
        require(block.timestamp > privateSaleStartTime, "private sale not started");
        require(_verify(whitelistMerkleRoot, maxAmount, proof), "invalid proof");
        require(msg.value == amount * WHITELIST_PRICE, "wrong eth value");

        WalletInfo memory _walletInfo = walletInfo[msg.sender];
        require(_walletInfo.whitelistMints + amount <= maxAmount, "already minted");
        walletInfo[msg.sender].whitelistMints += amount;

        _mintBanner(msg.sender, amount);
    }

    function friendsMint(
        uint64 amount,
        uint64 maxAmount,
        bytes32[] calldata proof
    ) external payable {
        require(block.timestamp > privateSaleStartTime, "private sale not started");
        require(_verify(zomiFriendsMerkleRoot, maxAmount, proof), "invalid proof");
        require(msg.value == amount * PUBLIC_PRICE, "wrong eth value");
        require(friendMints + amount < MAX_FRIEND_MINTS, "max friends");

        WalletInfo memory _walletInfo = walletInfo[msg.sender];
        require(_walletInfo.friendsMints + amount <= maxAmount, "already minted");
        walletInfo[msg.sender].friendsMints += amount;
        friendMints += amount;

        _mintBanner(msg.sender, amount);
    }

    function publicMint(uint64 amount) external payable {
        require(block.timestamp > publicSaleStartTime, "public sale not started");
        require(msg.value == amount * PUBLIC_PRICE, "wrong eth value");

        WalletInfo memory _walletInfo = walletInfo[msg.sender];
        require(_walletInfo.publicMints + amount <= MAX_PUBLIC_MINT, "already minted");
        walletInfo[msg.sender].publicMints += amount;

        _mintBanner(msg.sender, amount);
    }

    function getMintStatus()
        external
        view
        returns (
            bool isPrivateOpen,
            bool isPublicOpen,
            bool isClosed,
            uint256 mintedSupply
        )
    {
        isPrivateOpen = block.timestamp > privateSaleStartTime;
        isPublicOpen = block.timestamp > publicSaleStartTime;
        isClosed = block.timestamp > mintCloseTime;
        mintedSupply = totalSupply();
    }

    function _mintBanner(address to, uint64 amount) internal {
        require(block.timestamp < mintCloseTime, "mint closed");
        require(totalSupply() + amount <= MAX_SUPPLY, "sold out");
        _mint(to, amount);
    }

    function _verify(
        bytes32 merkleRoot,
        uint256 amount,
        bytes32[] calldata proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    // OWNER FUNCTIONS
    function withdraw() external onlyOwner {
        address anonymice = 0x77fd294DF4Ae46faF6Aecd7E4Eed469739011b66;
        address treasury = 0x884Cf92C98934EF318756e8E94509Fa23c8a9366;
        address artist = 0xffE6830eE2e4CAF60911bcb623038c21B49aAab6;

        uint256 total = address(this).balance;
        Address.sendValue(payable(anonymice), (total * 17 gwei) / 100 gwei); // 17% anonymice
        Address.sendValue(payable(treasury), (total * 50 gwei) / 100 gwei); // 50% treasury
        Address.sendValue(payable(artist), (total * 33 gwei) / 100 gwei); // 33% artist
    }

    function emergencyWithdraw() external onlyOwner {
        address multisig = 0x70437CF59490803a1D3EE426c09f838Df33989DA;

        uint256 total = address(this).balance;
        Address.sendValue(payable(multisig), total);
    }

    function setZomiFriendsMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        zomiFriendsMerkleRoot = merkleRoot;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setBaseURI(string memory value) external onlyOwner {
        require(!isCollectionSealed, "sealed");
        baseURI = value;
    }

    function sealCollection() external onlyOwner {
        isCollectionSealed = true;
    }

    function setSaleTimes(
        uint256 _privateSaleStartTime,
        uint256 _publicSaleStartTime,
        uint256 _mintCloseTime
    ) external onlyOwner {
        privateSaleStartTime = _privateSaleStartTime;
        publicSaleStartTime = _publicSaleStartTime;
        mintCloseTime = _mintCloseTime;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}