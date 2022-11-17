// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../utils/Ownable.sol";
import "../erc721/interfaces/IERC721GeneralMint.sol";
import "../erc721/interfaces/IERC721EditionMint.sol";
import "./interfaces/INativeMetaTransaction.sol";
import "../utils/EIP712Upgradeable.sol";
import "../metatx/ERC2771ContextUpgradeable.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title MintManager
 * @author [email protected], [email protected]
 * @dev Faciliates lion's share of minting in Highlight protocol V2 by managing mint "vectors" on-chain and off-chain
 */
contract MintManager is EIP712Upgradeable, UUPSUpgradeable, OwnableUpgradeable, ERC2771ContextUpgradeable {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev On-chain mint vector
     * @param contractAddress NFT smart contract address
     * @param currency Currency used for payment. Native gas token, if zero address
     * @param paymentRecipient Payment recipient
     * @param startTimestamp When minting opens on vector
     * @param endTimestamp When minting ends on vector
     * @param pricePerToken Price that has to be paid per minted token
     * @param tokenLimitPerTx Max number of tokens that can be minted in one transaction
     * @param maxTotalClaimableViaVector Max number of tokens that can be minted via vector
     * @param maxUserClaimableViaVector Max number of tokens that can be minted by user via vector
     * @param totalClaimedViaVector Total number of tokens minted via vector
     * @param allowlistRoot Root of merkle tree with allowlist
     * @param paused If vector is paused
     */
    struct Vector {
        address contractAddress;
        address currency;
        address payable paymentRecipient;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 pricePerToken;
        uint64 tokenLimitPerTx;
        uint64 maxTotalClaimableViaVector;
        uint64 maxUserClaimableViaVector;
        uint64 totalClaimedViaVector;
        bytes32 allowlistRoot;
        uint8 paused;
    }

    /**
     * @dev On-chain mint vector mutability rules
     * @param updatesFrozen If true, vector cannot be updated
     * @param deleteFrozen If true, vector cannot be deleted
     * @param pausesFrozen If true, vector cannot be paused
     */
    struct VectorMutability {
        uint8 updatesFrozen;
        uint8 deleteFrozen;
        uint8 pausesFrozen;
    }

    /**
     * @dev Packet enabling impersonation of purchaser for currencies supporting meta-transactions
     * @param functionSignature Function to call on contract, with arguments encoded
     * @param sigR Elliptic curve signature component
     * @param sigS Elliptic curve signature component
     * @param sigV Elliptic curve signature component
     */
    struct PurchaserMetaTxPacket {
        bytes functionSignature;
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
    }

    /**
     * @dev Claim that is signed off-chain with EIP-712, and unwrapped to facilitate fulfillment of mint
     * @param currency Currency used for payment. Native gas token, if zero address
     * @param contractAddress NFT smart contract address
     * @param claimer Account able to use this claim
     * @param paymentRecipient Payment recipient
     * @param pricePerToken Price that has to be paid per minted token
     * @param numTokensToMint Number of NFTs to mint in this transaction
     * @param maxClaimableViaVector Max number of tokens that can be minted via vector
     * @param maxClaimablePerUser Max number of tokens that can be minted by user via vector
     * @param editionId ID of edition to mint on. Unused if claim is passed into ERC721General minting function
     * @param claimExpiryTimestamp Time when claim expires
     * @param claimNonce Unique identifier of claim
     * @param offchainVectorId Unique identifier of vector offchain
     */
    struct Claim {
        address currency;
        address contractAddress;
        address claimer;
        address payable paymentRecipient;
        uint256 pricePerToken;
        uint64 numTokensToMint;
        uint256 maxClaimableViaVector;
        uint256 maxClaimablePerUser;
        uint256 editionId;
        uint256 claimExpiryTimestamp;
        bytes32 claimNonce;
        bytes32 offchainVectorId;
    }

    /**
     * @dev Claim that is signed off-chain with EIP-712, and unwrapped to facilitate fulfillment of mint.
     *      Includes meta-tx packets to impersonate purchaser and make payments.
     * @param currency Currency used for payment. Native gas token, if zero address
     * @param contractAddress NFT smart contract address
     * @param claimer Account able to use this claim
     * @param paymentRecipient Payment recipient
     * @param pricePerToken Price that has to be paid per minted token
     * @param numTokensToMint Number of NFTs to mint in this transaction
     * @param purchaseToCreatorPacket Meta-tx packet that send portion of payment to creator
     * @param purchaseToPlatformPacket Meta-tx packet that send portion of payment to platform
     * @param maxClaimableViaVector Max number of tokens that can be minted via vector
     * @param maxClaimablePerUser Max number of tokens that can be minted by user via vector
     * @param editionId ID of edition to mint on. Unused if claim is passed into ERC721General minting function
     * @param claimExpiryTimestamp Time when claim expires
     * @param claimNonce Unique identifier of claim
     * @param offchainVectorId Unique identifier of vector offchain
     */
    struct ClaimWithMetaTxPacket {
        address currency;
        address contractAddress;
        address claimer;
        uint256 pricePerToken;
        uint64 numTokensToMint;
        PurchaserMetaTxPacket purchaseToCreatorPacket;
        PurchaserMetaTxPacket purchaseToPlatformPacket;
        uint256 maxClaimableViaVector;
        uint256 maxClaimablePerUser;
        uint256 editionId; // unused if for general contract mints
        uint256 claimExpiryTimestamp;
        bytes32 claimNonce;
        bytes32 offchainVectorId;
    }

    /**
     * @dev Tracks current claim state of offchain vectors
     * @param numClaimed Total claimed on vector
     * @param numClaimedPerUser Tracks totals claimed per user on vector
     */
    struct OffchainVectorClaimState {
        uint256 numClaimed;
        mapping(address => uint256) numClaimedPerUser;
    }

    /* solhint-disable max-line-length */
    /**
     * @dev DEPRECATED - Claim typehash used via typed structured data hashing (EIP-712)
     */
    bytes32 private constant _CLAIM_TYPEHASH =
        keccak256(
            "Claim(address currency,address contractAddress,address claimer,address paymentRecipient,uint256 pricePerToken,uint64 numTokensToMint,uint256 maxClaimableViaVector,uint256 maxClaimablePerUser,uint256 editionId,uint256 claimExpiryTimestamp,bytes32 claimNonce,bytes32 offchainVectorId)"
        );

    /**
     * @dev DEPRECATED - Claim typehash used via typed structured data hashing (EIP-712)
     */
    bytes32 private constant _CLAIM_WITH_META_TX_PACKET_TYPEHASH =
        keccak256(
            "ClaimWithMetaTxPacket(address currency,address contractAddress,address claimer,uint256 pricePerToken,uint64 numTokensToMint,PurchaserMetaTxPacket purchaseToCreatorPacket,PurchaserMetaTxPacket purchaseToCreatorPacket,uint256 maxClaimableViaVector,uint256 maxClaimablePerUser,uint256 editionId,uint256 claimExpiryTimestamp,bytes32 claimNonce,bytes32 offchainVectorId)"
        );

    /* solhint-enable max-line-length */

    /**
     * @dev Platform receiving portion of payment
     */
    address payable private _platform;

    /**
     * @dev System-wide mint vectors
     */
    mapping(uint256 => Vector) public vectors;

    /**
     * @dev System-wide mint vectors' mutabilities
     */
    mapping(uint256 => VectorMutability) public vectorMutabilities;

    /**
     * @dev System-wide vector ids to (user to user claims count)
     */
    mapping(uint256 => mapping(address => uint64)) public userClaims;

    /**
     * @dev Tracks what nonces used in signed mint keys have been used for vectors enforced offchain
     *      Requires the platform to not re-use offchain vector IDs.
     */
    mapping(bytes32 => EnumerableSet.Bytes32Set) private _offchainVectorsToNoncesUsed;

    /**
     * @dev Tracks running state of offchain vectors
     */
    mapping(bytes32 => OffchainVectorClaimState) public offchainVectorsClaimState;

    /**
     * @dev Maps vector ids to edition ids
     */
    mapping(uint256 => uint256) public vectorToEditionId;

    /**
     * @dev Current vector id index
     */
    uint256 private _vectorSupply;

    /**
     * @dev Platform transaction executors
     */
    EnumerableSet.AddressSet internal _platformExecutors;

    /**
     * @dev Emitted when platform executor is added or removed
     * @param executor Changed executor
     * @param added True if executor was added and false otherwise
     */
    event PlatformExecutorChanged(address indexed executor, bool indexed added);

    /**
     * @dev Emitted when vector is created on-chain
     * @param vectorId ID of vector
     * @param editionId Edition id of vector, meaningful if vector is for Editions collection
     * @param vector Vector to create
     */
    event VectorCreated(uint256 indexed vectorId, uint256 indexed editionId, Vector vector);

    /**
     * @dev Emitted when vector is updated on-chain
     * @param vectorId ID of vector
     * @param newVector New vector details
     */
    event VectorUpdated(uint256 indexed vectorId, Vector newVector);

    /**
     * @dev Emitted when vector is deleted on-chain
     * @param vectorId ID of vector to delete
     */
    event VectorDeleted(uint256 indexed vectorId);

    /**
     * @dev Emitted when vector is paused or unpaused on-chain
     * @param vectorId ID of vector
     * @param paused True if vector was paused, false otherwise
     */
    event VectorPausedOrUnpaused(uint256 indexed vectorId, uint8 indexed paused);

    /**
     * @dev Emitted when vector mutability updated
     * @param vectorId ID of vector
     * @param _newVectorMutability New vector mutability
     */
    event VectorMutabilityUpdated(uint256 indexed vectorId, VectorMutability _newVectorMutability);

    /**
     * @dev Emits when native gas token held by contract is withdrawn by platform
     * @param withdrawnValue Amount withdrawn
     */
    event NativeGasTokenWithdrawn(uint256 withdrawnValue);

    /**
     * @dev Emitted when payment is made in native gas token
     * @param paymentRecipient Creator recipient of payment
     * @param vectorId Vector that payment was for
     * @param amountToCreator Amount sent to creator
     * @param percentageBPSOfTotal Percentage (in basis points) that was sent to creator, of total payment
     */
    event NativeGasTokenPayment(
        address indexed paymentRecipient,
        bytes32 indexed vectorId,
        uint256 amountToCreator,
        uint32 percentageBPSOfTotal
    );

    /**
     * @dev Emitted when payment is made in ERC20
     * @param currency ERC20 currency
     * @param paymentRecipient Creator recipient of payment
     * @param vectorId Vector that payment was for
     * @param payer Payer
     * @param amountToCreator Amount sent to creator
     * @param percentageBPSOfTotal Percentage (in basis points) that was sent to creator, of total payment
     */
    event ERC20Payment(
        address indexed currency,
        address indexed paymentRecipient,
        bytes32 indexed vectorId,
        address payer,
        uint256 amountToCreator,
        uint32 percentageBPSOfTotal
    );

    /**
     * @dev Emitted when payment is made in ERC20 via meta-tx packet method
     * @param currency ERC20 currency
     * @param msgSender Payer
     * @param vectorId Vector that payment was for
     * @param purchaseToCreatorPacket Meta-tx packet facilitating payment to creator
     * @param purchaseToPlatformPacket Meta-tx packet facilitating payment to platform
     * @param amount Payment amount
     */
    event ERC20PaymentMetaTxPackets(
        address indexed currency,
        address indexed msgSender,
        bytes32 indexed vectorId,
        PurchaserMetaTxPacket purchaseToCreatorPacket,
        PurchaserMetaTxPacket purchaseToPlatformPacket,
        uint256 amount
    );

    /**
     * @dev Restricts calls to platform
     */
    modifier onlyPlatform() {
        require(_msgSender() == _platform, "Not platform");
        _;
    }

    /**
     * @dev Initializes MintManager
     * @param platform Platform address
     * @param _owner MintManager owner
     * @param trustedForwarder Trusted meta-tx executor
     * @param initialExecutor Initial platform executor
     */
    function initialize(
        address payable platform,
        address _owner,
        address trustedForwarder,
        address initialExecutor
    ) external initializer {
        _platform = platform;
        __EIP721Upgradeable_initialize("MintManager", "1.0.0");
        __ERC2771ContextUpgradeable__init__(trustedForwarder);
        __Ownable_init();
        _transferOwnership(_owner);
        _platformExecutors.add(initialExecutor);
    }

    /**
     * @dev Add platform executor. Expected to be protected by a smart contract wallet.
     * @param _executor Platform executor to add
     */
    function addPlatformExecutor(address _executor) external onlyOwner {
        require(_executor != address(0), "Cannot set to null address");
        require(_platformExecutors.add(_executor), "Already added");
        emit PlatformExecutorChanged(_executor, true);
    }

    /**
     * @dev Deprecate platform executor. Expected to be protected by a smart contract wallet.
     * @param _executor Platform executor to deprecate
     */
    function deprecatePlatformExecutor(address _executor) external onlyOwner {
        require(_platformExecutors.remove(_executor), "Not deprecated");
        emit PlatformExecutorChanged(_executor, false);
    }

    /**
     * @dev Creates on-chain vector
     * @param _vector Vector to create
     * @param _vectorMutability Vector mutability
     * @param editionId Edition id of vector, meaningful if vector is for Editions collection
     */
    function createVector(
        Vector calldata _vector,
        VectorMutability calldata _vectorMutability,
        uint256 editionId
    ) external {
        require(Ownable(_vector.contractAddress).owner() == _msgSender(), "Not contract owner");
        require(_vector.totalClaimedViaVector == 0, "totalClaimedViaVector not 0");

        _vectorSupply++;
        vectors[_vectorSupply] = _vector;
        vectorMutabilities[_vectorSupply] = _vectorMutability;
        vectorToEditionId[_vectorSupply] = editionId;

        emit VectorCreated(_vectorSupply, editionId, _vector);
    }

    /**
     * @dev Updates on-chain vector
     * @param vectorId ID of vector to update
     * @param _newVector New vector details
     */
    function updateVector(uint256 vectorId, Vector calldata _newVector) external {
        Vector memory _oldVector = vectors[vectorId];
        require(vectorMutabilities[vectorId].updatesFrozen == 0, "Updates frozen");
        require(_oldVector.totalClaimedViaVector == _newVector.totalClaimedViaVector, "Total claimed different");
        require(Ownable(_oldVector.contractAddress).owner() == _msgSender(), "Not contract owner");

        vectors[vectorId] = _newVector;

        emit VectorUpdated(vectorId, _newVector);
    }

    /**
     * @dev Deletes on-chain vector
     * @param vectorId ID of vector to delete
     */
    function deleteVector(uint256 vectorId) external {
        Vector memory _oldVector = vectors[vectorId];
        require(vectorMutabilities[vectorId].deleteFrozen == 0, "Delete frozen");
        require(Ownable(_oldVector.contractAddress).owner() == _msgSender(), "Not contract owner");

        delete vectors[vectorId];
        delete vectorMutabilities[vectorId];
        delete vectorToEditionId[_vectorSupply];

        emit VectorDeleted(vectorId);
    }

    /**
     * @dev Pauses on-chain vector
     * @param vectorId ID of vector to pause
     */
    function pauseVector(uint256 vectorId) external {
        Vector memory _oldVector = vectors[vectorId];
        require(vectorMutabilities[vectorId].pausesFrozen == 0, "Pauses frozen");
        require(Ownable(_oldVector.contractAddress).owner() == _msgSender(), "Not contract owner");

        vectors[vectorId].paused = 1;

        emit VectorPausedOrUnpaused(vectorId, 1);
    }

    /**
     * @dev Unpauses on-chain vector
     * @param vectorId ID of vector to unpause
     */
    function unpauseVector(uint256 vectorId) external {
        Vector memory _oldVector = vectors[vectorId];
        require(Ownable(_oldVector.contractAddress).owner() == _msgSender(), "Not contract owner");

        vectors[vectorId].paused = 0;

        emit VectorPausedOrUnpaused(vectorId, 0);
    }

    /**
     * @dev Updates on-chain vector mutability. Protected by vector mutability field updatesFrozen itself
     * @param vectorId ID of vector mutability to update
     * @param _newVectorMutability New vector mutability details
     */
    function updateVectorMutability(uint256 vectorId, VectorMutability calldata _newVectorMutability) external {
        require(vectorMutabilities[vectorId].updatesFrozen == 0, "Updates frozen");
        require(Ownable(vectors[vectorId].contractAddress).owner() == _msgSender(), "Not contract owner");

        vectorMutabilities[vectorId] = _newVectorMutability;

        emit VectorMutabilityUpdated(vectorId, _newVectorMutability);
    }

    /**
     * @dev Mint on vector pointing to ERC721General collection
     * @param vectorId ID of vector
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     */
    function vectorMintGeneral721(
        uint256 vectorId,
        uint64 numTokensToMint,
        address mintRecipient
    ) external payable {
        address msgSender = _msgSender();

        require(msgSender == tx.origin, "Smart contracts not allowed");

        Vector memory _vector = vectors[vectorId];
        uint64 newNumClaimedViaVector = _vector.totalClaimedViaVector + numTokensToMint;
        uint64 newNumClaimedForUser = userClaims[vectorId][msgSender] + numTokensToMint;

        require(_vector.allowlistRoot == 0, "Use allowlist mint");

        _vectorMintGeneral721(
            vectorId,
            _vector,
            numTokensToMint,
            mintRecipient,
            newNumClaimedViaVector,
            newNumClaimedForUser
        );

        vectors[vectorId].totalClaimedViaVector = newNumClaimedViaVector;
        userClaims[vectorId][msgSender] = newNumClaimedForUser;
    }

    /**
     * @dev Mint on vector pointing to ERC721General collection, with allowlist
     * @param vectorId ID of vector
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     * @param proof Proof of minter's inclusion in allowlist
     */
    function vectorMintGeneral721WithAllowlist(
        uint256 vectorId,
        uint64 numTokensToMint,
        address mintRecipient,
        bytes32[] calldata proof
    ) external payable {
        address msgSender = _msgSender();

        require(msgSender == tx.origin, "Smart contracts not allowed");

        Vector memory _vector = vectors[vectorId];
        uint64 newNumClaimedViaVector = _vector.totalClaimedViaVector + numTokensToMint;
        uint64 newNumClaimedForUser = userClaims[vectorId][msgSender] + numTokensToMint;

        // merkle tree allowlist validation
        bytes32 leaf = keccak256(abi.encodePacked(msgSender));
        require(MerkleProof.verify(proof, _vector.allowlistRoot, leaf), "Invalid proof");

        _vectorMintGeneral721(
            vectorId,
            _vector,
            numTokensToMint,
            mintRecipient,
            newNumClaimedViaVector,
            newNumClaimedForUser
        );

        vectors[vectorId].totalClaimedViaVector = newNumClaimedViaVector;
        userClaims[vectorId][msgSender] = newNumClaimedForUser;
    }

    /**
     * @dev Mint on am ERC721General collection with a valid claim
     * @param claim Claim
     * @param claimSignature Signed + encoded claim
     * @param mintRecipient Who to mint the NFT(s) to
     */
    function gatedMintGeneral721(
        Claim calldata claim,
        bytes calldata claimSignature,
        address mintRecipient
    ) external payable {
        _processGatedMintClaim(claim, claimSignature);
        // mint NFT(s)
        if (claim.numTokensToMint == 1) {
            IERC721GeneralMint(claim.contractAddress).mintOneToOneRecipient(mintRecipient);
        } else {
            IERC721GeneralMint(claim.contractAddress).mintAmountToOneRecipient(mintRecipient, claim.numTokensToMint);
        }
    }

    /**
     * @dev Mint on am ERC721General collection with a valid claim, using meta-tx packets
     * @param claim Claim
     * @param claimSignature Signed + encoded claim
     * @param mintRecipient Who to mint the NFT(s) to
     */
    function gatedMintPaymentPacketGeneral721(
        ClaimWithMetaTxPacket calldata claim,
        bytes calldata claimSignature,
        address mintRecipient
    ) external {
        address msgSender = _msgSender();

        _verifyAndUpdateClaimWithMetaTxPacket(claim, claimSignature, msgSender);

        require(claim.currency != address(0), "Not ERC20 payment");

        // make payments
        if (claim.pricePerToken > 0) {
            _processERC20PaymentWithMetaTxPackets(
                claim.currency,
                claim.purchaseToCreatorPacket,
                claim.purchaseToPlatformPacket,
                msgSender,
                claim.offchainVectorId,
                claim.pricePerToken * claim.numTokensToMint
            );
        }

        // mint NFT(s)
        if (claim.numTokensToMint == 1) {
            IERC721GeneralMint(claim.contractAddress).mintOneToOneRecipient(mintRecipient);
        } else {
            IERC721GeneralMint(claim.contractAddress).mintAmountToOneRecipient(mintRecipient, claim.numTokensToMint);
        }
    }

    /**
     * @dev Mint on vector pointing to ERC721Editions or ERC721SingleEdiion collection
     * @param vectorId ID of vector
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     */
    function vectorMintEdition721(
        uint256 vectorId,
        uint64 numTokensToMint,
        address mintRecipient
    ) external payable {
        address msgSender = _msgSender();

        require(msgSender == tx.origin, "Smart contracts not allowed");

        Vector memory _vector = vectors[vectorId];
        uint64 newNumClaimedViaVector = _vector.totalClaimedViaVector + numTokensToMint;
        uint64 newNumClaimedForUser = userClaims[vectorId][msgSender] + numTokensToMint;

        require(_vector.allowlistRoot == 0, "Use allowlist mint");

        _vectorMintEdition721(
            vectorId,
            _vector,
            vectorToEditionId[vectorId],
            numTokensToMint,
            mintRecipient,
            newNumClaimedViaVector,
            newNumClaimedForUser
        );

        vectors[vectorId].totalClaimedViaVector = newNumClaimedViaVector;
        userClaims[vectorId][msgSender] = newNumClaimedForUser;
    }

    /**
     * @dev Mint on vector pointing to ERC721Editions or ERC721SingleEdiion collection, with allowlist
     * @param vectorId ID of vector
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     * @param proof Proof of minter's inclusion in allowlist
     */
    function vectorMintEdition721WithAllowlist(
        uint256 vectorId,
        uint64 numTokensToMint,
        address mintRecipient,
        bytes32[] calldata proof
    ) external payable {
        address msgSender = _msgSender();

        require(msgSender == tx.origin, "Smart contracts not allowed");

        Vector memory _vector = vectors[vectorId];
        uint64 newNumClaimedViaVector = _vector.totalClaimedViaVector + numTokensToMint;
        uint64 newNumClaimedForUser = userClaims[vectorId][msgSender] + numTokensToMint;

        // merkle tree allowlist validation
        bytes32 leaf = keccak256(abi.encodePacked(msgSender));
        require(MerkleProof.verify(proof, _vector.allowlistRoot, leaf), "Invalid proof");

        _vectorMintEdition721(
            vectorId,
            _vector,
            vectorToEditionId[vectorId],
            numTokensToMint,
            mintRecipient,
            newNumClaimedViaVector,
            newNumClaimedForUser
        );

        vectors[vectorId].totalClaimedViaVector = newNumClaimedViaVector;
        userClaims[vectorId][msgSender] = newNumClaimedForUser;
    }

    /**
     * @dev Mint on an ERC721Editions or ERC721SingleEdiion collection with a valid claim
     * @param _claim Claim
     * @param _signature Signed + encoded claim
     * @param _recipient Who to mint the NFT(s) to
     */
    function gatedMintEdition721(
        Claim calldata _claim,
        bytes calldata _signature,
        address _recipient
    ) external payable {
        _processGatedMintClaim(_claim, _signature);
        // mint NFT(s)
        if (_claim.numTokensToMint == 1) {
            IERC721EditionMint(_claim.contractAddress).mintOneToRecipient(_claim.editionId, _recipient);
        } else {
            IERC721EditionMint(_claim.contractAddress).mintAmountToRecipient(
                _claim.editionId,
                _recipient,
                _claim.numTokensToMint
            );
        }
    }

    /**
     * @dev Mint on an ERC721Editions or ERC721SingleEdiion collection with a valid claim, using meta-tx packets
     * @param claim Claim
     * @param claimSignature Signed + encoded claim
     * @param mintRecipient Who to mint the NFT(s) to
     */
    function gatedMintPaymentPacketEdition721(
        ClaimWithMetaTxPacket calldata claim,
        bytes calldata claimSignature,
        address mintRecipient
    ) external {
        address msgSender = _msgSender();

        _verifyAndUpdateClaimWithMetaTxPacket(claim, claimSignature, msgSender);

        require(claim.currency != address(0), "Has to be ERC20 payment");

        // make payments
        if (claim.pricePerToken > 0) {
            _processERC20PaymentWithMetaTxPackets(
                claim.currency,
                claim.purchaseToCreatorPacket,
                claim.purchaseToPlatformPacket,
                msgSender,
                claim.offchainVectorId,
                claim.pricePerToken * claim.numTokensToMint
            );
        }

        // mint NFT(s)
        if (claim.numTokensToMint == 1) {
            IERC721EditionMint(claim.contractAddress).mintOneToRecipient(claim.editionId, mintRecipient);
        } else {
            IERC721EditionMint(claim.contractAddress).mintAmountToRecipient(
                claim.editionId,
                mintRecipient,
                claim.numTokensToMint
            );
        }
    }

    /**
     * @dev Withdraw native gas token owed to platform
     */
    function withdrawNativeGasToken() external onlyPlatform {
        uint256 withdrawnValue = address(this).balance;
        (bool sentToPlatform, bytes memory dataPlatform) = _platform.call{ value: withdrawnValue }("");
        require(sentToPlatform, "Failed to send Ether to platform");

        emit NativeGasTokenWithdrawn(withdrawnValue);
    }

    /**
     * @dev Returns platform executors
     */
    function platformExecutors() external view returns (address[] memory) {
        return _platformExecutors.values();
    }

    /**
     * @dev Returns claim ids used for an offchain vector
     * @param vectorId ID of offchain vector
     */
    function getClaimNoncesUsedForOffchainVector(bytes32 vectorId) external view returns (bytes32[] memory) {
        return _offchainVectorsToNoncesUsed[vectorId].values();
    }

    /**
     * @dev Returns number of NFTs minted by user on vector
     * @param vectorId ID of offchain vector
     * @param user Minting user
     */
    function getNumClaimedPerUserOffchainVector(bytes32 vectorId, address user) external view returns (uint256) {
        return offchainVectorsClaimState[vectorId].numClaimedPerUser[user];
    }

    /**
     * @dev Verify that claim and claim signature are valid for a mint
     * @param claim Claim
     * @param signature Signed + encoded claim
     * @param expectedMsgSender Expected claimer to verify claim for
     */
    function verifyClaim(
        Claim calldata claim,
        bytes calldata signature,
        address expectedMsgSender
    ) external view returns (bool) {
        address signer = _claimSigner(claim, signature);
        require(expectedMsgSender == claim.claimer, "Sender not claimer");

        return
            _isPlatformExecutor(signer) &&
            !_offchainVectorsToNoncesUsed[claim.offchainVectorId].contains(claim.claimNonce) &&
            block.timestamp <= claim.claimExpiryTimestamp &&
            (claim.maxClaimableViaVector == 0 ||
                claim.numTokensToMint + offchainVectorsClaimState[claim.offchainVectorId].numClaimed <=
                claim.maxClaimableViaVector) &&
            (claim.maxClaimablePerUser == 0 ||
                claim.numTokensToMint +
                    offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[expectedMsgSender] <=
                claim.maxClaimablePerUser);
    }

    /**
     * @dev Verify that claim and claim signature are valid for a mint (claim version with meta-tx packets)
     * @param claim Claim
     * @param signature Signed + encoded claim
     * @param expectedMsgSender Expected claimer to verify claim for
     */
    function verifyClaimWithMetaTxPacket(
        ClaimWithMetaTxPacket calldata claim,
        bytes calldata signature,
        address expectedMsgSender
    ) external view returns (bool) {
        address signer = _claimWithMetaTxPacketSigner(claim, signature);
        require(expectedMsgSender == claim.claimer, "Sender not claimer");

        return
            _isPlatformExecutor(signer) &&
            !_offchainVectorsToNoncesUsed[claim.offchainVectorId].contains(claim.claimNonce) &&
            block.timestamp <= claim.claimExpiryTimestamp &&
            (claim.maxClaimableViaVector == 0 ||
                claim.numTokensToMint + offchainVectorsClaimState[claim.offchainVectorId].numClaimed <=
                claim.maxClaimableViaVector) &&
            (claim.maxClaimablePerUser == 0 ||
                claim.numTokensToMint +
                    offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[expectedMsgSender] <=
                claim.maxClaimablePerUser);
    }

    /**
     * @dev Returns if nonce is used for the vector
     * @param vectorId ID of offchain vector
     * @param nonce Nonce being checked
     */
    function isNonceUsed(bytes32 vectorId, bytes32 nonce) external view returns (bool) {
        return _offchainVectorsToNoncesUsed[vectorId].contains(nonce);
    }

    /* solhint-disable no-empty-blocks */
    /**
     * @dev Limit upgrades of contract to MintManager owner
     * @param // New implementation address
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /* solhint-enable no-empty-blocks */

    /**
     * @dev Used for meta-transactions
     */
    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @dev Used for meta-transactions
     */
    function _msgData() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @dev Process, verify, and update the state of a gated mint claim
     * @param claim Claim
     * @param claimSignature Signed + encoded claim
     */
    function _processGatedMintClaim(Claim calldata claim, bytes calldata claimSignature) private {
        address msgSender = _msgSender();

        _verifyAndUpdateClaim(claim, claimSignature, msgSender);

        // make payments
        if (claim.currency == address(0) && claim.pricePerToken > 0) {
            // pay in native gas token
            uint256 amount = claim.numTokensToMint * claim.pricePerToken;
            _processNativeGasTokenPayment(amount, claim.paymentRecipient, claim.offchainVectorId);
        } else if (claim.pricePerToken > 0) {
            // pay in ERC20
            uint256 amount = claim.numTokensToMint * claim.pricePerToken;
            _processERC20Payment(amount, claim.paymentRecipient, msgSender, claim.currency, claim.offchainVectorId);
        }
    }

    /**
     * @dev Verify, and update the state of a gated mint claim
     * @param claim Claim
     * @param signature Signed + encoded claim
     * @param msgSender Expected claimer
     */
    function _verifyAndUpdateClaim(
        Claim calldata claim,
        bytes calldata signature,
        address msgSender
    ) private {
        address signer = _claimSigner(claim, signature);
        require(msgSender == claim.claimer, "Sender not claimer");

        // cannot cache here due to nested mapping
        uint256 expectedNumClaimedViaVector = offchainVectorsClaimState[claim.offchainVectorId].numClaimed +
            claim.numTokensToMint;
        uint256 expectedNumClaimedByUser = offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[
            msgSender
        ] + claim.numTokensToMint;

        require(
            _isPlatformExecutor(signer) &&
                !_offchainVectorsToNoncesUsed[claim.offchainVectorId].contains(claim.claimNonce) &&
                block.timestamp <= claim.claimExpiryTimestamp &&
                (expectedNumClaimedViaVector <= claim.maxClaimableViaVector || claim.maxClaimableViaVector == 0) &&
                (expectedNumClaimedByUser <= claim.maxClaimablePerUser || claim.maxClaimablePerUser == 0),
            "Invalid claim"
        );

        _offchainVectorsToNoncesUsed[claim.offchainVectorId].add(claim.claimNonce); // mark claim nonce as used
        // update claim state
        offchainVectorsClaimState[claim.offchainVectorId].numClaimed = expectedNumClaimedViaVector;
        offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[msgSender] = expectedNumClaimedByUser;
    }

    /**
     * @dev Verify, and update the state of a gated mint claim (version w/ meta-tx packets)
     * @param claim Claim
     * @param signature Signed + encoded claim
     * @param msgSender Expected claimer
     */
    function _verifyAndUpdateClaimWithMetaTxPacket(
        ClaimWithMetaTxPacket calldata claim,
        bytes calldata signature,
        address msgSender
    ) private {
        address signer = _claimWithMetaTxPacketSigner(claim, signature);
        require(msgSender == claim.claimer, "Sender not claimer");

        // cannot cache here due to nested mapping
        uint256 expectedNumClaimedViaVector = offchainVectorsClaimState[claim.offchainVectorId].numClaimed +
            claim.numTokensToMint;
        uint256 expectedNumClaimedByUser = offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[
            msgSender
        ] + claim.numTokensToMint;

        require(
            _isPlatformExecutor(signer) &&
                !_offchainVectorsToNoncesUsed[claim.offchainVectorId].contains(claim.claimNonce) &&
                block.timestamp <= claim.claimExpiryTimestamp &&
                (expectedNumClaimedViaVector <= claim.maxClaimableViaVector || claim.maxClaimableViaVector == 0) &&
                (expectedNumClaimedByUser <= claim.maxClaimablePerUser || claim.maxClaimablePerUser == 0),
            "Invalid claim"
        );

        _offchainVectorsToNoncesUsed[claim.offchainVectorId].add(claim.claimNonce); // mark claim nonce as used
        // update claim state
        offchainVectorsClaimState[claim.offchainVectorId].numClaimed = expectedNumClaimedViaVector;
        offchainVectorsClaimState[claim.offchainVectorId].numClaimedPerUser[msgSender] = expectedNumClaimedByUser;
    }

    /**
     * @dev Process a mint on an on-chain vector
     * @param _vectorId ID of vector being minted on
     * @param _vector Vector being minted on
     * @param numTokensToMint Number of NFTs to mint on vector
     * @param newNumClaimedViaVector New number of NFTs minted via vector after this ones
     * @param newNumClaimedForUser New number of NFTs minted by user via vector after this ones
     */
    function _processVectorMint(
        uint256 _vectorId,
        Vector memory _vector,
        uint64 numTokensToMint,
        uint256 newNumClaimedViaVector,
        uint256 newNumClaimedForUser
    ) private {
        require(
            _vector.maxTotalClaimableViaVector >= newNumClaimedViaVector || _vector.maxTotalClaimableViaVector == 0,
            "> maxClaimableViaVector"
        );
        require(
            _vector.maxUserClaimableViaVector >= newNumClaimedForUser || _vector.maxUserClaimableViaVector == 0,
            "> maxClaimablePerUser"
        );
        require(_vector.paused == 0, "Vector paused");
        require(
            (_vector.startTimestamp <= block.timestamp || _vector.startTimestamp == 0) &&
                (block.timestamp <= _vector.endTimestamp || _vector.endTimestamp == 0),
            "Invalid mint time"
        );
        require(numTokensToMint > 0, "Have to mint something");
        require(numTokensToMint <= _vector.tokenLimitPerTx, "Too many per tx");

        if (_vector.currency == address(0) && _vector.pricePerToken > 0) {
            // pay in native gas token
            uint256 amount = numTokensToMint * _vector.pricePerToken;
            _processNativeGasTokenPayment(amount, _vector.paymentRecipient, bytes32(_vectorId));
        } else if (_vector.pricePerToken > 0) {
            // pay in ERC20
            uint256 amount = numTokensToMint * _vector.pricePerToken;
            _processERC20Payment(amount, _vector.paymentRecipient, _msgSender(), _vector.currency, bytes32(_vectorId));
        }
    }

    /**
     * @dev Mint on vector pointing to ERC721General collection
     * @param _vectorId ID of vector
     * @param _vector Vector being minted on
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     * @param newNumClaimedViaVector New number of NFTs minted via vector after this ones
     * @param newNumClaimedForUser New number of NFTs minted by user via vector after this ones
     */
    function _vectorMintGeneral721(
        uint256 _vectorId,
        Vector memory _vector,
        uint64 numTokensToMint,
        address mintRecipient,
        uint256 newNumClaimedViaVector,
        uint256 newNumClaimedForUser
    ) private {
        _processVectorMint(_vectorId, _vector, numTokensToMint, newNumClaimedViaVector, newNumClaimedForUser);
        if (numTokensToMint == 1) {
            IERC721GeneralMint(_vector.contractAddress).mintOneToOneRecipient(mintRecipient);
        } else {
            IERC721GeneralMint(_vector.contractAddress).mintAmountToOneRecipient(mintRecipient, numTokensToMint);
        }
    }

    /**
     * @dev Mint on vector pointing to ERC721Editions or ERC721SingleEdiion collection
     * @param _vectorId ID of vector
     * @param _vector Vector being minted on
     * @param editionId ID of edition being minted on
     * @param numTokensToMint Number of tokens to mint
     * @param mintRecipient Who to mint the NFT(s) to
     * @param newNumClaimedViaVector New number of NFTs minted via vector after this ones
     * @param newNumClaimedForUser New number of NFTs minted by user via vector after this ones
     */
    function _vectorMintEdition721(
        uint256 _vectorId,
        Vector memory _vector,
        uint256 editionId,
        uint64 numTokensToMint,
        address mintRecipient,
        uint256 newNumClaimedViaVector,
        uint256 newNumClaimedForUser
    ) private {
        _processVectorMint(_vectorId, _vector, numTokensToMint, newNumClaimedViaVector, newNumClaimedForUser);
        if (numTokensToMint == 1) {
            IERC721EditionMint(_vector.contractAddress).mintOneToRecipient(editionId, mintRecipient);
        } else {
            IERC721EditionMint(_vector.contractAddress).mintAmountToRecipient(
                editionId,
                mintRecipient,
                numTokensToMint
            );
        }
    }

    /**
     * @dev Process payment in native gas token, sending to creator and platform
     * @param totalAmount Total amount being paid
     * @param recipient Creator recipient of payment
     * @param vectorId ID of vector (on-chain or off-chain)
     */
    function _processNativeGasTokenPayment(
        uint256 totalAmount,
        address payable recipient,
        bytes32 vectorId
    ) private {
        require(totalAmount == msg.value, "Invalid amount");

        uint256 amountToCreator = (totalAmount * 95) / 100;
        (bool sentToRecipient, bytes memory dataRecipient) = recipient.call{ value: amountToCreator }("");
        require(sentToRecipient, "Failed to send Ether to recipient");

        emit NativeGasTokenPayment(recipient, vectorId, amountToCreator, 9500);
    }

    /**
     * @dev Process payment in ERC20, sending to creator and platform
     * @param totalAmount Total amount being paid
     * @param recipient Creator recipient of payment
     * @param payer Payer
     * @param currency ERC20 currency
     * @param vectorId ID of vector (on-chain or off-chain)
     */
    function _processERC20Payment(
        uint256 totalAmount,
        address recipient,
        address payer,
        address currency,
        bytes32 vectorId
    ) private {
        uint256 amountToCreator = (totalAmount * 95) / 100;

        IERC20(currency).transferFrom(payer, recipient, amountToCreator);
        IERC20(currency).transferFrom(payer, _platform, totalAmount - amountToCreator);

        emit ERC20Payment(currency, recipient, vectorId, payer, amountToCreator, 9500);
    }

    /**
     * @dev Process payment in ERC20 with meta-tx packets, sending to creator and platform
     * @param currency ERC20 currency
     * @param purchaseToCreatorPacket Meta-tx packet facilitating payment to creator recipient
     * @param purchaseToPlatformPacket Meta-tx packet facilitating payment to platform
     * @param msgSender Claimer
     * @param vectorId ID of vector (on-chain or off-chain)
     * @param amount Total amount paid
     */
    function _processERC20PaymentWithMetaTxPackets(
        address currency,
        PurchaserMetaTxPacket calldata purchaseToCreatorPacket,
        PurchaserMetaTxPacket calldata purchaseToPlatformPacket,
        address msgSender,
        bytes32 vectorId,
        uint256 amount
    ) private {
        uint256 previousBalance = IERC20(currency).balanceOf(msgSender);
        INativeMetaTransaction(currency).executeMetaTransaction(
            msgSender,
            purchaseToCreatorPacket.functionSignature,
            purchaseToCreatorPacket.sigR,
            purchaseToCreatorPacket.sigS,
            purchaseToCreatorPacket.sigV
        );

        INativeMetaTransaction(currency).executeMetaTransaction(
            msgSender,
            purchaseToPlatformPacket.functionSignature,
            purchaseToPlatformPacket.sigR,
            purchaseToPlatformPacket.sigS,
            purchaseToPlatformPacket.sigV
        );

        require(IERC20(currency).balanceOf(msgSender) <= previousBalance - amount, "Invalid amount transacted");

        emit ERC20PaymentMetaTxPackets(
            currency,
            msgSender,
            vectorId,
            purchaseToCreatorPacket,
            purchaseToPlatformPacket,
            amount
        );
    }

    /**
     * @dev Recover claim signature signer
     * @param claim Claim
     * @param signature Claim signature
     */
    function _claimSigner(Claim calldata claim, bytes calldata signature) private view returns (address) {
        return
            _hashTypedDataV4(
                keccak256(bytes.concat(_claimABIEncoded1(claim), _claimABIEncoded2(claim.offchainVectorId)))
            ).recover(signature);
    }

    /**
     * @dev Recover claimWithMetaTxPacket signature signer
     * @param claim Claim
     * @param signature Claim signature
     */
    function _claimWithMetaTxPacketSigner(ClaimWithMetaTxPacket calldata claim, bytes calldata signature)
        private
        view
        returns (address)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    bytes.concat(
                        _claimWithMetaTxABIEncoded1(claim),
                        _claimWithMetaTxABIEncoded2(claim.claimNonce, claim.offchainVectorId)
                    )
                )
            ).recover(signature);
    }

    /**
     * @dev Returns true if account passed in is a platform executor
     * @param _executor Account being checked
     */
    function _isPlatformExecutor(address _executor) private view returns (bool) {
        return _platformExecutors.contains(_executor);
    }

    /* solhint-disable max-line-length */
    /**
     * @dev Get claim typehash
     */
    function _getClaimTypeHash() private pure returns (bytes32) {
        return
            keccak256(
                "Claim(address currency,address contractAddress,address claimer,address paymentRecipient,uint256 pricePerToken,uint64 numTokensToMint,uint256 maxClaimableViaVector,uint256 maxClaimablePerUser,uint256 editionId,uint256 claimExpiryTimestamp,bytes32 claimNonce,bytes32 offchainVectorId)"
            );
    }

    /**
     * @dev Get claimWithMetaTxPacket typehash
     */
    function _getClaimWithMetaTxPacketTypeHash() private pure returns (bytes32) {
        return
            keccak256(
                "ClaimWithMetaTxPacket(address currency,address contractAddress,address claimer,uint256 pricePerToken,uint64 numTokensToMint,PurchaserMetaTxPacket purchaseToCreatorPacket,PurchaserMetaTxPacket purchaseToPlatformPacket,uint256 maxClaimableViaVector,uint256 maxClaimablePerUser,uint256 editionId,uint256 claimExpiryTimestamp,bytes32 claimNonce,bytes32 offchainVectorId)"
            );
    }

    /* solhint-enable max-line-length */

    /**
     * @dev Return abi-encoded claim part one
     * @param claim Claim
     */
    function _claimABIEncoded1(Claim calldata claim) private pure returns (bytes memory) {
        return
            abi.encode(
                _getClaimTypeHash(),
                claim.currency,
                claim.contractAddress,
                claim.claimer,
                claim.paymentRecipient,
                claim.pricePerToken,
                claim.numTokensToMint,
                claim.maxClaimableViaVector,
                claim.maxClaimablePerUser,
                claim.editionId,
                claim.claimExpiryTimestamp,
                claim.claimNonce
            );
    }

    /**
     * @dev Return abi-encoded claim part two
     * @param offchainVectorId Offchain vector ID of claim
     */
    function _claimABIEncoded2(bytes32 offchainVectorId) private pure returns (bytes memory) {
        return abi.encode(offchainVectorId);
    }

    /**
     * @dev Return abi-encoded claimWithMetaTxPacket part one
     * @param claim Claim
     */
    function _claimWithMetaTxABIEncoded1(ClaimWithMetaTxPacket calldata claim) private pure returns (bytes memory) {
        return
            abi.encode(
                _getClaimWithMetaTxPacketTypeHash(),
                claim.currency,
                claim.contractAddress,
                claim.claimer,
                claim.pricePerToken,
                claim.numTokensToMint,
                claim.purchaseToCreatorPacket,
                claim.purchaseToPlatformPacket,
                claim.maxClaimableViaVector,
                claim.maxClaimablePerUser,
                claim.editionId,
                claim.claimExpiryTimestamp
            );
    }

    /**
     * @dev Return abi-encoded claimWithMetaTxPacket part two
     * @param claimNonce Claim's unique identifier
     * @param offchainVectorId Offchain vector ID of claim
     */
    function _claimWithMetaTxABIEncoded2(bytes32 claimNonce, bytes32 offchainVectorId)
        private
        pure
        returns (bytes memory)
    {
        return abi.encode(claimNonce, offchainVectorId);
    }
}