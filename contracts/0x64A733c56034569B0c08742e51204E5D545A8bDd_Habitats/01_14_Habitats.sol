// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { ERC721AQueryable, ERC721A } from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
 * @title Habitats NFT
 */
contract Habitats is ERC721AQueryable, ERC2981, Ownable, ReentrancyGuard {
    enum SaleState { Closed, Presale, AllowList, Public }

    uint256 public constant RESERVE_LIMIT = 250;
    uint256 public constant COLLECTION_SIZE = 2500;
    uint256 public constant MAX_BATCH_SIZE = 10;
    uint256 public mintPrice = .1 ether;
    uint256 public allowListMintAllowance = 2;
    address payable private immutable _withdrawalAddress;
    address private immutable _reserveAddress;
    mapping(address => uint) private presaleAllowance;
    SaleState public state;
    string public baseURI;
    bytes32 public allowListMerkleRoot;

    constructor(
        address withdrawalAddress,
        address reserveAddress
    ) ERC721A("Habitats", "HAB") {
        _withdrawalAddress = payable(withdrawalAddress);
        _reserveAddress = reserveAddress;
        _setDefaultRoyalty(withdrawalAddress, 500);
    }

    /**
     * @notice Modifer to disallow calls from contracts
     */
    modifier userOnly() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * @notice Mints tokens during presale
     */
    function presaleMint(uint256 numTokens) external payable nonReentrant {
        require(state == SaleState.Presale, "Presale has not started yet");
        require(_numberMinted(msg.sender) + numTokens <= presaleAllowance[msg.sender], "You have exceeded your presale allowance");
        require(_totalMinted() + numTokens <= COLLECTION_SIZE, "Max supply reached");
        require(msg.value >= mintPrice * numTokens, "Insufficient ETH provided");
        _safeMint(msg.sender, numTokens);
    }

    /**
     * @notice Mints tokens during allow list minting
     */
    function allowListMint(uint256 numTokens, bytes32[] calldata proof) external payable userOnly {
        require(state == SaleState.AllowList, "Allow list minting has not started yet");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verifyAllowList(proof, leaf), "Invalid Merkle Tree proof supplied");
        require(_numberMinted(msg.sender) + numTokens <= allowListMintAllowance, "You have exceeded your allow list allowance");
        require(_totalMinted() + numTokens <= COLLECTION_SIZE, "Max supply reached");
        require(msg.value >= mintPrice * numTokens, "Insufficient ETH provided");
        _safeMint(msg.sender, numTokens);
    }

    /**
     * @notice Verifies if an address is allow list elgible given a merkle proof and leaf node
     */
    function _verifyAllowList(bytes32[] memory proof, bytes32 leaf) private view returns (bool) {
        return MerkleProof.verify(proof, allowListMerkleRoot, leaf);
    }

    /**
     * @notice Mints tokens during public sale
     */
    function publicMint(uint256 numTokens) external payable userOnly {
        require(state == SaleState.Public, "Sale has not started yet");
        require(numTokens <= MAX_BATCH_SIZE, "Quantity to mint too high");
        require(_totalMinted() + numTokens <= COLLECTION_SIZE, "Max supply reached");
        require(msg.value >= mintPrice * numTokens, "Insufficient ETH provided");
        _safeMint(msg.sender, numTokens);
    }
    
    /**
     * @notice Reserves tokens for team
     */
    function reserve(uint256 numTokens) external onlyOwner {
        require(_numberMinted(_reserveAddress) + numTokens <= RESERVE_LIMIT, "Cannot reserve that many");
        require(_totalMinted() + numTokens <= COLLECTION_SIZE, "Max supply reached");
        _safeMint(_reserveAddress, numTokens);
    }

    /**
     * @notice Changes state of sale
     */
    function setSaleState(SaleState state_) external onlyOwner {
        state = state_;
    }

    /**
     * @notice Modify presale allowance
     */
    function setPresaleAllowance(address[] memory addresses, uint256 amount) public onlyOwner {
        for (uint256 i; i < addresses.length; i++) {
            presaleAllowance[addresses[i]] = amount;
        }
    }

    /**
     * @notice Returns the presale allowance allocated to an address
     */
    function getPresaleAllowance(address address_) external view returns (uint256) {
        return presaleAllowance[address_];
    }

    /**
     * @notice Sets the root of the merkle tree used for the allow list
     */
    function setAllowListMerkleRoot(bytes32 allowListMerkleRoot_) external onlyOwner {
        allowListMerkleRoot = allowListMerkleRoot_;
    }

    /**
     * @dev See {ERC721A-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Provides URI with metadata
     * @dev Sets base URI used in _baseURI
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @notice Returns the amount of tokens minted by a given address
     */
    function amountMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @notice Changes mint price. Should only be used in extenuating circumstances
     * e.g. ETH price changes drastically
     */
    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    /**
     * @notice Change allowance per address on the allow list
     */
    function setAllowListMintAllowance(uint256 allowListMintAllowance_) external onlyOwner {
        allowListMintAllowance = allowListMintAllowance_;
    }

    /**
     * @notice Withdraw funds from contract
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = _withdrawalAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    receive() external payable {}
}