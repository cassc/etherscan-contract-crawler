// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC721Pausable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import { ERC721CrossChain, ERC721 } from "./ERC721/ERC721CrossChain.sol";
import { ERC721Queryable } from "./ERC721/ERC721Queryable.sol";
import { SalePhaseConfiguration } from "./lib/SalePhaseConfiguration.sol";
import { SignatureVerifier } from "./lib/SignatureVerifier.sol";
import { VRFIntegration } from "./lib/VRFIntegration.sol";
import { Withdrawable } from "./lib/Withdrawable.sol";
import { AwakeningAbility } from "./lib/AwakeningAbility.sol";

contract ElectricSheep is
    Ownable,
    ERC721Pausable,
    ERC721Queryable,
    ERC721CrossChain,
    SignatureVerifier,
    Withdrawable,
    SalePhaseConfiguration,
    VRFIntegration,
    AwakeningAbility
{
    error InsufficientPayment();
    error InsufficientContractBalance();
    error ExceedMaxMintQuantity();
    error ExceedMintQuota();
    error InvalidMintQuota();
    error CallerNotUser();
    error MintZeroQuantity();
    error SetRefundVaultToZeroAddress();
    error RefundNotEnabled();
    error RefundFailed();

    event ProvenanceUpdated(string provenance);
    event Refunded(address from, address to, uint256 tokenId);
    event RefundConfigUpdated(RefundConfig config);

    struct CurrentMintedAmount {
        uint64 builderMint;
        uint64 allowlist;
        uint64 publicSale;
        uint64 team;
    }

    struct RefundConfig {
        bool enabled;
        uint256 price;
        address vault;
    }

    uint256 public constant COLLECTION_SIZE = 10000;
    uint256 public constant TEAM_MINT_MAX = 200;
    CurrentMintedAmount public currentMintedAmount;
    uint256 public nextTokenId = 0;
    uint256 public tokenStartingOffset;
    string public tokenBaseURI;
    string public provenance;
    RefundConfig public refundConfig;
    mapping(address => uint256) public builderMintedPerAddress;
    mapping(address => uint256) public allowlistMintedPerAddress;
    mapping(address => uint256) public publicSaleMintedPerAddress;


    /**
     * @notice Constructor
     * @param name token name
     * @param symbol token symbol
     * @param coordinator chainlink VRF coordinator contract address
     * @param keyHash chainlink VRF key hash
     * @param subscriptionId chainlink VRF subscription id
     * 
     */
    constructor(
        string memory name,
        string memory symbol,
        address coordinator,
        bytes32 keyHash,
        uint64 subscriptionId
    )
        ERC721Queryable(COLLECTION_SIZE)
        ERC721CrossChain(name, symbol)
        SignatureVerifier(name, "1")
        VRFIntegration(coordinator, keyHash, subscriptionId)
    {}

    /**
     * @notice Caller is an externally owned account
     */
    modifier callerIsUser() {
        if (tx.origin != _msgSender()) {
            revert CallerNotUser();
        }
        _;
    }

    /**
     * @notice Check all sale phases' minting quantity
     * @param quantity mint quantity
     */
    modifier checkMintQuantityCommon(uint256 quantity) {
        if (quantity == 0) {
            revert MintZeroQuantity();
        }
        if (nextTokenId + quantity > COLLECTION_SIZE) {
            revert ExceedMaxMintQuantity();
        }
        _;
    }

    /**
     * @notice Mint for builder
     * @param quantity mint quantity
     * @param signature signature to verify minting
     */
    function builderMint(uint256 quantity, uint256 quota, bytes calldata signature)
        external
        payable
        callerIsUser
        whenBuilderMintActive
        checkMintQuantityCommon(quantity)
        verifyBuilderMint(quota, signature)
    {
        if (currentMintedAmount.builderMint + quantity > builderMintMaxAmount) {
            revert ExceedMaxMintQuantity();
        }
        address sender = _msgSender();
        if (quota == 0 || quota > builderMintMaxPerAddress) {
            revert InvalidMintQuota();
        }
        if (builderMintedPerAddress[sender] + quantity > quota) {
            revert ExceedMintQuota();
        }
        if (msg.value < quantity * builderMintPrice) {
            revert InsufficientPayment();
        }

        builderMintedPerAddress[sender] += quantity;
        currentMintedAmount.builderMint += uint64(quantity);
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(sender, nextTokenId++);
        }
    }

    /**
     * @notice Mint for allowlist
     * @param quantity mint quantity
     * @param quota mint quota for per address
     * @param signature signature to verify minting
     */
    function allowlistMint(uint256 quantity, uint256 quota, bytes calldata signature)
        external
        payable
        callerIsUser
        whenAllowlistActive
        checkMintQuantityCommon(quantity)
        verifyAllowlist(quota, signature)
    {
        if (currentMintedAmount.allowlist + quantity > allowlistMaxAmount) {
            revert ExceedMaxMintQuantity();
        }
        address sender = _msgSender();
        if (quota == 0 || quota > allowlistMaxMintPerAddress) {
            revert InvalidMintQuota();
        }
        if (allowlistMintedPerAddress[sender] + quantity > quota) {
            revert ExceedMintQuota();
        }
        if (msg.value < quantity * allowlistPrice) {
            revert InsufficientPayment();
        }

        allowlistMintedPerAddress[sender] += quantity;
        currentMintedAmount.allowlist += uint64(quantity);
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(sender, nextTokenId++);
        }
    }

    /**
     * @notice Mint for public sale
     * @param quantity mint quantity
     * @param signature signature to verify minting
     */
    function publicSaleMint(uint256 quantity, bytes calldata signature)
        external
        payable
        callerIsUser
        whenPublicSaleActive
        checkMintQuantityCommon(quantity)
        verifyPublicSale(quantity, signature)
    {
        if (currentMintedAmount.publicSale + quantity > publicSaleMaxAmount) {
            revert ExceedMaxMintQuantity();
        }
        address sender = _msgSender();
        if (publicSaleMintedPerAddress[sender] + quantity > publicSaleMaxMintPerAddress) {
            revert ExceedMintQuota();
        }
        if (msg.value < quantity * publicSalePrice) {
            revert InsufficientPayment();
        }

        publicSaleMintedPerAddress[sender] += quantity;
        currentMintedAmount.publicSale += uint64(quantity);
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(sender, nextTokenId++);
        }
    }

    /**
     * @notice Mint for publisher
     * @param to recevier address
     * @param quantity mint quantity
     */
    function teamMint(address to, uint256 quantity) external onlyOwner checkMintQuantityCommon(quantity) {
        if (currentMintedAmount.team + quantity > TEAM_MINT_MAX) {
            revert ExceedMaxMintQuantity();
        }

        currentMintedAmount.team += uint64(quantity);
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, nextTokenId++);
        }
    }

    /**
     * @notice Allow owners to refund their tokens, only available in ethereum chain
     * @param tokenId token to be refunded
     */
    function refund(uint256 tokenId) external callerIsUser nonReentrant {
        if (!isRefundEnabled()) {
            revert RefundNotEnabled();
        }
        if (address(this).balance < refundConfig.price) {
            revert InsufficientContractBalance();
        }
        address from = _msgSender();
        address to = refundConfig.vault;
        if (ownerOf(tokenId) != from) {
            revert CallerNotOwner();
        }
        safeTransferFrom(from, to, tokenId);
        emit Refunded(from, to, tokenId);
        (bool success, ) = from.call{value: refundConfig.price}("");
        if (!success) {
            revert RefundFailed();
        }
    }

    /**
     * @notice Set token base uri
     * @param uri uri
     */
    function setTokenBaseURI(string memory uri) external onlyOwner {
        tokenBaseURI = uri;
    }

    /**
     * @notice Change the provenance hash
     * Dealing with unforeseen circumstances, under community supervision
     * @param provenance_ provenance hash
     */
    function setProvenance(string memory provenance_) external onlyOwner {
        provenance = provenance_;
        emit ProvenanceUpdated(provenance);
    }

    /**
     * @notice Pause all token operations
     * Dealing with unforeseen circumstances, under community supervision
     */
    function emergencyPause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Enable and configure refund process
     * @param config refund config
     */
    function setRefundConfig(RefundConfig calldata config) external onlyOwner {
        if (config.vault == address(0)) {
            revert SetRefundVaultToZeroAddress();
        }
        refundConfig = config;
        emit RefundConfigUpdated(config);
    }

    /**
     * @notice Indicate if the refund process is enabled
     */
    function isRefundEnabled() public view returns (bool) {
        return refundConfig.enabled && refundConfig.price > 0 && refundConfig.vault != address(0);
    }

    /**
     * @notice Assign tokenId to tokens in the provenance sequence, which is decied by random number
     * @param seed random number
     */
    function afterRandomSeedSettled(uint256 seed) internal override {
        // The first three tokens are special edition, their tokenIds are fixed in 0/1/2;
        uint256 fixedTokens = 3;
        // offset ranges from 1 to 9996, avoid using the default sequence
        tokenStartingOffset = (seed % (COLLECTION_SIZE - fixedTokens - 1)) + 1;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Pausable, ERC721Queryable, AwakeningAbility) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }
}