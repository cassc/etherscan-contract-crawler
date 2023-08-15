// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { PullPaymentUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PullPaymentUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { Create2Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import { IVerifier } from "./interfaces/IVerifier.sol";
import { INFTFactory } from "./interfaces/INFTFactory.sol";
import { INFTRegistry } from "./interfaces/INFTRegistry.sol";
import { IRoyaltySplitter } from "./interfaces/IRoyaltySplitter.sol";
import { IFeeDistributor } from "./interfaces/IFeeDistributor.sol";
import { INFTOperator } from "./interfaces/INFTOperator.sol";
import { INFT } from "./interfaces/INFT.sol";
import { ParamEncoder } from "./libraries/ParamEncoder.sol";
import { NFT } from "./NFT.sol";

error CollectionExists(uint256 collectionId);
error CollectionNotFound(uint256 collectionId);
error CollectionItemLimitExceeded(uint256 collectionId, uint256 currentItemCount);
error ItemSupplyLimitExceeded(uint256 collectionId, uint256 deduplicationId, uint256 currentItemSupply);

contract NFTFactory is
    INFTFactory,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    PullPaymentUpgradeable
{
    using AddressUpgradeable for address payable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Collection {
        address nft;
        uint256 itemLimit;
        CountersUpgradeable.Counter itemCount;
    }

    bytes32 public constant VERSION = "1.2.0";
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IVerifier public verifier;
    uint8 private reserved1;
    bytes32 private reserved2;
    // collectionId => collectionData
    mapping(uint256 => Collection) public collections;
    // collectionId => deduplicationId => itemSupply
    // slither-disable-next-line uninitialized-state
    mapping(uint256 => mapping(uint256 => CountersUpgradeable.Counter)) public itemSupplies;
    INFTRegistry public defaultNFTRegistry;
    IRoyaltySplitter public royaltySplitter;
    IFeeDistributor public feeDistributor;
    INFTOperator public defaultNFTOperator;

    event VerifierSet(IVerifier indexed verifier);
    event DefaultNFTRegistrySet(INFTRegistry indexed defaultNFTRegistry);
    event RoyaltySplitterSet(IRoyaltySplitter indexed royaltySplitter);
    event FeeDistributorSet(IFeeDistributor indexed feeDistributor);
    event DefaultNFTOperatorSet(INFTOperator indexed defaultNFTOperator);
    event NFTRegistryDisabled(uint256 indexed collectionId, bool registryDisabled);
    event NFTOwnershipTransferred(uint256 indexed collectionId, address newOwner);
    event MaxItemSupplySet(uint256 maxItemSupply);
    event CollectionCreated(uint256 indexed collectionId);
    event TokenMinted(uint256 indexed collectionId, uint256 indexed tokenId);
    event TransactionProcessed(uint256 indexed transactionId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {
        _asyncTransfer(msg.sender, msg.value);
    }

    function initialize(
        IVerifier verifier_,
        INFTRegistry defaultNFTRegistry_,
        IRoyaltySplitter royaltySplitter_,
        IFeeDistributor feeDistributor_,
        INFTOperator defaultNFTOperator_
    ) external initializer {
        AccessControlUpgradeable.__AccessControl_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        PausableUpgradeable.__Pausable_init();
        PullPaymentUpgradeable.__PullPayment_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        verifier = verifier_;
        defaultNFTRegistry = defaultNFTRegistry_;
        royaltySplitter = royaltySplitter_;
        feeDistributor = feeDistributor_;
        defaultNFTOperator = defaultNFTOperator_;
    }

    function setVerifier(IVerifier verifier_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        verifier = verifier_;
        emit VerifierSet(verifier_);
    }

    function setDefaultNFTRegistry(INFTRegistry defaultNFTRegistry_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultNFTRegistry = defaultNFTRegistry_;
        emit DefaultNFTRegistrySet(defaultNFTRegistry_);
    }

    function setRoyaltySplitter(IRoyaltySplitter royaltySplitter_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltySplitter = royaltySplitter_;
        emit RoyaltySplitterSet(royaltySplitter_);
    }

    function setFeeDistributor(IFeeDistributor feeDistributor_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeDistributor = feeDistributor_;
        emit FeeDistributorSet(feeDistributor_);
    }

    function setDefaultNFTOperator(INFTOperator defaultNFTOperator_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultNFTOperator = defaultNFTOperator_;
        emit DefaultNFTOperatorSet(defaultNFTOperator_);
    }

    function setNFTRegistryDisabled(uint256 collectionId, bool registryDisabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address nft = collections[collectionId].nft;
        emit NFTRegistryDisabled(collectionId, registryDisabled);
        INFT(nft).setRegistryDisabled(registryDisabled);
    }

    function transferNFTOwnership(uint256 collectionId, address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address nft = collections[collectionId].nft;
        emit NFTOwnershipTransferred(collectionId, newOwner);
        INFT(nft).transferOwnership(newOwner);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        super._pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        super._unpause();
    }

    function createCollection(
        CreateCollectionParams calldata params,
        bytes calldata signature
    ) external payable nonReentrant whenNotPaused {
        bytes32 hash = _createCollectionHash(params, msg.sender);
        bool verified = verifier.verifySigner(hash, signature);
        if (!verified) {
            revert IVerifier.SignerNotVerified(hash, signature);
        }

        _createCollection(params);
    }

    function mintItem(
        MintItemParams calldata params,
        bytes calldata signature
    ) external payable nonReentrant whenNotPaused {
        bytes32 hash = _mintItemHash(params, msg.sender);
        bool verified = verifier.verifySigner(hash, signature);
        if (!verified) {
            revert IVerifier.SignerNotVerified(hash, signature);
        }

        _mintItem(params);
    }

    function mintItemUnsigned(
        MintItemParams calldata params
    ) external payable nonReentrant whenNotPaused onlyRole(MINTER_ROLE) {
        _mintItem(params);
    }

    function computeCollectionAddress(
        uint256 collectionId,
        string calldata name,
        string calldata symbol
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(type(NFT).creationCode, abi.encode(name, symbol, defaultNFTRegistry, defaultNFTOperator))
        );
        return Create2Upgradeable.computeAddress(bytes32(collectionId), bytecodeHash);
    }

    function createCollectionHash(
        CreateCollectionParams calldata params,
        address sender
    ) external pure returns (bytes32) {
        return _createCollectionHash(params, sender);
    }

    function mintItemHash(MintItemParams calldata params, address sender) external pure returns (bytes32) {
        return _mintItemHash(params, sender);
    }

    function _createCollection(CreateCollectionParams calldata params) private {
        uint256 collectionId = params.collectionId;
        if (collections[collectionId].nft != address(0)) {
            revert CollectionExists(collectionId);
        }

        NFT nft = new NFT{ salt: bytes32(collectionId) }(
            params.name,
            params.symbol,
            defaultNFTRegistry,
            defaultNFTOperator
        );
        collections[collectionId] = Collection({
            nft: address(nft),
            itemLimit: params.itemLimit,
            itemCount: CountersUpgradeable.Counter(0)
        });

        if (params.royalties.length > 0) {
            (address royaltyForwarder, uint96 totalShares) = royaltySplitter.registerCollectionRoyalty(
                address(nft),
                params.royalties
            );
            nft.setDefaultRoyalty(royaltyForwarder, totalShares);
        }

        if (params.fees.length > 0) {
            feeDistributor.distributeFees{ value: msg.value }(params.fees);
        }

        emit CollectionCreated(params.collectionId);
        emit TransactionProcessed(params.transactionId);
    }

    function _mintItem(MintItemParams calldata params) private {
        _setItemSupply(params.collectionId, params.deduplicationId, params.maxItemSupply);
        _mintToken(params.collectionId, params.tokenId, params.tokenReceiver, params.tokenURI, params.royalties);

        if (params.fees.length > 0) {
            feeDistributor.distributeFees{ value: msg.value }(params.fees);
        }

        emit TokenMinted(params.collectionId, params.tokenId);
        emit TransactionProcessed(params.transactionId);
    }

    function _setItemSupply(uint256 collectionId, uint256 deduplicationId, uint256 maxItemSupply) private {
        CountersUpgradeable.Counter storage itemSupply = itemSupplies[collectionId][deduplicationId];
        if (maxItemSupply != 0 && itemSupply.current() >= maxItemSupply) {
            revert ItemSupplyLimitExceeded(collectionId, deduplicationId, itemSupply.current());
        }

        itemSupply.increment();
    }

    function _mintToken(
        uint256 collectionId,
        uint256 tokenId,
        address tokenReceiver,
        string calldata tokenURI,
        IRoyaltySplitter.Royalty[] calldata royalties
    ) private {
        Collection storage collection = collections[collectionId];
        if (collection.nft == address(0)) {
            revert CollectionNotFound(collectionId);
        }
        if (collection.itemLimit != 0 && collection.itemCount.current() >= collection.itemLimit) {
            revert CollectionItemLimitExceeded(collectionId, collection.itemCount.current());
        }

        collection.itemCount.increment();

        INFT nft = INFT(collection.nft);
        nft.mint(tokenId, tokenReceiver, tokenURI);

        if (royalties.length > 0) {
            (address royaltyForwarder, uint96 totalShares) = royaltySplitter.registerTokenRoyalty(
                collection.nft,
                tokenId,
                royalties
            );
            nft.setTokenRoyalty(tokenId, royaltyForwarder, totalShares);
        }
    }

    function _createCollectionHash(
        CreateCollectionParams calldata params,
        address sender
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    params.transactionId,
                    params.collectionId,
                    params.name,
                    params.symbol,
                    params.itemLimit,
                    ParamEncoder.encodeFees(params.fees),
                    sender
                )
            );
    }

    function _mintItemHash(MintItemParams calldata params, address sender) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    params.transactionId,
                    params.collectionId,
                    params.tokenReceiver,
                    params.tokenId,
                    params.tokenURI,
                    params.deduplicationId,
                    params.maxItemSupply,
                    ParamEncoder.encodeRoyalty(params.royalties),
                    ParamEncoder.encodeFees(params.fees),
                    sender
                )
            );
    }
}