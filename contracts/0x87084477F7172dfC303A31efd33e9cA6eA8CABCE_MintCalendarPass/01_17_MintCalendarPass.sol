// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract MintCalendarPass is ERC1155Supply, IERC2981, Ownable, Pausable {
    using Strings for uint256;

    bool public isPublicSaleActive;
    bool public isWhitelistSaleActive;

    bytes32 public whitelistMerkleRoot;
    mapping(address => uint256) public mintCounts;

    string public name;
    string public symbol;
    uint256 public immutable mintPrice;
    uint256 public immutable collectionSize;
    uint256 public immutable transactionMintLimit;
    uint256 public immutable addressMintLimit;

    uint16 public royaltyBasisPoints;
    string public collectionURI;
    string internal metadataBaseURI;

    uint256 public PASS_INDEX = 0;

    constructor(string memory initialMetadataBaseURI, string memory initialCollectionURI, uint16 initialRoyaltyBasisPoints, uint256 initialTransactionMintLimit, uint256 initialAddressMintLimit, uint256 initialCollectionSize, uint256 initialMintPrice)
    ERC1155(initialMetadataBaseURI)
    Ownable() {
        name = "Mint Calendar Pass";
        symbol = "MCPass";
        collectionURI = initialCollectionURI;
        royaltyBasisPoints = initialRoyaltyBasisPoints;
        transactionMintLimit = initialTransactionMintLimit;
        addressMintLimit = initialAddressMintLimit;
        collectionSize = initialCollectionSize;
        mintPrice = initialMintPrice;
    }

    // Meta

    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
        return (address(this), salePrice * royaltyBasisPoints / 10000);
    }

    function contractURI() external view returns (string memory) {
        return collectionURI;
    }

    // Admin

    function setMetadataBaseURI(string calldata newMetadataBaseURI) external onlyOwner {
        _setURI(newMetadataBaseURI);
    }

    function setRoyaltyBasisPoints(uint16 newRoyaltyBasisPoints) external onlyOwner {
        require(newRoyaltyBasisPoints >= 0, 'MintCalendarPass: royaltyBasisPoints must be >= 0');
        require(newRoyaltyBasisPoints < 5000, 'MintCalendarPass: royaltyBasisPoints must be < 5000 (50%)');
        royaltyBasisPoints = newRoyaltyBasisPoints;
    }

    function setIsWhitelistSaleActive(bool newIsWhitelistSaleActive) external onlyOwner {
        require(mintPrice >= 0 || !newIsWhitelistSaleActive, 'MintCalendarPass: cannot start if mintPrice is 0');
        require(whitelistMerkleRoot != 0, 'MintCalendarPass: cannot start if whitelistMerkleRoot is not set');
        isWhitelistSaleActive = newIsWhitelistSaleActive;
    }

    function setIsPublicSaleActive(bool newIsPublicSaleActive) external onlyOwner {
        require(mintPrice >= 0 || !newIsPublicSaleActive, 'MintCalendarPass: cannot start if mintPrice is 0');
        isPublicSaleActive = newIsPublicSaleActive;
    }

    function setWhitelistMerkleRoot(bytes32 newWhitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = newWhitelistMerkleRoot;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function adminMint(address to, uint256 quantity) public onlyOwner {
        _innerMint(to, quantity);
    }

    //  Metadata

    function uri(uint256 tokenId) override public view returns (string memory) {
        require(totalSupply(tokenId) > 0, "MintCalendarPass: query for nonexistent token");
        require(tokenId >= 0 && tokenId < collectionSize, "MintCalendarPass: query for nonexistent token");
        return string(abi.encodePacked(super.uri(tokenId), Strings.toString(tokenId), ".json"));
    }

    // Minting

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "MintCalendarPass: The caller is another contract");
        _;
    }

    function _generateMerkleLeaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verifyMerkleLeaf(bytes32 merkleLeaf, bytes32 merkleRoot, bytes32[] memory proof) internal pure returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, merkleLeaf);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata proof) public payable callerIsUser {
        require(isWhitelistSaleActive && mintPrice > 0, "MintCalendarPass: whitelist sale not active");
        require(_verifyMerkleLeaf(_generateMerkleLeaf(_msgSender()), whitelistMerkleRoot, proof), "MintCalendarPass: invalid proof");
        require(msg.value >= mintPrice * quantity, "MintCalendarPass: insufficient payment");
        userMint(quantity);
    }

    function publicMint(uint256 quantity) public payable callerIsUser {
        require(isPublicSaleActive && mintPrice > 0, "MintCalendarPass: public sale not active");
        require(msg.value >= mintPrice * quantity, "MintCalendarPass: insufficient payment");
        userMint(quantity);
    }

    function userMint(uint256 quantity) internal {
        require(mintCounts[_msgSender()] + quantity <= addressMintLimit, "MintCalendarPass: adress mint limit reached");
        require(quantity > 0 && quantity <= transactionMintLimit, 'MintCalendarPass: invalid quantity');
        mintCounts[_msgSender()] += quantity;
        _innerMint(_msgSender(), quantity);
    }

    function _innerMint(address to, uint256 quantity) internal {
        require(totalSupply(PASS_INDEX) + quantity <= collectionSize, 'MintCalendarPass: quantity out of bounds');
        _mint(to, PASS_INDEX, quantity, "");
    }

}