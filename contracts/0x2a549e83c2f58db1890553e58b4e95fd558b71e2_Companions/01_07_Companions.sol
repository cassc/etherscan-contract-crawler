// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

import { ERC721A } from "erc721a/ERC721A.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { MerkleProof } from "openzeppelin/cryptography/MerkleProof.sol";
import { ICompanions } from "./ICompanions.sol";

contract Companions is ICompanions, ERC721A, Ownable {
    /// ERRORS ///

    error PrioritylistMintNotActive();
    error AllowlistMintNotActive();
    error MintAmountExceeded();
    error PublicMintNotActive();
    error InvalidProof();
    error MaxSupplyReached();
    error SenderNotEOA();

    /// PRIVATE STORAGE ///

    /// @dev IPFS base URI storage.
    string private _baseTokenURI;

    /// PUBLIC STORAGE ///

    /// @dev Maximum supply of tokens that can ever be minted.
    uint256 public constant MAX_SUPPLY = 5000;

    /// @inheritdoc ICompanions
    bytes32 public prioritylistMerkleRoot;

    /// @inheritdoc ICompanions
    bytes32 public allowlistMerkleRoot;

    /// @inheritdoc ICompanions
    bool public isPrioritylistMintActive;

    /// @inheritdoc ICompanions
    bool public isAllowlistMintActive;

    /// @inheritdoc ICompanions
    bool public isPublicMintActive;

    /// CONSTRUCTOR ///

    /// @dev Constructor to initialize ERC-721A contract with name and symbol.
    constructor() ERC721A("Cornerstone Companions", "COMPANIONS") { }

    /// @inheritdoc ICompanions
    function setPrioritylistMerkleRoot(bytes32 root) external onlyOwner {
        prioritylistMerkleRoot = root;
    }

    /// @inheritdoc ICompanions
    function setAllowlistMerkleRoot(bytes32 root) external onlyOwner {
        allowlistMerkleRoot = root;
    }

    /// @inheritdoc ICompanions
    function setIsPrioritylistMintActive(bool state) external onlyOwner {
        isPrioritylistMintActive = state;
    }

    /// @inheritdoc ICompanions
    function setIsAllowlistMintActive(bool state) external onlyOwner {
        isAllowlistMintActive = state;
    }

    /// @inheritdoc ICompanions
    function setIsPublicMintActive(bool state) external onlyOwner {
        isPublicMintActive = state;
    }

    /// @inheritdoc ICompanions
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @inheritdoc ICompanions
    function airdrop(address[] calldata recipients, uint256 quantity) external onlyOwner {
        uint256 recipientsLength = recipients.length;
        if (_totalMinted() + recipientsLength * quantity > MAX_SUPPLY) revert MaxSupplyReached();

        for (uint256 i = 0; i < recipientsLength; i++) {
            _mint(recipients[i], quantity);
        }
    }

    /// @inheritdoc ICompanions
    function prioritylistMint(bytes32[] calldata merkleProof, uint256 quantity, uint256 maxMintAmount) external {
        if (!isPrioritylistMintActive) revert PrioritylistMintNotActive();
        if (_totalMinted() + quantity > MAX_SUPPLY) revert MaxSupplyReached();
        if (quantity > maxMintAmount - _numberMinted(msg.sender)) revert MintAmountExceeded();

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, maxMintAmount))));
        if (!MerkleProof.verifyCalldata(merkleProof, prioritylistMerkleRoot, leaf)) revert InvalidProof();

        _mint(msg.sender, quantity);
    }

    /// @inheritdoc ICompanions
    function allowlistMint(bytes32[] calldata merkleProof, uint256 quantity, uint256 maxMintAmount) external {
        if (!isAllowlistMintActive) revert AllowlistMintNotActive();
        if (_totalMinted() + quantity > MAX_SUPPLY) revert MaxSupplyReached();
        if (quantity > maxMintAmount - _numberMinted(msg.sender)) revert MintAmountExceeded();

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, maxMintAmount))));
        if (!MerkleProof.verifyCalldata(merkleProof, allowlistMerkleRoot, leaf)) revert InvalidProof();

        _mint(msg.sender, quantity);
    }

    /// @inheritdoc ICompanions
    function publicMint() external {
        if (msg.sender != tx.origin) revert SenderNotEOA();
        if (!isPublicMintActive) revert PublicMintNotActive();
        if (_totalMinted() >= MAX_SUPPLY) revert MaxSupplyReached();

        _mint(msg.sender, 1);
    }

    /// INTERNAL FUNCTIONS ///

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}