// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.17;

import "./ERC721xyzUpgradeable.sol";
import "../../interfaces/IFairXYZDeployer.sol";
import "../../interfaces/IFairXYZWallets.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

contract FairFellaz is
    ERC721xyzUpgradeable,
    AccessControlUpgradeable,
    MulticallUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    IFairXYZDeployer
{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    struct TokensAvailableToMint {
        /// @dev Max number of tokens on sale across the whole collection
        uint128 maxTokens;
        /// @dev The creator can enforce a max mints per wallet at a global level, i.e. across all stages
        uint128 globalMintsPerWallet;
    }

    TokensAvailableToMint public tokensAvailable;

    /// @dev URI information
    string internal baseURI;
    string internal pathURI;
    string internal preRevealURI;
    string internal _overrideURI;
    bool public lockURI;

    /// @dev Bool to allow signature-less minting, in case the seller/creator wants to liberate themselves
    // from being bound to a signature generated on the Fair.xyz back-end
    bool public signatureReleased;

    /// @dev Interface into FairXYZWallets. This provides the wallet address to which the Fair.xyz fee is sent to
    address public interfaceAddress;

    /// @dev Burnable token bool
    bool public burnable;

    /// @dev Sale information - this tells the contract where the proceeds from the primary sale should go to
    address internal _primarySaleReceiver;

    /// @dev Tightly pack the parameters that define a sale stage
    struct StageData {
        uint40 startTime;
        uint40 endTime;
        uint32 mintsPerWallet;
        uint32 phaseLimit;
        uint112 price;
        bytes32 merkleRoot;
    }

    /// @dev Mapping a stage ID to its corresponding StageData struct
    mapping(uint256 => StageData) internal stageMap;

    /// @dev Mapping to keep track of the number of mints a given wallet has done on a specific stage
    mapping(uint256 => mapping(address => uint256)) public stageMints;

    /// @dev Total number of sale stages
    uint256 public totalStages;

    /// @dev mapping from tokenId to metadata variant selected
    mapping(uint256 => uint256) private _tokenVariantSelected;

    /// @dev number of variants supported by metadata and selectable by token owners
    uint256 public numberOfVariants;

    /// @dev OpenSea supported contract metadata
    string public contractURI;

    /// @dev Pre-defined roles for AccessControl
    bytes32 public constant SECOND_ADMIN_ROLE = keccak256("T2A");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    uint256 internal constant stageLengthLimit = 20;

    uint256 constant FairxyzMintFee = 0.00087 ether;

    /// @dev Fair.xyz fee recipient address
    address internal constant FairxyzReceiverAddress =
        0xC5A2f45fF2d4CA27e167600b5225C7E6E187d8C0;

    /// @dev Fair.xyz address required for verifying signatures in the contract
    address internal constant FairxyzSignerAddress =
        0x7A6F5866f97034Bb7153829bdAaC1FFCb8Facb71;

    address constant DEFAULT_OPERATOR_FILTER_REGISTRY =
        0x000000000000AAeB6D7670E522A718067333cd4E;
    address constant DEFAULT_OPERATOR_FILTER_SUBSCRIPTION =
        0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

    /// @dev EIP-712 signatures
    bytes32 constant EIP712_NAME_HASH = keccak256("Fair.xyz");
    bytes32 constant EIP712_VERSION_HASH = keccak256("1.0.0");
    bytes32 constant EIP712_DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 constant EIP712_MINT_TYPE_HASH =
        keccak256(
            "Mint(address recipient,uint256 quantity,uint256 nonce,uint256 maxMintsPerWallet)"
        );

    event NewStagesSet(StageData[] stages, uint256 startIndex);

    /*///////////////////////////////////////////////////////////////
                            Initialisation
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialise a new Creator contract by setting variables and initialising
     * inherited contracts
     */
    function _initialize(
        string memory name_,
        string memory symbol_,
        string memory prerevealURI_,
        string memory contractURI_,
        uint256 numberOfVariants_,
        address ownerOfContract,
        uint96 royaltyPercentage_,
        uint128 maxTokens_,
        uint128 globalMintsPerWallet_,
        StageData[] calldata stages
    ) external initializer {
        __ERC721_init(name_, symbol_);
        __AccessControl_init();
        __Multicall_init();

        __OperatorFilterer_init(
            DEFAULT_OPERATOR_FILTER_REGISTRY,
            DEFAULT_OPERATOR_FILTER_SUBSCRIPTION,
            true
        );

        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _transferOwnership(ownerOfContract);

        _primarySaleReceiver = ownerOfContract;
        _setDefaultRoyalty(ownerOfContract, royaltyPercentage_);

        tokensAvailable = TokensAvailableToMint(
            maxTokens_,
            globalMintsPerWallet_
        );

        contractURI = contractURI_;
        preRevealURI = prerevealURI_;
        numberOfVariants = numberOfVariants_;

        if (stages.length > 0) {
            _setStages(stages, 0);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Sale stages logic
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev View sale parameters corresponding to a given stage
     */
    function viewStageMap(
        uint256 stageId
    ) external view returns (StageData memory) {
        if (stageId >= totalStages) revert StageDoesNotExist();

        return stageMap[stageId];
    }

    /**
     * @dev View the current active sale stage for a sale based on being within the
     * time bounds for the start time and end time for the considered stage
     */
    function viewCurrentStage() public view returns (uint256) {
        for (uint256 i = totalStages; i > 0; ) {
            unchecked {
                --i;
            }

            if (
                block.timestamp >= stageMap[i].startTime &&
                block.timestamp <= stageMap[i].endTime
            ) {
                return i;
            }
        }

        revert SaleNotActive();
    }

    /**
     * @dev Get the price for the current active sale stage
     * reverts if there is no current active stage
     */
    function viewCurrentPrice() public view returns (uint256) {
        return stageMap[viewCurrentStage()].price + FairxyzMintFee;
    }

    /**
     * @dev Returns the earliest stage which has not closed yet
     */
    function viewLatestStage() public view returns (uint256) {
        for (uint256 i = totalStages; i > 0; ) {
            unchecked {
                --i;
            }

            if (block.timestamp > stageMap[i].endTime) {
                return i + 1;
            }
        }

        return 0;
    }

    /**
     * @dev See _setStages
     */
    function setStages(StageData[] calldata stages, uint256 startId) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        _setStages(stages, startId);
    }

    /**
     * @dev Set the parameters for a list of sale stages, starting from startId onwards
     */
    function _setStages(
        StageData[] calldata stages,
        uint256 startId
    ) internal returns (uint256) {
        uint256 stagesLength = stages.length;

        uint256 latestStage = viewLatestStage();

        // Cannot set more than the stage length limit stages per transaction
        if (stagesLength > stageLengthLimit) revert StageLimitPerTx();

        uint256 currentTotalStages = totalStages;

        // Check that the stage the user is overriding from onwards is not a closed stage
        if (currentTotalStages > 0 && startId < latestStage)
            revert CannotEditPastStages();

        // The startId cannot be an arbitrary number, it must follow a sequential order based on the current number of stages
        if (startId > currentTotalStages) revert IncorrectIndex();

        // There can be no more than 20 sale stages (stageLengthLimit) between the most recent active stage and the last possible stage
        if (startId + stagesLength > latestStage + stageLengthLimit)
            revert TooManyStagesInTheFuture();

        uint256 initialStageStartTime = stageMap[startId].startTime;

        // In order to delete a stage, calldata of length 0 must be provided. The stage referenced by the startIndex
        // and all stages after that will no longer be considered for the drop
        if (stagesLength == 0) {
            // The stage cannot have started at any point for it to be deleted
            if (initialStageStartTime <= block.timestamp)
                revert CannotDeleteOngoingStage();

            // The new length of total stages is startId, as everything from there onwards is now disregarded
            totalStages = startId;
            emit NewStagesSet(stages, startId);
            return startId;
        }

        StageData memory newStage = stages[0];

        if (newStage.phaseLimit < _mintedTokens)
            revert TokenCountExceedsPhaseLimit();

        if (
            initialStageStartTime <= block.timestamp &&
            initialStageStartTime != 0 &&
            startId < totalStages
        ) {
            // If the start time of the stage being replaced is in the past and exists
            // the new stage start time must match it
            if (initialStageStartTime != newStage.startTime)
                revert InvalidStartTime();

            // The end time for a stage cannot be in the past
            if (newStage.endTime <= block.timestamp) revert EndTimeInThePast();
        } else {
            // the start time of the stage being replaced is in the future or doesn't exist
            // the new stage start time can't be in the past
            if (newStage.startTime <= block.timestamp)
                revert StartTimeInThePast();
        }

        unchecked {
            uint256 i = startId;
            uint256 stageCount = startId + stagesLength;

            do {
                if (i != startId) {
                    newStage = stages[i - startId];
                }

                // The number of tokens the user can mint up to in a stage cannot exceed the total supply available
                if (newStage.phaseLimit > tokensAvailable.maxTokens)
                    revert PhaseLimitExceedsTokenCount();

                // The end time cannot be less than the start time for a sale
                if (newStage.endTime <= newStage.startTime)
                    revert EndTimeLessThanStartTime();

                if (i > 0) {
                    uint256 previousStageEndTime = stageMap[i - 1].endTime;
                    // The number of total NFTs on sale cannot decrease below the total for a stage which has not ended
                    if (newStage.phaseLimit < stageMap[i - 1].phaseLimit) {
                        if (previousStageEndTime >= block.timestamp)
                            revert LessNFTsOnSaleThanBefore();
                    }

                    // A sale can only start after the previous one has closed
                    if (newStage.startTime <= previousStageEndTime)
                        revert PhaseStartsBeforePriorPhaseEnd();
                }

                // Update the variables in a given stage's stageMap with the correct indexing within the stages function input
                stageMap[i] = newStage;

                ++i;
            } while (i < stageCount);

            // The total number of stages is updated to be the startId + the length of stages added from there onwards
            totalStages = stageCount;

            emit NewStagesSet(stages, startId);
            return stageCount;
        }
    }

    /*///////////////////////////////////////////////////////////////
                    Sale proceeds & royalties
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Override primary sale receiver
     */
    function changePrimarySaleReceiver(
        address newPrimarySaleReceiver
    ) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        if (newPrimarySaleReceiver == address(0)) revert ZeroAddress();
        _primarySaleReceiver = newPrimarySaleReceiver;
        emit NewPrimarySaleReceiver(_primarySaleReceiver);
    }

    /**
     * @dev Override secondary royalty receiver and royalty percentage fee
     */
    function changeSecondaryRoyaltyReceiver(
        address newSecondaryRoyaltyReceiver,
        uint96 newRoyaltyValue
    ) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        _setDefaultRoyalty(newSecondaryRoyaltyReceiver, newRoyaltyValue);
        emit NewSecondaryRoyalties(
            newSecondaryRoyaltyReceiver,
            newRoyaltyValue
        );
    }

    /**
     * @dev Transfers the contract balance to the primary sale receiver
     */
    function withdraw() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool sent_, ) = _primarySaleReceiver.call{
            value: address(this).balance
        }("");
        if (!sent_) revert ETHSendFail();
    }

    /*///////////////////////////////////////////////////////////////
                            Token metadata
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Return the Base URI, used when there is no expected reveal experience
     */
    function _baseURI() public view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Return the pre-reveal URI, which is used when there is a reveal experience
     * and the reveal metadata has not been set yet.
     */
    function _preRevealURI() public view returns (string memory) {
        return preRevealURI;
    }

    function _tokenVariant(uint256 tokenId) internal view returns (uint256) {
        if (_tokenVariantSelected[tokenId] == 0)
            return (tokenId % numberOfVariants) + 1;
        return _tokenVariantSelected[tokenId];
    }

    function selectVariant(uint256 tokenId, uint256 variant) public {
        if (ownerOf(tokenId) != msg.sender) revert UnauthorisedUser();
        if (variant == 0 || variant > numberOfVariants) revert InvalidVariant();
        if (variant == _tokenVariantSelected[tokenId])
            revert VariantAlreadySelected();
        _tokenVariantSelected[tokenId] = variant;
    }

    /**
     * @dev Combines the baseURI and tokenId (and possibly variant) to return the location of the token metadata
     * returns prerevealURI if no baseURI is set.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        string memory baseURI_ = _baseURI();

        if (bytes(baseURI_).length == 0) {
            return _preRevealURI();
        } else if (numberOfVariants > 1) {
            return
                string(
                    abi.encodePacked(
                        baseURI_,
                        tokenId.toString(),
                        "-",
                        _tokenVariant(tokenId).toString(),
                        ".json"
                    )
                );
        } else {
            return
                string(abi.encodePacked(baseURI_, tokenId.toString(), ".json"));
        }
    }

    /**
     * @dev Lock the token metadata forever. This action is non reversible.
     */
    function lockURIforever() external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        if (lockURI) revert AlreadyLockedURI();
        lockURI = true;
        emit URILocked();
    }

    /**
     * @dev Change value of the baseURI and number of metadata variants per token.
     * If lockURI() has been executed, then this function will fail, as the data will have been locked forever.
     */
    function changeURI(
        string memory newURI,
        uint256 numberOfVariants_
    ) external onlyOwner {
        // URI cannot be modified if it has been locked
        if (lockURI) revert AlreadyLockedURI();
        if (numberOfVariants_ == 0) revert InvalidNumberOfVariants();

        baseURI = newURI;
        numberOfVariants = numberOfVariants_;
        emit NewTokenURI(newURI);
    }

    /*///////////////////////////////////////////////////////////////
                            Burning
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Toggle the burn state for NFTs in the contract
     */
    function toggleBurnable() external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        burnable = !burnable;
        emit BurnableSet(burnable);
    }

    /**
     * @dev Burn a token. Requires being an approved operator or the owner of an NFT
     */
    function burn(uint256 tokenId) external returns (uint256) {
        if (!burnable) revert BurningOff();
        if (
            !(isApprovedForAll(ownerOf(tokenId), msg.sender) ||
                msg.sender == ownerOf(tokenId) ||
                getApproved(tokenId) == msg.sender)
        ) revert BurnerIsNotApproved();
        _burn(tokenId);
        return tokenId;
    }

    /*///////////////////////////////////////////////////////////////
                        Minting + airdrop logic
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Set global max mints per wallet
     */
    function setGlobalMaxMints(uint128 newGlobalMaxMintsPerWallet) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        tokensAvailable.globalMintsPerWallet = newGlobalMaxMintsPerWallet;
        emit NewMaxMintsPerWalletSet(newGlobalMaxMintsPerWallet);
    }

    /**
     * @dev Allow for signature-less minting on public sales
     */
    function releaseSignature() external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        require(!signatureReleased);
        signatureReleased = true;
        emit SignatureReleased();
    }

    /**
     * @dev Hash transaction data for minting
     */
    function hashMintParams(
        address recipient,
        uint256 quantity,
        uint256 nonce,
        uint256 maxMintsPerWallet
    ) private view returns (bytes32) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    EIP712_MINT_TYPE_HASH,
                    recipient,
                    quantity,
                    nonce,
                    maxMintsPerWallet
                )
            )
        );
        return digest;
    }

    /**
     * @dev Handle excess NFTs being minted in a transaction based on the different stage and sale limits
     */
    function handleReimbursement(
        address recipient,
        uint256 presentStage,
        uint256 numberOfTokens,
        uint256 currentMintedTokens,
        StageData memory dropData,
        uint256 maxMintsPerWallet
    ) internal returns (uint256) {
        // Load the total number of NFTs the user has minted across all stages
        uint256 mintsPerWallet = uint256(mintData[recipient].mintsPerWallet);

        // Load the number of NFTs the user has minted solely on the active stage
        uint256 stageMintsPerWallet = stageMints[presentStage][recipient];

        unchecked {
            // A value of 0 means there is no limit as to how many mints a wallet can do in this stage
            if (dropData.mintsPerWallet > 0) {
                // Check that the user has not reached the minting limit per wallet for this stage
                if (stageMintsPerWallet >= dropData.mintsPerWallet)
                    revert ExceedsMintsPerWallet();

                // Cap the number of tokens the user can mint so that it does not exceed the limit
                // per wallet for this stage
                if (
                    stageMintsPerWallet + numberOfTokens >
                    dropData.mintsPerWallet
                ) {
                    numberOfTokens =
                        dropData.mintsPerWallet -
                        stageMintsPerWallet;
                }
            }

            uint256 _globalMintsPerWallet = tokensAvailable
                .globalMintsPerWallet;

            // A value of 0 means there is no limit as to how many mints a wallet can do across all stages
            if (_globalMintsPerWallet > 0) {
                // Check that the user has not reached the minting limit per wallet across the whole contract
                if (mintsPerWallet >= _globalMintsPerWallet)
                    revert ExceedsMintsPerWallet();

                // Cap the number of tokens the user can mint so that it does not exceed the minting limit
                // per wallet across the whole contract
                if (mintsPerWallet + numberOfTokens > _globalMintsPerWallet) {
                    numberOfTokens = _globalMintsPerWallet - mintsPerWallet;
                }
            }

            // Cap the number of tokens the user can mint so that it does not exceed the minting limit
            // of tokens on sale for this stage
            if (currentMintedTokens + numberOfTokens > dropData.phaseLimit) {
                numberOfTokens = dropData.phaseLimit - currentMintedTokens;
            }

            // A value of 0 means there is no limit as to how many mints a wallet has been authorised to mint.
            // This form of mint authorisation is managed through pre-generated signatures - if the contract has
            // been released from signature minting then this check is omitted
            if (maxMintsPerWallet > 0 && !signatureReleased) {
                // Check that the user has not reached the minting limit per wallet they have been allowlisted for
                if (stageMintsPerWallet >= maxMintsPerWallet)
                    revert ExceedsMintsPerWallet();

                // Cap the number of tokens the user can mint so that it does not exceed the limit
                // of mints the wallet has been allowlisted for
                if (stageMintsPerWallet + numberOfTokens > maxMintsPerWallet) {
                    numberOfTokens = maxMintsPerWallet - stageMintsPerWallet;
                }
            }

            // Update the total number mints the recipient has done for this stage
            stageMintsPerWallet += numberOfTokens;
            stageMints[presentStage][recipient] = stageMintsPerWallet;

            return (numberOfTokens);
        }
    }

    /**
     * @dev Mint token(s) for public sales
     */
    function mint(
        bytes memory signature,
        uint256 nonce,
        uint256 numberOfTokens,
        uint256 maxMintsPerWallet,
        address recipient
    ) external payable {
        // At least 1 and no more than 20 tokens can be minted per transaction
        if (!((0 < numberOfTokens) && (numberOfTokens <= 20)))
            revert TokenLimitPerTx();

        // Check the active stage - reverts if no stage is active
        uint256 presentStage = viewCurrentStage();

        // Load the minting parameters for this stage
        StageData memory dropData = stageMap[presentStage];

        // Check that enough ETH is sent for the minting quantity
        uint256 costPerToken = dropData.price + FairxyzMintFee;
        if (msg.value != costPerToken * numberOfTokens) revert NotEnoughETH();

        // Nonce = 0 is reserved for airdrop mints, to distinguish them from other mints in the
        // _mint function on ERC721xyzUpgradeable
        if (nonce == 0) revert InvalidNonce();

        uint256 currentMintedTokens = _mintedTokens;

        // The number of minted tokens cannot exceed the number of NFTs on sale for this stage
        if (currentMintedTokens >= dropData.phaseLimit) revert PhaseLimitEnd();

        // If a Merkle Root is defined for the stage, then this is an allowlist stage. Thus the function merkleMint
        // must be used instead
        if (dropData.merkleRoot != bytes32(0)) revert MerkleStage();

        // If the contract is released from signature minting, skips this signature verification
        if (!signatureReleased) {
            // Hash the variables
            bytes32 messageHash = hashMintParams(
                recipient,
                numberOfTokens,
                nonce,
                maxMintsPerWallet
            );

            // Ensure the recovered address from the signature is the Fair.xyz signer address
            if (messageHash.recover(signature) != FairxyzSignerAddress)
                revert UnrecognizableHash();

            // mintData[recipient].blockNumber is the last block (nonce) that was used to mint from the given address.
            // Nonces can only increase in number in each transaction, and are part of the signature. This ensures
            // that past signatures are not reused
            if (mintData[recipient].blockNumber >= nonce) revert ReusedHash();

            // Set a time limit of 40 blocks for the signature
            if (block.number > nonce + 40) revert TimeLimit();
        }

        uint256 adjustedNumberOfTokens = handleReimbursement(
            recipient,
            presentStage,
            numberOfTokens,
            currentMintedTokens,
            dropData,
            maxMintsPerWallet
        );

        // Mint the NFTs
        _safeMint(recipient, adjustedNumberOfTokens, nonce);

        (bool feeSent, ) = FairxyzReceiverAddress.call{
            value: (FairxyzMintFee * adjustedNumberOfTokens)
        }("");
        if (!feeSent) revert ETHSendFail();

        // If the value for numberOfTokens is less than the origMintCount, then there is reimbursement
        // to be done
        if (adjustedNumberOfTokens < numberOfTokens) {
            uint256 reimbursementPrice = (numberOfTokens -
                adjustedNumberOfTokens) * costPerToken;
            (bool sent, ) = msg.sender.call{value: reimbursementPrice}("");
            if (!sent) revert ETHSendFail();
        }

        emit Mint(recipient, presentStage, adjustedNumberOfTokens);
    }

    /**
     * @notice Verify merkle proof for address and address minting limit
     */
    function verifyMerkleAddress(
        bytes32[] calldata merkleProof,
        bytes32 _merkleRoot,
        address minterAddress,
        uint256 walletLimit
    ) private pure returns (bool) {
        return
            MerkleProofUpgradeable.verify(
                merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(minterAddress, walletLimit))
            );
    }

    /**
     * @dev Mint token(s) for allowlist sales
     */
    function merkleMint(
        bytes32[] calldata _merkleProof,
        uint256 numberOfTokens,
        uint256 maxMintsPerWallet,
        address recipient
    ) external payable {
        // At least 1 and no more than 20 tokens can be minted per transaction
        if (!((0 < numberOfTokens) && (numberOfTokens <= 20)))
            revert TokenLimitPerTx();

        // Check the active stage - reverts if no stage is active
        uint256 presentStage = viewCurrentStage();

        // Load the minting parameters for this stage
        StageData memory dropData = stageMap[presentStage];

        // Check that enough ETH is sent for the minting quantity
        uint256 costPerToken = dropData.price + FairxyzMintFee;
        if (msg.value != costPerToken * numberOfTokens) revert NotEnoughETH();

        // If a Merkle Root is not defined for the stage, then this is an public sale stage. Thus the function mint()
        // must be used instead
        if (dropData.merkleRoot == bytes32(0)) revert PublicStage();

        uint256 currentMintedTokens = _mintedTokens;

        // The number of minted tokens cannot exceed the number of NFTs on sale for this stage
        if (currentMintedTokens >= dropData.phaseLimit) revert PhaseLimitEnd();

        // Verify the Merkle Proof for the recipient address and the maximum number of mints the wallet has been assigned
        // on the allowlist
        if (
            !(
                verifyMerkleAddress(
                    _merkleProof,
                    dropData.merkleRoot,
                    recipient,
                    maxMintsPerWallet
                )
            )
        ) revert MerkleProofFail();

        uint256 adjustedNumberOfTokens = handleReimbursement(
            recipient,
            presentStage,
            numberOfTokens,
            currentMintedTokens,
            dropData,
            maxMintsPerWallet
        );

        // Mint NFTs
        _safeMint(recipient, adjustedNumberOfTokens, block.number);
        (bool feeSent, ) = FairxyzReceiverAddress.call{
            value: (FairxyzMintFee * adjustedNumberOfTokens)
        }("");
        if (!feeSent) revert ETHSendFail();

        // If the value for numberOfTokens is less than the origMintCount, then there is reimbursement
        // to be done
        if (adjustedNumberOfTokens < numberOfTokens) {
            uint256 reimbursementPrice = (numberOfTokens -
                adjustedNumberOfTokens) * costPerToken;
            (bool sent, ) = msg.sender.call{value: reimbursementPrice}("");
            if (!sent) revert ETHSendFail();
        }

        emit Mint(recipient, presentStage, adjustedNumberOfTokens);
    }

    /**
     * @dev See the total mints across all stages for a wallet
     */
    function totalWalletMints(
        address minterAddress
    ) external view returns (uint256) {
        return mintData[minterAddress].mintsPerWallet;
    }

    /**
     * @dev Airdrop tokens to a list of addresses
     */
    function airdrop(
        address[] memory address_,
        uint256 tokenCount
    ) external returns (uint256) {
        if (tokenCount > 20) revert TokenLimitPerTx();

        if (tokenCount == 0) revert TokenLimitPerTx();

        if (address_.length > 20) revert AddressLimitPerTx();

        if (address_.length == 0) revert AddressLimitPerTx();

        if (
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) &&
            !hasRole(MINTER_ROLE, msg.sender)
        ) revert UnauthorisedUser();

        uint256 newTotal = _mintedTokens + address_.length * tokenCount;
        unchecked {
            if (newTotal > tokensAvailable.maxTokens)
                revert ExceedsNFTsOnSale();

            for (uint256 i; i < address_.length; ) {
                _safeMint(address_[i], tokenCount, 0);
                ++i;
            }

            emit Airdrop(tokenCount, newTotal, address_);
            return newTotal;
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellanous
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721xyzUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev overrides {UpdatableOperatorFilterUpgradeable} function to determine the role of operator filter admin
     */
    function _isOperatorFilterAdmin(
        address operator
    ) internal view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, operator);
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     */
    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPE_HASH,
                EIP712_NAME_HASH,
                EIP712_VERSION_HASH,
                block.chainid,
                address(this)
            )
        );

        return ECDSAUpgradeable.toTypedDataHash(domainSeparator, structHash);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}