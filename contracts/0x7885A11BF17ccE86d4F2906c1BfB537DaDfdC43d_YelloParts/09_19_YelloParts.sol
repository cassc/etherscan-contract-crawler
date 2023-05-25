// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract YelloParts is
    Ownable,
    ERC721A,
    ERC721ABurnable,
    ERC721AQueryable,
    ReentrancyGuard,
    DefaultOperatorFilterer,
    ERC2981
{
    /**
     * @dev Collection Size is adjustable
     */
    uint256 private collectionSize;

    /**
     * @dev Price for minting 1 token
     */
    uint256 public mintPrice;

    /**
     * @dev Mint Open or Close
     */
    bool public mintOpen;

    /**
     * @dev Token types in metadata
     */
    uint256[] public tokenTypes;

    /**
     * @dev Starting token id of the active tokens, inactive tokens can't calculate token type
     */
    uint256 public activeStartTokenId;

    /**
     * @dev Base token URI
     */
    string private baseTokenURI;

    /**
     * @dev WhiteList is off chain using Merkle Tree
     */
    bytes32 private merkleRoot;

    /**
     * @dev BitMap to keep track of claimed whitelist address indexes
     */
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(
        uint256 _mintPrice,
        uint256 _collectionSize,
        uint256[] memory _tokenTypes
    ) ERC721A('YELLO PARTS', 'YLP') DefaultOperatorFilterer() {
        mintPrice = _mintPrice;
        collectionSize = _collectionSize;
        tokenTypes = _tokenTypes;

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
        require(_totalMinted() + quantity <= collectionSize, 'Reach max');
        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev free mint for whitelist
     */
    function giftMint(
        uint256 index,
        uint256 quantity,
        bytes32[] calldata _merkleProof
    ) external callerIsUser nonReentrant {
        require(mintOpen, 'Not started');
        require(_totalMinted() + quantity <= collectionSize, 'Reach max');
        require(!isClaimed(index), 'Already claimed');
        require(verifyMerkleProof(index, quantity, _merkleProof), 'Merkle: Invalid proof');

        setClaimed(index);
        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev public mint
     */
    function publicMint(uint256 quantity) external payable callerIsUser nonReentrant {
        require(mintOpen, 'Not started');
        require(msg.value >= mintPrice * quantity, 'Need more ETH');
        require(_totalMinted() + quantity <= collectionSize, 'Reach max');

        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev burn batch of tokens at once
     */
    function burnBatch(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ) {
            burn(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev swap tokens will burn the owned tokens and mint new tokens to address
     */
    function swapBatch(uint256[] calldata tokenIds) external callerIsUser nonReentrant {
        require(activeStartTokenId > 0, 'Swap not open');
        require(_totalMinted() + tokenIds.length <= collectionSize, 'Reach max');

        for (uint256 i = 0; i < tokenIds.length; ) {
            require(tokenIds[i] < activeStartTokenId, 'Cannot swap');
            burn(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        _safeMint(msg.sender, tokenIds.length);
    }

    /**
     * @dev set collection size
     */
    function setCollectionSize(uint256 _collectionSize) external onlyOwner {
        require(_collectionSize >= _totalMinted(), 'invalid size');
        collectionSize = _collectionSize;
    }

    /**
     * @dev set mint price
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @dev set Mint Open or Close
     */
    function setMintOpen(bool _mintOpen) external onlyOwner {
        mintOpen = _mintOpen;
    }

    /**
     * @dev set whiteList merkle tree root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev verify merkle proof
     */
    function verifyMerkleProof(
        uint256 index,
        uint256 numTokens,
        bytes32[] calldata _merkleProof
    ) internal view returns (bool) {
        return MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(index, msg.sender, numTokens)));
    }

    /**
     * @dev view base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev set base URI
     */
    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @dev set current active token types
     */
    function setTokenTypes(uint256[] calldata _tokenTypes) external onlyOwner {
        tokenTypes = _tokenTypes;
    }

    /**
     * @dev set activeStartTokenId
     */
    function setActiveStartTokenId(uint256 _tokenId) external onlyOwner {
        require(_tokenId < collectionSize, 'Reach max');
        activeStartTokenId = _tokenId;
    }

    /**
     * @dev view total minted amount including burned tokens
     */
    function totalMinted() external view virtual returns (uint256) {
        return _totalMinted();
    }

    /**
     * @dev withdraw money to owner
     */
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Transfer failed');
    }

    /**
     * @dev get ownership data of a token
     */
    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    /**
     * @dev return if address already claimed
     */
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @dev mark as claimed for address
     */
    function setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    /**
     * @dev get part type for a token
     */
    function getTokenType(uint256 tokenId) external view returns (uint256) {
        require(tokenTypes.length > 0, '0 num token types');
        require(_exists(tokenId), 'token not exists');
        require(tokenId >= activeStartTokenId, 'token is not actiave');
        uint256 idHash = uint256(keccak256(abi.encodePacked(tokenId)));
        return tokenTypes[idHash % tokenTypes.length];
    }

    /**
     * @dev For Opensea OperatorFilterer
     */

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev For ERC2981
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}