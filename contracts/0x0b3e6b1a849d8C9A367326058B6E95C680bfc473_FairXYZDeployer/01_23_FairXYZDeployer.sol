// SPDX-License-Identifier: MIT

// @ Fair.xyz dev

pragma solidity 0.8.17;

import "./ERC721xyzUpgradeable.sol";
import "./IFairXYZWallets.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FairXYZDeployer is
    ERC721xyzUpgradeable,
    AccessControlUpgradeable,
    MulticallUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    struct TokensAvailableToMint {
        // Max number of tokens on sale across the whole collection
        uint128 maxTokens;
        // The creator can enforce a max mints per wallet at a global level, i.e. across all stages
        uint128 globalMintsPerWallet;
    }

    TokensAvailableToMint public tokensAvailable;

    // URI information
    string internal baseURI;
    string internal pathURI;
    string internal preRevealURI;
    string internal _overrideURI;
    bool public lockURI;

    // Bool to allow signature-less minting, in case the seller/creator wants to liberate themselves
    // from being bound to a signature generated on the Fair.xyz back-end
    bool public signatureReleased;

    // Interface into FairXYZWallets. This provides the wallet address to which the Fair.xyz fee is sent to
    address public interfaceAddress;

    // Burnable token bool
    bool public burnable;

    // Royalty information - this tells the contract where the proceeds from the primary sale should go to
    address internal _primarySaleReceiver;

    // Tightly pack the parameters that define a sale stage
    struct StageData {
        uint40 startTime;
        uint40 endTime;
        uint32 mintsPerWallet;
        uint32 phaseLimit;
        uint112 price;
        bytes32 merkleRoot;
    }

    // Mapping a stage ID to its corresponding StageData struct
    mapping(uint256 => StageData) internal stageMap;

    // Mapping to keep track of the number of mints a given wallet has done on a specific stage
    mapping(uint256 => mapping(address => uint256)) public stageMints;

    // Total number of sale stages
    uint256 public totalStages;

    // Pre-defined roles for AccessControl
    bytes32 public constant SECOND_ADMIN_ROLE = keccak256("T2A");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    // Fair.xyz address required for verifying signatures in the contract
    address internal constant FairxyzSignerAddress =
        0x7A6F5866f97034Bb7153829bdAaC1FFCb8Facb71;

    address constant DEFAULT_OPERATOR_FILTER_REGISTRY =
        0x000000000000AAeB6D7670E522A718067333cd4E;
    address constant DEFAULT_OPERATOR_FILTER_SUBSCRIPTION =
        0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

    // Events
    event Airdrop(uint256 tokenCount, uint256 newTotal, address[] recipients);
    event BurnableSet(bool burnState);
    event SignatureReleased();
    event NewMaxMintsPerWalletSet(uint128 newGlobalMintsPerWallet);
    event NewPathURI(string newPathURI);
    event NewPrimarySaleReceiver(address newPrimaryReceiver);
    event NewSecondaryRoyalties(
        address newSecondaryReceiver,
        uint96 newRoyalty
    );
    event NewStagesSet(StageData[] stages, uint256 startIndex);
    event NewTokenURI(string newTokenURI);
    event Mint(address minterAddress, uint256 stage, uint256 mintCount);
    event URILocked();

    // Errors
    error AlreadyLockedURI();
    error BurnerIsNotApproved();
    error BurningOff();
    error CannotDeleteOngoingStage();
    error CannotEditPastStages();
    error ETHSendFail();
    error EndTimeInThePast();
    error EndTimeLessThanStartTime();
    error ExceedsMintsPerWallet();
    error ExceedsNFTsOnSale();
    error IncorrectIndex();
    error InvalidNonce();
    error InvalidStartTime();
    error LessNFTsOnSaleThanBefore();
    error MerkleProofFail();
    error MerkleStage();
    error NotEnoughETH();
    error PhaseLimitEnd();
    error PhaseLimitExceedsTokenCount();
    error PhaseStartsBeforePriorPhaseEnd();
    error PublicStage();
    error ReusedHash();
    error SaleEnd();
    error SaleNotActive();
    error StageDoesNotExist();
    error StartTimeInThePast();
    error TimeLimit();
    error TokenCountExceedsPhaseLimit();
    error TokenDoesNotExist();
    error TokenLimitPerTx();
    error UnauthorisedUser();
    error UnrecognizableHash();
    error ZeroAddress();

    /**
     * @dev Returns the wallet of Fair.xyz to which primary sale fee will be
     */
    function viewWithdraw() public view returns (address) {
        address returnWithdraw = IFairXYZWallets(interfaceAddress)
            .viewWithdraw();
        return (returnWithdraw);
    }

    /**
     * @dev Intended to be called from the original implementation for the factory contract
     */
    function initialize() external initializer {
        __ERC721_init("", "");
        __AccessControl_init();
        __Multicall_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev Initialise a new Creator contract by setting variables and initialising
     * inherited contracts
     */
    function _initialize(
        uint128 maxTokens_,
        string memory name_,
        string memory symbol_,
        address interfaceAddress_,
        string[] memory URIs_,
        uint96 royaltyPercentage_,
        uint128 globalMintsPerWallet_,
        address[] memory royaltyReceivers,
        address ownerOfContract,
        StageData[] calldata stages
    ) external initializer {
        if (!(interfaceAddress_ != address(0))) revert ZeroAddress();
        require(URIs_.length == 3);
        require(royaltyReceivers.length == 2);
        __ERC721_init(name_, symbol_);
        __AccessControl_init();
        __Multicall_init();
        __ReentrancyGuard_init();
        __OperatorFilterer_init(
            DEFAULT_OPERATOR_FILTER_REGISTRY,
            DEFAULT_OPERATOR_FILTER_SUBSCRIPTION,
            true
        );
        _transferOwnership(ownerOfContract);
        tokensAvailable = TokensAvailableToMint(
            maxTokens_,
            globalMintsPerWallet_
        );
        interfaceAddress = interfaceAddress_;
        preRevealURI = URIs_[0];
        baseURI = URIs_[1];
        pathURI = URIs_[2];
        _primarySaleReceiver = royaltyReceivers[0];
        _setDefaultRoyalty(royaltyReceivers[1], royaltyPercentage_);
        _grantRole(DEFAULT_ADMIN_ROLE, ownerOfContract);
        _grantRole(SECOND_ADMIN_ROLE, ownerOfContract);
        if (stages.length > 0) {
            _setStages(stages, 0);
        }
    }

    /**
     * @dev Ensure number of minted tokens never goes above the total contract minting limit
     */
    modifier saleIsOpen() {
        if (!(_mintedTokens < tokensAvailable.maxTokens)) revert SaleEnd();
        _;
    }

    /**
     * @dev View sale parameters corresponding to a given stage
     */
    function viewStageMap(uint256 stageId)
        public
        view
        returns (StageData memory)
    {
        if (stageId >= totalStages) revert StageDoesNotExist();

        return stageMap[stageId];
    }

    /**
     * @dev View the current active sale stage for a sale based on being within the
     * time bounds for the start time and end time for the considered stage
     */
    function viewCurrentStage() public view returns (uint256) {
        for (uint256 i; i < totalStages; ) {
            if (
                block.timestamp >= stageMap[i].startTime &&
                block.timestamp <= stageMap[i].endTime
            ) {
                return i;
            }

            unchecked {
                ++i;
            }
        }

        revert SaleNotActive();
    }

    /**
     * @dev Returns the earliest stage which has not closed yet
     */
    function viewLatestStage() public view returns (uint256) {
        for (uint256 i; i < totalStages; ) {
            if (block.timestamp < stageMap[i].endTime) {
                return i;
            }
            unchecked {
                ++i;
            }
        }

        return totalStages;
    }

    /**
     * @dev See _setStages
     */
    function setStages(StageData[] calldata stages, uint256 startId) external {
        if (!hasRole(SECOND_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        _setStages(stages, startId);
    }

    /**
     * @dev Set the parameters for a list of sale stages, starting from startId onwards
     */
    function _setStages(StageData[] calldata stages, uint256 startId)
        internal
        returns (uint256)
    {
        uint256 currentTotalStages = totalStages;
        // Check that the stage the user is overriding from onwards is not a closed stage
        if (currentTotalStages > 0 && startId < viewLatestStage())
            revert CannotEditPastStages();

        // The startId cannot be an arbitrary number, it must follow a sequential order based on the current number of stages
        if (startId > currentTotalStages) revert IncorrectIndex();

        uint256 length = stages.length;

        uint256 startStageStartTime = stageMap[startId].startTime;

        // In order to delete a stage, calldata of length 0 must be provided. The stage referenced by the startIndex
        // and all stages after that will no longer be considered for the drop
        if (length == 0) {
            // The stage cannot have started at any point for it to be deleted
            if (startStageStartTime <= block.timestamp)
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
            startStageStartTime <= block.timestamp && startStageStartTime != 0
        ) {
            // If the start time of the stage being replaced is in the past and exists
            // the new stage start time must match it
            if (startStageStartTime != newStage.startTime)
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
            uint256 stageCount = startId + length;

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
                    // The number of total NFTs on sale cannot decrease from one stage to the next.
                    if (newStage.phaseLimit < stageMap[i - 1].phaseLimit)
                        revert LessNFTsOnSaleThanBefore();

                    // A sale can only start after the previous one has closed
                    if (newStage.startTime <= stageMap[i - 1].endTime)
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
     * @dev Hash the variables to be modified for URI changes.
     */
    function hashURIChange(
        address sender,
        string memory newPathURI,
        string memory newURI,
        address address_
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(sender, newPathURI, newURI, address_)
                )
            )
        );
        return hash;
    }

    /**
     * @dev Change values for the URIs. New Path URI implies a new reveal date being used.
     * newURI acts as an override for all priorly defined URIs). If lockURI() has been
     * executed, then this function will fail, as the data will have been locked forever.
     */
    function changeURI(
        bytes memory signature,
        string memory newPathURI,
        string memory newURI
    ) external {
        if (!hasRole(SECOND_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();

        // URI cannot be modified if it has been locked
        if (lockURI) revert AlreadyLockedURI();

        bytes32 messageHash = hashURIChange(
            msg.sender,
            newPathURI,
            newURI,
            address(this)
        );

        if (messageHash.recover(signature) != FairxyzSignerAddress)
            revert UnrecognizableHash();

        if (bytes(newPathURI).length != 0) {
            pathURI = newPathURI;
            emit NewPathURI(pathURI);
        }
        if (bytes(newURI).length != 0) {
            _overrideURI = newURI;
            baseURI = "";
            emit NewTokenURI(_overrideURI);
        }
    }

    /**
     * @dev Set global max mints per wallet
     */
    function setGlobalMaxMints(uint128 newGlobalMaxMintsPerWallet) external {
        if (!hasRole(SECOND_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        tokensAvailable.globalMintsPerWallet = newGlobalMaxMintsPerWallet;
        emit NewMaxMintsPerWalletSet(newGlobalMaxMintsPerWallet);
    }

    /**
     * @dev Toggle the burn state for NFTs in the contract
     */
    function toggleBurnable() external {
        if (!hasRole(SECOND_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        burnable = !burnable;
        emit BurnableSet(burnable);
    }

    /**
     * @dev Override primary royalty receiver
     */
    function changePrimarySaleReceiver(address newPrimarySaleReceiver)
        external
    {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        _primarySaleReceiver = newPrimarySaleReceiver;
        emit NewPrimarySaleReceiver(_primarySaleReceiver);
    }

    /**
     * @dev Override secondary royalty receivers
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
     * @dev Return the Base URI, used when there is no expected reveal experience
     */
    function _baseURI() public view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Return the path URI - used for reveal experience
     */
    function _pathURI() public view returns (string memory) {
        if (bytes(_overrideURI).length == 0) {
            return IFairXYZWallets(interfaceAddress).viewPathURI(pathURI);
        } else {
            return _overrideURI;
        }
    }

    /**
     * @dev Return the pre-reveal URI, which is used when there is a reveal experience
     * and the reveal metadata has not been set yet.
     */
    function _preRevealURI() public view returns (string memory) {
        return preRevealURI;
    }

    /**
     * @dev Combines path URI, base URI and pre-reveal URI for the full metadata journey on Fair.xyz
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if(!_exists(tokenId)) revert TokenDoesNotExist();

        string memory pathURI_ = _pathURI();
        string memory baseURI_ = _baseURI();
        string memory preRevealURI_ = _preRevealURI();

        if (bytes(pathURI_).length == 0) {
            return preRevealURI_;
        } else {
            return
                string(
                    abi.encodePacked(pathURI_, baseURI_, tokenId.toString())
                );
        }
    }

    /**
     * @dev See the total mints across all stages for a wallet
     */
    function totalWalletMints(address minterAddress)
        external
        view
        returns (uint256)
    {
        return mintData[minterAddress].mintsPerWallet;
    }

    /**
     * @dev Burn a token. This requires being an owner of the NFT. The expected behaviour for a
     * burn mechanism is that the user transfers their NFT to a redemption contract which in turn
     * calls this function
     */
    function burn(uint256 tokenId) external returns (uint256) {
        if (!burnable) revert BurningOff();
        if (!(isApprovedForAll(ownerOf(tokenId), msg.sender) || msg.sender == ownerOf(tokenId) || getApproved(tokenId) == msg.sender)) revert BurnerIsNotApproved();
        _burn(tokenId);
        return tokenId;
    }

    /**
     * @dev Airdrop tokens to a list of addresses
     */
    function airdrop(address[] memory address_, uint256 tokenCount)
        external
        returns (uint256)
    {
        if (tokenCount == 0) revert TokenLimitPerTx();

        if (
            !hasRole(SECOND_ADMIN_ROLE, msg.sender) &&
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

    /**
     * @dev Hash transaction data for minting
     */
    function hashTransaction(
        address sender,
        uint256 qty,
        uint256 nonce,
        uint256 maxMintsPerWallet,
        address address_
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        sender,
                        qty,
                        nonce,
                        maxMintsPerWallet,
                        address_
                    )
                )
            )
        );
        return hash;
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
     * @dev Mint token(s) for public sales
     */
    function mint(
        bytes memory signature,
        uint256 nonce,
        uint256 numberOfTokens,
        uint256 maxMintsPerWallet,
        address recipient
    ) external payable {
        // Check the active stage - reverts if no stage is active
        uint256 presentStage = viewCurrentStage();

        // Load the minting parameters for this stage
        StageData memory dropData = stageMap[presentStage];

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
            bytes32 messageHash = hashTransaction(
                recipient,
                numberOfTokens,
                nonce,
                maxMintsPerWallet,
                address(this)
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

        // Check that enough ETH is sent for the minting quantity
        if (msg.value < dropData.price * numberOfTokens) revert NotEnoughETH();

        // At least 1 and no more than 20 tokens can be minted per transaction
        if (!((0 < numberOfTokens) && (numberOfTokens <= 20)))
            revert TokenLimitPerTx();

        // Load the total number of NFTs the user has minted across all stages
        uint256 mintsPerWallet = uint256(mintData[recipient].mintsPerWallet);

        // Load the number of NFTs the user has minted solely on the active stage
        uint256 stageMintsPerWallet = stageMints[presentStage][recipient];

        // Keep track of the user's original intent of tokens they want to mint, to be used for ETH reimbursement
        // later if necessary
        uint256 origMintCount = numberOfTokens;

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
        }

        // Mint the NFTs
        _safeMint(recipient, numberOfTokens, nonce);

        // If the value for numberOfTokens is less than the origMintCount, then there is reimbursement
        // to be done
        if (numberOfTokens < origMintCount) {
            uint256 reimbursementPrice = (origMintCount - numberOfTokens) *
                dropData.price;
            (bool sent, ) = msg.sender.call{value: reimbursementPrice}("");
            if (!sent) revert ETHSendFail();
        }

        emit Mint(recipient, presentStage, numberOfTokens);
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
    ) external payable saleIsOpen {
        // Check the active stage - reverts if no stage is active
        uint256 presentStage = viewCurrentStage();

        // Load the minting parameters for this stage
        StageData memory dropData = stageMap[presentStage];

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

        // Check that enough ETH is sent for the minting quantity
        if (msg.value < dropData.price * numberOfTokens) revert NotEnoughETH();

        // At least 1 and no more than 20 tokens can be minted per transaction
        if (!((0 < numberOfTokens) && (numberOfTokens <= 20)))
            revert TokenLimitPerTx();

        // Load the total number of NFTs the user has minted across all stages
        uint256 mintsPerWallet = uint256(mintData[recipient].mintsPerWallet);

        // Load the number of NFTs the user has minted solely on the active stage
        uint256 stageMintsPerWallet = stageMints[presentStage][recipient];

        // Keep track of the user's original intent of tokens they want to mint, to be used for ETH reimbursement
        // later if necessary
        uint256 origMintCount = numberOfTokens;

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

            // A value of 0 means there is no limit as to how many mints a wallet has been allowlisted for
            if (maxMintsPerWallet > 0) {
                // Check that the user has not reached the minting limit per wallet they have been allowlisted for
                if (stageMintsPerWallet >= maxMintsPerWallet)
                    revert ExceedsMintsPerWallet();

                // Cap the number of tokens the user can mint so that it does not exceed the limit
                // of mints the wallet has been allowlisted for
                if (stageMintsPerWallet + numberOfTokens > maxMintsPerWallet) {
                    numberOfTokens = maxMintsPerWallet - stageMintsPerWallet;
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

            // Update the total number mints the recipient has done for this stage
            stageMintsPerWallet += numberOfTokens;
            stageMints[presentStage][recipient] = stageMintsPerWallet;
        }

        // Mint NFTs
        _safeMint(recipient, numberOfTokens, block.number);

        // If the value for numberOfTokens is less than the origMintCount, then there is reimbursement
        // to be done
        if (numberOfTokens < origMintCount) {
            uint256 reimbursementPrice = (origMintCount - numberOfTokens) *
                dropData.price;
            (bool sent, ) = msg.sender.call{value: reimbursementPrice}("");
            if (!sent) revert ETHSendFail();
        }

        emit Mint(recipient, presentStage, numberOfTokens);
    }

    /**
     * @dev Only owner or Fair.xyz - withdraw contract balance to owner wallet. 6% primary sale fee to Fair.xyz
     */
    function withdraw() external payable nonReentrant {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                msg.sender == viewWithdraw(),
            "Not owner or Fair.xyz!"
        );
        uint256 contractBalance = address(this).balance;

        (bool sent, ) = viewWithdraw().call{value: (contractBalance * 3) / 50}(
            ""
        );
        if (!sent) revert ETHSendFail();

        uint256 remainingContractBalance = address(this).balance;
        (bool sent_, ) = _primarySaleReceiver.call{
            value: remainingContractBalance
        }("");
        if (!sent_) revert ETHSendFail();
    }

    function supportsInterface(bytes4 interfaceId)
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
    function _isOperatorFilterAdmin(address operator)
        internal
        view
        override
        returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, operator);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}