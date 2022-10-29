// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title R3DRUM
contract R3DRUM is ERC721A, Ownable, PaymentSplitter {
    // IMMUTABLE STORAGE

    /// @notice Available NFT supply
    uint256 public immutable maxSupply;

    /// @notice Maximum tokens per giveaway address
    uint256 private immutable giveawayQuantity;

    /// @notice Merkle root for giveaway
    bytes32 private immutable giveawayMerkleRoot;

    /// @notice Maximum tokens per public mint transaction
    uint256 public immutable maxTokensPerPublicMintTxn;

    // MUTABLE STORAGE

    /// @notice Base URI for NFT
    string private baseURI;

    bool private isPublicMintActive = false;

    bool private isGiveawayMintActive = false;

    /// @notice Price in wei to mint each NFT during public mint
    uint64 private publicMintPrice;

    /// @notice List of giveaway addresses that already claimed
    mapping(address => bool) private giveawayClaimed;

    // CONSTRUCTOR

    /// @notice Creates a new NFT distribution contract
    constructor(
        string memory name,
        string memory symbol,
        address[] memory payees,
        uint256[] memory shares,
        uint56 _publicMintPrice,
        uint256 _maxSupply,
        uint256 _maxTokensPerPublicMintTxn,
        uint256 _giveawayQuantity,
        bytes32 _giveawayMerkleRoot
    ) ERC721A(name, symbol) PaymentSplitter(payees, shares) {
        publicMintPrice = _publicMintPrice;
        maxSupply = _maxSupply;
        maxTokensPerPublicMintTxn = _maxTokensPerPublicMintTxn;
        giveawayQuantity = _giveawayQuantity;
        giveawayMerkleRoot = _giveawayMerkleRoot;
    }

    // MODIFIERS

    /// @dev Throws if called by a contract
    modifier isNotContract() {
        require(tx.origin == msg.sender, "only users allowed");
        _;
    }

    // FUNCTION OVERRIDES

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // FUNCTIONS

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setPublicMintPrice(uint64 _publicMintPrice) public onlyOwner {
        publicMintPrice = _publicMintPrice;
    }

    function getPublicMintPrice() public view returns (uint64) {
        return publicMintPrice;
    }

    function setGiveawayMintActive(bool _isGiveawayMintActive)
        public
        onlyOwner
    {
        isGiveawayMintActive = _isGiveawayMintActive;
    }

    function getGiveawayMintActive() public view returns (bool) {
        return isGiveawayMintActive;
    }

    function setPublicMintActive(bool _isPublicMintActive) public onlyOwner {
        isPublicMintActive = _isPublicMintActive;
    }

    function getPublicMintActive() public view returns (bool) {
        return isPublicMintActive;
    }

    function getHasClaimedGiveaway(address _address)
        public
        view
        returns (bool)
    {
        return giveawayClaimed[_address];
    }

    function publicMint(uint256 quantity) external payable isNotContract {
        require(isPublicMintActive, "public mint not active");
        require(
            quantity <= maxTokensPerPublicMintTxn,
            "quantity exceeds allowance"
        );
        require(
            publicMintPrice * quantity <= msg.value,
            "insufficient funds sent"
        );
        require(
            totalSupply() + quantity <= maxSupply,
            "quantity exceeds max supply"
        );

        _mint(msg.sender, quantity);
    }

    function giveawayMint(bytes32[] calldata proof)
        external
        payable
        isNotContract
    {
        require(isGiveawayMintActive, "giveaway not active");
        require(!giveawayClaimed[msg.sender], "giveaway already claimed");
        require(
            totalSupply() + giveawayQuantity <= maxSupply,
            "quantity exceeds max supply"
        );
        require(
            MerkleProof.verify(
                proof,
                giveawayMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "invalid proof"
        );

        giveawayClaimed[msg.sender] = true;
        _mint(msg.sender, giveawayQuantity);
    }
}