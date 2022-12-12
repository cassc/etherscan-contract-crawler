// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./INFCStorage.sol";

contract NFC2023 is ERC721, ERC721Enumerable, ERC2981, Ownable {

    /*
    This smart contract has been handcrafted by OpenGem for The Non Fungible Conference 2023 event.
    OpenGem provides tools for users and developers to secure ownership of digital assets. We also advice leading organizations by performing audits on their products.

    https://opengem.com
    */

   using Strings for uint256;

    string public constant NFT_INFO = "Access to the Non-Fungible Conference on June 7th & 8th, 2023 from 9am-6pm on both days. This ArtWork is the first collaboration between @CarlosMarcialt and @Coldie. Thanks to @Basileus, @CultCryptoArt who are co-editing the conference. Please Follow @NFCSummit before the conference to get instruction about how to redeem your ticket.";
    string public constant METADATA_ARWEAVE = "https://arweave.net/gKziK0nzZBVFgWaR4nROXezKUTMdbmZdc-U-5xuNmvI";
    string public constant METADATA_IPFS ="https://gateway.pinata.cloud/ipfs/QmQQKwrrHac3cBDVf1r66rJ5xhATkvEmRvPM7RwTtFCsKX";
    string public constant METADATA_ANIMATION_PROVENANCE = "d6357cf6261516ad796bde082f473fdbeeab66b5221044e0c91cc58ef4516ba3";
    
    INFCStorage storageContract;
    address storageAddress;
    address paidWallet;
    address primaryRoyaltyWallet;

    string public metadataForFetchingOnly;
    string public imgBackupTx;

    bool public secondaryOpen = false;
    bool public openSecondaryLocked = false;

    modifier whenSecondaryOpen {
        require(secondaryOpen, "Listing & transfer not allowed yet.");
        _;
    }

    modifier ifExist(uint256 _tokenId) {
        require(_exists(_tokenId), "Nonexistent token.");
        _;
    }

    modifier onlyFromWallet() {
        require(tx.origin == msg.sender, "Caller is not sender.");
        _;
    }

    constructor(
        address _secondaryRoyaltyWallet,
        address _paidWallet,
        address _primaryRoyaltyWallet,
        string memory _metadataForFetchingOnly,
        address _storageAddress)
        ERC721("Non Fungible Conference 2023", "NFCSummit2023") 
    {
        _setDefaultRoyalty(_secondaryRoyaltyWallet, 1000);
        paidWallet = _paidWallet;
        primaryRoyaltyWallet = _primaryRoyaltyWallet;
        metadataForFetchingOnly = _metadataForFetchingOnly;
        storageContract = INFCStorage(_storageAddress);
    }

    function toggleSecondary() external onlyOwner {
        require(!openSecondaryLocked, "Secondary is open for ever.");
        secondaryOpen = !secondaryOpen;
    }

    function lockOpenSecondary() external onlyOwner {
        openSecondaryLocked = true;
        secondaryOpen = true;
    }

    function lockBackupData(string calldata _tx) external onlyOwner {
        require(bytes(imgBackupTx).length == 0, "Backup locked.");
        imgBackupTx = _tx;
    }

    function tokenImgBackupTx(uint256 _tokenId) external view ifExist(_tokenId) returns (string memory) {
        return imgBackupTx;
    }

    function tokenURIarweave(uint256 _tokenId) external view ifExist(_tokenId) returns (string memory) {
        return METADATA_ARWEAVE;
    }

    function tokenURIipfs(uint256 _tokenId) external view ifExist(_tokenId) returns (string memory) {
        return METADATA_IPFS;
    }

    function tokenURI(uint256 _tokenId) public view override ifExist(_tokenId) returns (string memory) {
        return bytes(metadataForFetchingOnly).length > 0 ? string(abi.encodePacked(metadataForFetchingOnly, _tokenId.toString(), ".json")) : "";
    }

    function updateJsonFetching(string calldata _metadataForFetchingOnly) external onlyOwner {
        metadataForFetchingOnly = _metadataForFetchingOnly;
    }

    function discountedMint(address _nft_contract, uint256 _nft_id) external payable onlyFromWallet {
        require(!storageContract.salesLocked(), "Sales are closed.");
        require(IERC721(_nft_contract).ownerOf(_nft_id) == msg.sender, "You are not owner.");
        storageContract.checkEligibility(_nft_contract, _nft_id);
        require(msg.value >= (storageContract.basePrice() - (storageContract.phase() * storageContract.basePrice()) / 100), "Ether value sent is not correct.");
        
        storageContract.redeem(_nft_contract, _nft_id);
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function normalMint() external payable onlyFromWallet {
        require(storageContract.phase() == 0, "Only during public sales.");
        require(!storageContract.salesLocked(), "Sales are closed.");
        require(msg.value >= storageContract.basePrice(), "Ether value sent is not correct.");

        _safeMint(msg.sender, totalSupply() + 1);
    }

    function freeMint(bytes32[] calldata _merkle) external onlyFromWallet {
        require(!storageContract.whitelistClaimed(msg.sender), "Already freemint.");
        require(MerkleProof.verify(_merkle, storageContract.merkleRoot(), keccak256(abi.encodePacked(msg.sender))), "Incorrect proof.");
        
        storageContract.storeWhitelistClaim(msg.sender);
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function emergencyMint() external payable onlyFromWallet {
        require(storageContract.emergency(), "Not emergency.");
        require(!storageContract.salesLocked(), "Sales are closed.");
        require(msg.value >= storageContract.basePrice(), "Ether value sent is not correct.");

        _safeMint(msg.sender, totalSupply() + 1);
    }

    function withdraw() external payable onlyFromWallet onlyOwner {
        uint256 balance = address(this).balance;
        payable(paidWallet).transfer(balance * 95/100);
        payable(primaryRoyaltyWallet).transfer(balance * 5/100);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721, ERC721)
        whenSecondaryOpen
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(IERC721, ERC721)
        whenSecondaryOpen
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(IERC721, ERC721)
        whenSecondaryOpen
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(IERC721, ERC721)
        whenSecondaryOpen
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(IERC721, ERC721)
        whenSecondaryOpen
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}