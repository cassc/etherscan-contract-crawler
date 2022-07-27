// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title The Farmverse
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://thefarmverse.app

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721Ao.sol";
import "./Payable.sol";

contract Farmverse is ERC721Ao, Payable {
    using Strings for uint256;

    uint256 public tokenPrice = 0.0088 ether;

    // Token values incremented for gas efficiency
    uint16 private maxSalePlusOne = 4445;
    uint16 private constant MAX_PER_TRANS = 5;

    // Presale
    bytes32 public merkleRoot = "";

    // State
    bool public saleActive = false;

    string public baseURI;
    string public placeholderURI;

    constructor() ERC721Ao("Farmverse", "FARM") Payable() {}

    //
    // Modifiers
    //

    /**
     * Ensure sale is active.
     */
    modifier isSaleActive() {
        require(saleActive, "Farmverse: Invalid state");
        _;
    }

    /**
     * Ensure amount of tokens to mint is within the transaction limit.
     */
    modifier correctPrice(uint16 numTokens) {
        require(msg.value == tokenPrice * numTokens, "Farmverse: Invalid Ether value");
        _;
    }

    /**
     * Ensure amount of tokens to mint is within the limit.
     */
    modifier withinMintLimit(uint16 numTokens) {
        require((_totalMinted() + numTokens) < maxSalePlusOne, "Farmverse: Exceeds available tokens");
        _;
    }

    //
    // Minting
    //

    /**
     * Mint tokens during the public sale.
     * @param numTokens Number of tokens to mint.
     */
    function mintPublic(uint16 numTokens)
        external
        payable
        isSaleActive
        withinMintLimit(numTokens)
        correctPrice(numTokens)
    {
        require(numTokens <= MAX_PER_TRANS, "Farmverse: Exceeds transaction limit");
        _safeMint(msg.sender, numTokens);
    }

    /**
     * Mint tokens when farmlisted.
     * @param numTokens Number of tokens to mint.
     * @param proof The Merkle proof used to validate the leaf is in the root.
     */
    function mintFarmlist(uint16 numTokens, bytes32[] calldata proof)
        external
        payable
        isSaleActive
        withinMintLimit(numTokens)
        correctPrice(numTokens)
    {
        require(numTokens <= MAX_PER_TRANS * 2, "Farmverse: Exceeds transaction limit");
        bytes32 leaf = keccak256(abi.encode(msg.sender));
        require(verify(merkleRoot, leaf, proof), "Farmverse: Not a valid proof");
        _safeMint(msg.sender, numTokens);
    }

    /**
     * Mints reserved tokens.
     * @param numTokens Number of tokens to mint.
     * @param mintTo Address to mint tokens to.
     */
    function mintReserved(uint16 numTokens, address mintTo) external onlyOwner withinMintLimit(numTokens) {
        _safeMint(mintTo, numTokens);
    }

    //
    // Admin
    //

    /**
     * Toggle the sale active state.
     */
    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    /**
     * Update token price.
     * @param tokenPrice_ The new price per token.
     */
    function setTokenPrice(uint256 tokenPrice_) external onlyOwner {
        tokenPrice = tokenPrice_;
    }

    /**
     * Update maximum number of tokens for sale.
     * @param maxSale The new maximum number of tokens for sale.
     */
    function setMaxSale(uint16 maxSale) external onlyOwner {
        maxSalePlusOne = maxSale + 1;
    }

    /**
     * Set the presale Merkle root.
     * @param merkleRoot_ The new merkle root.
     */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    /**
     * Sets base URI.
     * @param baseURI_ The new base URI.
     * @dev Only use this method after sell out as it will leak unminted token data.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Sets placeholder URI.
     * @param placeholderURI_ The new placeholder URI.
     */
    function setPlaceholderURI(string memory placeholderURI_) external onlyOwner {
        placeholderURI = placeholderURI_;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(uint16(tokenId)), "ERC721Metadata: URI query for nonexistent token");

        string memory uri = _baseURI();
        return bytes(uri).length > 0 ? string(abi.encodePacked(uri, tokenId.toString(), ".json")) : placeholderURI;
    }

    /**
     * @dev Return sale claim info.
     * saleClaims[0]: maxSale (total available tokens)
     * saleClaims[1]: totalSupply
     * saleClaims[2]: tokenPrice
     */
    function saleClaims() public view virtual returns (uint256[3] memory) {
        return [maxSalePlusOne - 1, totalSupply(), tokenPrice];
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Ao, ERC2981) returns (bool) {
        return ERC721Ao.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * Verify the Merkle proof is valid.
     * @param root The Merkle root. Use the value stored in the contract
     * @param leaf The leaf.
     * @param proof The Merkle proof used to validate the leaf is in the root
     */
    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}