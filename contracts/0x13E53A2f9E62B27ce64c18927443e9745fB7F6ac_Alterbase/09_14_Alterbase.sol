// SPDX-License-Identifier: MIT
//
// ░█▀▀█ ▒█░░░ ▀▀█▀▀ ▒█▀▀▀ ▒█▀▀█ ▒█▀▀█ ░█▀▀█ ▒█▀▀▀█ ▒█▀▀▀ 
// ▒█▄▄█ ▒█░░░ ░▒█░░ ▒█▀▀▀ ▒█▄▄▀ ▒█▀▀▄ ▒█▄▄█ ░▀▀▀▄▄ ▒█▀▀▀ 
// ▒█░▒█ ▒█▄▄█ ░▒█░░ ▒█▄▄▄ ▒█░▒█ ▒█▄▄█ ▒█░▒█ ▒█▄▄▄█ ▒█▄▄▄
//
pragma solidity ^0.8.13;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract Alterbase is Ownable, ERC721A, DefaultOperatorFilterer, ERC2981, ReentrancyGuard {
    uint256 internal immutable collectionSize;

    /**
     * @dev WL's max mint size (in terms of totalSupply)
     */
    uint256 private wlMaxSize;

    /**
     * @dev Max Mint Per Wallet for every stage
     */
    uint256 private constant maxPerALMint = 3;
    uint256 private constant maxPerWLMint = 2;
    uint256 private constant maxPerPLMint = 10;

    /**
     * @dev Prices
     */
    uint256 private AL_PRICE;
    uint256 private WL_PRICE;
    uint256 private PL_PRICE;

    /**
     * @dev Provenance Hash
     */
    string public provenance;

    /**
     * @dev Is metadata all frozen
     */
    bool public allFrozen;

    /**
     * @dev Mint count for each address
     */
    mapping(address => uint256) private alClaimed;
    mapping(address => uint256) private wlClaimed;
    mapping(address => uint256) private plClaimed;

    /**
     * @dev Sale start time
     */
    uint256 private alStartTime;
    uint256 private wlStartTime;
    uint256 private plStartTime;

    /**
     * @dev Base token URI
     */
    string private _baseTokenURI;

    /**
     * @dev AlterList and WhiteList is off chain using Merkle Tree
     */
    bytes32 private _merkleRootAL;
    bytes32 private _merkleRootWL;

    constructor(
        uint256 AL_PRICE_,
        uint256 WL_PRICE_,
        uint256 PL_PRICE_,
        uint256 collectionSize_,
        uint256 wlMaxSize_
    ) ERC721A('ALTERBASE', 'ALT') DefaultOperatorFilterer() {
        require(wlMaxSize_ <= collectionSize_, 'Over size');
        AL_PRICE = AL_PRICE_;
        WL_PRICE = WL_PRICE_;
        PL_PRICE = PL_PRICE_;
        collectionSize = collectionSize_;
        wlMaxSize = wlMaxSize_;

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
    }

    /**
     * @dev validates caller is not from contract
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'Caller is contract');
        _;
    }

    /**
     * @dev for marketing etc.
     */
    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= collectionSize, 'Reach max');
        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev alterList mint for smaller pool of WL
     */
    function alterMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable callerIsUser {
        require(alStartTime != 0 && block.timestamp >= alStartTime, 'Not started');
        require(totalSupply() + quantity <= collectionSize, 'Reach max');
        require(
            MerkleProof.verify(_merkleProof, _merkleRootAL, keccak256(abi.encodePacked(msg.sender))),
            'Not eligible'
        );
        require(alClaimed[msg.sender] + quantity <= maxPerALMint, 'Mint too many');

        alClaimed[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(AL_PRICE * quantity);
    }

    /**
     * @dev whitelist mint for bigger pool of WL
     */
    function whiteListMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable callerIsUser {
        require(wlStartTime != 0 && block.timestamp >= wlStartTime, 'Not started');
        require(totalSupply() + quantity <= wlMaxSize && totalSupply() + quantity <= collectionSize, 'Reach max');
        require(
            MerkleProof.verify(_merkleProof, _merkleRootWL, keccak256(abi.encodePacked(msg.sender))),
            'Not eligible'
        );
        require(wlClaimed[msg.sender] + quantity <= maxPerWLMint, 'Mint too many');

        wlClaimed[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(WL_PRICE * quantity);
    }

    /**
     * @dev public mint
     */
    function publicMint(uint256 quantity) external payable callerIsUser {
        require(plStartTime != 0 && block.timestamp >= plStartTime, 'Not started');
        require(totalSupply() + quantity <= collectionSize, 'Reach max');
        require(plClaimed[msg.sender] + quantity <= maxPerPLMint, 'Mint too many');

        plClaimed[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(PL_PRICE * quantity);
    }

    /**
     * @dev validate payment amount and refund if over
     */
    function refundIfOver(uint256 price) private {
        require(msg.value >= price, 'Need more ETH');
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /**
     * @dev set wlMaxSize
     */
    function setWLMaxSize(uint256 wlMaxSize_) external onlyOwner {
        require(wlMaxSize_ <= collectionSize, 'Over size');
        wlMaxSize = wlMaxSize_;
    }

    /**
     * @dev set alterList price
     */
    function setALPrice(uint256 price) external onlyOwner {
        AL_PRICE = price;
    }

    /**
     * @dev set whiteList price
     */
    function setWLPrice(uint256 price) external onlyOwner {
        WL_PRICE = price;
    }

    /**
     * @dev set alterList price
     */
    function setPLPrice(uint256 price) external onlyOwner {
        PL_PRICE = price;
    }

    /**
     * @dev set alterList sale start time
     */
    function setALSaleStartTime(uint32 timestamp) external onlyOwner {
        alStartTime = timestamp;
    }

    /**
     * @dev set whiteList sale start time
     */
    function setWLSaleStartTime(uint32 timestamp) external onlyOwner {
        wlStartTime = timestamp;
    }

    /**
     * @dev set public sale start time
     */
    function setPLSaleStartTime(uint32 timestamp) external onlyOwner {
        plStartTime = timestamp;
    }

    /**
     * @dev view base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev set base URI
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        require(!allFrozen, 'Already frozen');
        _baseTokenURI = baseURI;
    }

    /**
     * @dev withdraw money to owner
     */
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Transfer failed');
    }

    /**
     * @dev get total minted number of an address
     */
    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @dev get ownership data of a token
     */
    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    /**
     * @dev set alterList merkle tree root
     */
    function setMerkleRootAL(bytes32 merkleRoot) external onlyOwner {
        _merkleRootAL = merkleRoot;
    }

    /**
     * @dev set whiteList merkle tree root
     */
    function setMerkleRootWL(bytes32 merkleRoot) external onlyOwner {
        _merkleRootWL = merkleRoot;
    }

    /**
     * @dev set provenance hash
     */
    function setProvenanceHash(string calldata provHash) external onlyOwner {
        provenance = provHash;
    }

    /**
     * @dev freeze all metadata, once call, forever frozen
     */
    function freezeAll() external onlyOwner {
        allFrozen = true;
    }

    /**
     * @dev For Opensea OperatorFilterer
     */

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev For ERC2981
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}