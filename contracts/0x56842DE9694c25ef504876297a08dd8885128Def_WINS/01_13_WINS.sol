// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title Wolves In NFT St
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://www.winsnft.io

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "./Payable.sol";

contract WINS is ERC721AQueryable, Payable {
    uint256 public tokenPrice = 0.0555 ether;

    // Token values incremented for gas efficiency
    uint16 private constant MAX_SALE_P1 = 556;
    uint16 private phaseSalePlusOne = 201;
    uint16 private allowancePlusOne = 3;

    // Presale
    bytes32 public merkleRoot = "";

    // State
    enum SaleState {
        OFF,
        LISTED,
        PUBLIC
    }
    SaleState public saleState = SaleState.OFF;

    string public baseURI;
    string public placeholderURI;

    constructor() ERC721A("Wolves In NFT St", "WINS") Payable() {}

    //
    // Modifiers
    //

    /**
     * Validate the supplied parameters for minting.
     * @dev Ensure sale is active.
     * @dev Ensure amount of tokens to mint is within the limit.
     * @dev Ensure the ETH supplied is correct.
     */
    modifier mintValidated(SaleState state, uint256 numTokens) {
        require(saleState == state, "WINS: Invalid state");
        uint256 newTotal = _totalMinted() + numTokens;
        require(newTotal < MAX_SALE_P1, "WINS: Exceeds available tokens");
        require(newTotal < phaseSalePlusOne, "WINS: Exceeds available tokens");
        require(msg.value == tokenPrice * numTokens, "WINS: Invalid Ether value");
        _;
    }

    //
    // Minting
    //

    /**
     * Mint tokens during public sale.
     * @param numTokens Number of tokens to mint.
     */
    function mintPublic(uint256 numTokens) external payable mintValidated(SaleState.PUBLIC, numTokens) {
        _safeMint(msg.sender, numTokens);
    }

    /**
     * Mint tokens when listed.
     * @param numTokens Number of tokens to mint.
     * @param proof The Merkle proof used to validate the leaf is in the root.
     */
    function mintListed(uint256 numTokens, bytes32[] calldata proof)
        external
        payable
        mintValidated(SaleState.LISTED, numTokens)
    {
        require(_numberMinted(msg.sender) + numTokens < allowancePlusOne, "WINS: Exceeds allowance");
        // Verify merkle proof
        bytes32 leaf = keccak256(abi.encode(msg.sender));
        require(verify(merkleRoot, leaf, proof), "WINS: Not a valid proof");

        _safeMint(msg.sender, numTokens);
    }

    /**
     * Mint reserved tokens.
     * @param mintTo Address to mint tokens to.
     * @param numTokens Number of tokens to mint.
     */
    function mintReserved(address mintTo, uint16 numTokens) external onlyOwner {
        require((_totalMinted() + numTokens) < MAX_SALE_P1, "WINS: Exceeds available tokens");
        _safeMint(mintTo, numTokens);
    }

    //
    // Admin
    //

    /**
     * Set the sale state.
     * @param saleState_ The new sale state. 0 = OFF, 1 = LISTED, 2 = PUBLIC
     */
    function setSaleState(SaleState saleState_) external onlyOwner {
        saleState = saleState_;
    }

    /**
     * Update token price.
     * @param tokenPrice_ The new price per token.
     */
    function setTokenPrice(uint256 tokenPrice_) external onlyOwner {
        tokenPrice = tokenPrice_;
    }

    /**
     * Update the phase sale limit.
     * @param phaseSale The new phase sale limit.
     */
    function setPhaseSale(uint16 phaseSale) external onlyOwner {
        phaseSalePlusOne = phaseSale + 1;
    }

    /**
     * Update the allowance per wallet.
     * @param allowance The new allowance per wallet.
     */
    function setAllowance(uint16 allowance) external onlyOwner {
        allowancePlusOne = allowance + 1;
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

    function _baseURI() internal view override returns (string memory) {
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
    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory uri = _baseURI();
        return bytes(uri).length > 0 ? string(abi.encodePacked(uri, _toString(tokenId), ".json")) : placeholderURI;
    }

    /**
     * @dev Return sale claim info.
     * @return Information required for sales UI
     * saleClaims[0]: saleState
     * saleClaims[1]: maxSale (total available tokens)
     * saleClaims[2]: totalSupply
     * saleClaims[3]: tokenPrice
     * saleClaims[4]: allowance remaining
     * saleClaims[4]: phase max sale (total tokens in this phase)
     */
    function saleClaims(address owner) public view returns (uint256[6] memory) {
        return [
            uint256(saleState),
            MAX_SALE_P1 - 1,
            totalSupply(),
            tokenPrice,
            allowancePlusOne - _numberMinted(owner) - 1,
            phaseSalePlusOne - 1
        ];
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @inheritdoc	IERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * Verify the Merkle proof is valid.
     * @param root The Merkle root. Use the value stored in the contract
     * @param leaf The leaf. An address
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