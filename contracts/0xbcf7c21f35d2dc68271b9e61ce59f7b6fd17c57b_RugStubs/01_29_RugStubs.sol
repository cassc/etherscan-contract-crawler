// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.17;

import "AccessControlUpgradeable.sol";
import "OwnableUpgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";
import "ECDSAUpgradeable.sol";
import "MerkleProofUpgradeable.sol";
import "UUPSUpgradeable.sol";
import "ERC1155xyzUpgradeable.sol";
import "RugStubsErrorsAndEvents.sol";
import "IFairXYZWallets.sol";

contract RugStubs is
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC1155xyzUpgradeable,
    RugStubsErrorsAndEvents
{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    string public name;
    string public symbol;

    /// @dev Bool to allow signature-less minting, in case the seller/creator wants to liberate themselves
    // from being bound to a signature generated on the Fair.xyz back-end
    bool public signatureReleased;

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

    /// @dev Tightly pack all token information for burn to redeem
    struct TokenData {
        uint40 saleStartTime;
        uint40 saleEndTime;
        uint32 supplyAvailable;
        uint32 mintsPerWallet;
        uint112 price;
        uint256 burnPerToken;
        address currency;
        string URI;
    }

    /// @dev Mapping a token ID to its corresponding TokenData struct
    mapping(uint256 => TokenData) internal tokenMap;

    /// @dev Mapping to keep track of the number of mints a given wallet has done on a specific stage
    mapping(uint256 => mapping(address => uint256)) public stageMints;

    /// @dev Total number of sale stages
    uint256 public totalStages;

    mapping(uint256 => uint256) public tokenClaims;

    address public _primarySaleReceiver;

    /// @dev Pre-defined roles for AccessControl
    bytes32 public constant SECOND_ADMIN_ROLE = keccak256("T2A");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    string internal rugStubsURI;

    mapping(uint256 => mapping(address => uint256)) public userArtClaims;

    uint256 internal constant stageLengthLimit = 20;

    /// @dev Fair.xyz address required for verifying signatures in the contract
    address internal constant FairxyzSignerAddress =
        0x7A6F5866f97034Bb7153829bdAaC1FFCb8Facb71;

    /// @dev Fair.xyz fee recipient address
    address internal constant FairxyzReceiverAddress =
        0xC5A2f45fF2d4CA27e167600b5225C7E6E187d8C0;

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
    bytes32 constant EIP712_URICHANGE_TYPE_HASH =
        keccak256("URIChange(address sender,string newPathURI,string newURI)");

    event NewStagesSet(StageData[] stages, uint256 startIndex);

    /*///////////////////////////////////////////////////////////////
                            Initialisation
    //////////////////////////////////////////////////////////////*/

    /// @dev Interface into FairXYZWallets. This provides the wallet address to which the Fair.xyz fee is sent to
    address public immutable FAIR_WALLETS_ADDRESS;

    constructor(address fairWallets) {
        if (fairWallets == address(0)) revert ZeroAddress();
        FAIR_WALLETS_ADDRESS = fairWallets;
        _disableInitializers();
    }

    /**
     * @dev Initialise a new Creator contract by setting variables and initialising
     * inherited contracts
     */
    function _initialize(
        uint96 royaltyPercentage_,
        address[] memory royaltyReceivers,
        StageData[] calldata stages,
        string memory name_,
        string memory symbol_
    ) external initializer {
        require(royaltyReceivers.length == 2);
        __ERC1155_init();

        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SECOND_ADMIN_ROLE, msg.sender);

        __Ownable_init();
        __ReentrancyGuard_init();
        __OperatorFilterer_init(
            DEFAULT_OPERATOR_FILTER_REGISTRY,
            DEFAULT_OPERATOR_FILTER_SUBSCRIPTION,
            true
        );
    
        name = name_;
        symbol = symbol_;
        _primarySaleReceiver = royaltyReceivers[0];
        _setDefaultRoyalty(royaltyReceivers[1], royaltyPercentage_);
        if (stages.length > 0) {
            _setStages(stages, 0);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Metadata
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Set the URI for Stubs
     */
    function setStubsURI(string memory newURI) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        rugStubsURI = newURI;
    }

    /**
     * @dev Set token data
     */
    function setTokenData(uint256 tokenId, TokenData calldata data) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();

        if (tokenId == 0) revert InvalidTokenId();

        tokenMap[tokenId] = data;
    }

    /**
     * @dev Set token URI
     */
    function setTokenURI(uint256 tokenId, string memory newURI) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();

        if (tokenId == 0) revert InvalidTokenId();

        tokenMap[tokenId].URI = newURI;
    }

    /**
     * @dev View token data
     */
    function viewTokenData(uint256 tokenId)
        external
        view
        returns (TokenData memory)
    {
        if (bytes(tokenMap[tokenId].URI).length == 0)
            revert TokenDoesNotExist();

        return tokenMap[tokenId];
    }

    function uri(uint256 tokenId) public view returns (string memory) {
        if (tokenId == 0) return rugStubsURI;

        if (bytes(tokenMap[tokenId].URI).length == 0)
            revert TokenDoesNotExist();

        return tokenMap[tokenId].URI;
    }

    /*///////////////////////////////////////////////////////////////
                            Sale stages logic
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev View sale parameters corresponding to a given stage
     */
    function viewStageMap(uint256 stageId)
        external
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

        if (newStage.phaseLimit < _stubsMinted())
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
    function changePrimarySaleReceiver(address newPrimarySaleReceiver)
        external
    {
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
     * @dev Only owner or Fair.xyz - withdraw contract balance to owner wallet. 6% primary sale fee to Fair.xyz
     */
    function withdraw() external payable nonReentrant {
        address fairWithdraw = IFairXYZWallets(FAIR_WALLETS_ADDRESS)
            .viewWithdraw();

        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                msg.sender == fairWithdraw,
            "Not owner or Fair.xyz!"
        );
        uint256 contractBalance = address(this).balance;

        (bool sent, ) = fairWithdraw.call{value: (contractBalance * 3) / 50}(
            ""
        );
        if (!sent) revert ETHSendFail();

        uint256 remainingContractBalance = address(this).balance;
        (bool sent_, ) = _primarySaleReceiver.call{
            value: remainingContractBalance
        }("");
        if (!sent_) revert ETHSendFail();
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
     * @dev Claim art by burning stubs
     */
    function claimArt(
        uint256 tokenIdToClaim,
        uint256 claimQuantity,
        uint256 totalStubsToBurn
    ) public {
        TokenData memory tokenToClaim = tokenMap[tokenIdToClaim];

        uint256 burnQuantity = tokenToClaim.burnPerToken * claimQuantity;
        if (burnQuantity != totalStubsToBurn) revert NotEnoughStubsToBurn();

        if (block.timestamp < tokenToClaim.saleStartTime)
            revert SaleNotActive();
        if (block.timestamp > tokenToClaim.saleEndTime) revert SaleNotActive();

        if (
            tokenClaims[tokenIdToClaim] + claimQuantity >
            tokenToClaim.supplyAvailable
        ) revert NotEnoughSupplyRemaining();

        if (
            userArtClaims[tokenIdToClaim][msg.sender] + claimQuantity >
            tokenToClaim.mintsPerWallet
        ) revert NotEnoughSupplyRemaining();

        unchecked{
            tokenClaims[tokenIdToClaim] += claimQuantity;
            userArtClaims[tokenIdToClaim][msg.sender] += claimQuantity;
        }

        _burn(msg.sender, 0, burnQuantity);
        _mint(msg.sender, tokenIdToClaim, claimQuantity, "", 0);
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

        uint256 currentMintedTokens = _stubsMinted();

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

            // latestBlockNumber[recipient] is the last block (nonce) that was used to mint from the given address.
            // Nonces can only increase in number in each transaction, and are part of the signature. This ensures
            // that past signatures are not reused
            if (latestBlockNumber[recipient] >= nonce) revert ReusedHash();

            // Set a time limit of 40 blocks for the signature
            if (block.number > nonce + 40) revert TimeLimit();
        }

        // Check that enough ETH is sent for the minting quantity
        uint256 costPerToken = dropData.price;
        if (msg.value != costPerToken * numberOfTokens) revert NotEnoughETH();

        // At least 1 and no more than 20 tokens can be minted per transaction
        if (!((0 < numberOfTokens) && (numberOfTokens <= 20)))
            revert TokenLimitPerTx();

        uint256 adjustedNumberOfTokens = handleReimbursement(
            recipient,
            presentStage,
            numberOfTokens,
            currentMintedTokens,
            dropData,
            maxMintsPerWallet
        );

        // Mint the NFTs
        _mint(recipient, 0, adjustedNumberOfTokens, "", nonce);

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

    function _stubsMinted() internal view returns (uint256) {
        return tokenSupply(0) + stubsBurnt;
    }

    function airdrop(uint256 tokenId, uint256 quantity, address recipient) 
        external
    {
        if (!hasRole(SECOND_ADMIN_ROLE, msg.sender)) revert UnauthorisedUser();
        if(tokenId != 0){
            if (bytes(tokenMap[tokenId].URI).length == 0)
                revert TokenDoesNotExist();
        }
        _mint(recipient, tokenId, quantity, "", 0);
    }

    /*///////////////////////////////////////////////////////////////
                            Miscellanous
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC1155xyzUpgradeable)
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
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     */
    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
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

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function emitEvent() public onlyOwner{
        emit NewCloneTicker(address(this), owner(), symbol);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}