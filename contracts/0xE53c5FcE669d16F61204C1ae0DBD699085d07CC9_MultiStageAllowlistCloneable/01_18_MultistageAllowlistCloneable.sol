// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

// Imports.
import { ICollection } from "./interfaces/ICollection.sol";
import { ICollectionCloneable } from "./interfaces/ICollectionCloneable.sol";
import { ICollectionNFTEligibilityPredicate } from "./interfaces/ICollectionNFTEligibilityPredicate.sol";
import { ICollectionNFTMintFeePredicate } from "./interfaces/ICollectionNFTMintFeePredicate.sol";
import { IHashes } from "./interfaces/IHashes.sol";
import { OwnableCloneable } from "./lib/OwnableCloneable.sol";

/**
 * @title The interface for the NFT smart contract.
 * @dev The following interface is used to properly call functions of the NFT smart contract.
 *      The interface is necessary as it describes the functions that are present in the CollectionNFTCloneableV1
 *      smart contract but are not specified in its interfaces.
 */
interface INFT {
    /**
     * @notice Returns the current token ID (number of minted NFTs).
     * @return The current token ID.
     */
    function nonce() external view returns (uint256);

    /**
     * @notice Returns the owner of the tokenId token.
     * @param tokenId The token ID to get the owner of.
     * @return The owner address.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /**
     * @notice Returns the number of Hashes qualifying for governance.
     * @return The number of Hashes qualifying for governance.
     */
    function governanceCap() external view returns (uint256);
}

/**
 * @title Cloneable Multi-stage Allowlist.
 * @notice This contract is a cloneable extension to the Hashes ecosystem. Its main goal is to introduce
 *         a decentralized allowlist and the ability to control mint eligibility and fees.  The contract
 *         allows owners to create and manage staged minting NFT events, including allowlists,
 *         maximum numbers of tokens, prices, etc. It can be directly integrated into the ecosystem and
 *         used with the CollectionNFTCloneableV1 smart contracts.
 * @author PopBlocks (popblocks.org)
 */
contract MultiStageAllowlistCloneable is
    ICollection,
    ICollectionCloneable,
    ICollectionNFTEligibilityPredicate,
    ICollectionNFTMintFeePredicate,
    OwnableCloneable
{
    /**
     * @notice The struct specifies a selling stage.
     * @dev param onlyDaoHashes - The flag indicates that only DAO hashes are eligible to mint during the stage.
     * @dev param allowlistActivated - Specifies if the tokenIdAllowlist and walletAllowlist should be considered.
     * @dev param size - The max number of tokens available to mint during the stage.
     * @dev param eligibilityExtension - An additional smart contract that can be used to check eligibility to mint.
                                         Set to address(0) to disable the functionality.
     * @dev param price - The mint price during the stage.
     * @dev param allowlistSize - The size of the mapping of bitfields.
     * @dev param tokenIdAllowlist - The bitmaps that specify what token IDs are eligible to mint during the stage.
     * @dev param walletAllowlist - The additional mapping of allowed or blocked wallet addresses.
     */
    struct Stage {
        bool onlyDaoHashes;
        bool allowlistActivated;
        uint32 size;
        ICollectionNFTEligibilityPredicate eligibilityExtension;
        uint256 price;
        uint256 allowlistSize;
        mapping(uint256 => uint256) tokenIdAllowlist;
        mapping(address => bool) walletAllowlist;
    }

    /**
     * @notice The struct specifies a selling stage.
     * @dev param onlyDaoHashes - The flag indicates that only DAO hashes are eligible to mint during the stage.
     * @dev param allowlistActivated - Specifies if the tokenIdAllowlist and walletAllowlist should be considered.
     * @dev param eligibilityExtension - An additional smart contract that can be used to check eligibility to mint.
                                         Set to address(0) to disable the functionality.
     * @dev param size - The max number of tokens available to mint during the stage.
     * @dev param price - The mint price during the stage.
     * @dev param walletAllowlist - The additional mapping of allowed wallet addresses.
     * @dev param tokenIdAllowlist - The bitmaps that specify what token IDs are eligible to mint during the stage.
     */
    struct InitializerSettings {
        bool onlyDaoHashes;
        bool allowlistActivated;
        address eligibilityExtension;
        uint32 size;
        uint256 price;
        address[] walletAllowlist;
        uint256[] tokenIdAllowlist;
    }

    /// @notice The constant that specifies that the size of a stage is not limited.
    uint8 public constant UNLIMITED_TOKENS = 0;
    /// @notice The number of token ID positions per single element of the allowlist array.
    uint256 public constant IDS_PER_ELEMENT = 256;
    /// @notice The starting token ID for the current round.
    uint256 public startTokenId;
    /// @notice The Hashes NFT smart contract interface.
    INFT public hashesContract;
    /// @notice The NFT smart contract interface.
    INFT public collectionNFTContract;
    /// @notice The number of Hashes qualifying for governance.
    uint256 public hashesGovernanceCap;
    /// @notice The available stages.
    Stage[] public stages;
    /// @notice The number of stages.
    uint8 public numStages;
    /// @notice The flag controls stage activation.
    bool public stagesActive;
    /// @notice The switch turns off minting forever.
    bool public mintingClosed;
    /// @notice The current active stage.
    uint8 public currentStage;
    /// @notice The initialization state of the current smart contract.
    bool private _initialized;

    /**
     * @notice Checks if a stage index is valid.
     * @dev Reverts when the stage index is out of bound.
     * @param stage The index of a stage.
     */
    modifier validStage(uint8 stage) {
        require(stage < stages.length, "Stage ID is out of bound.");
        _;
    }

    /**
     * @notice Checks if the current smart contract is properly initialized.
     */
    modifier isInitialized() {
        require(
            _initialized && address(collectionNFTContract) != address(0),
            "The smart contract needs to be initialized before using."
        );
        _;
    }

    /**
     * @notice This function initializes a cloneable implementation contract.
     * @param hashesToken_ The Hashes NFT contract address.
     * @param factoryMaintainerAddress_ The address of the current factory maintainer.
     * @param createCollectionCaller_ The address which has called createCollection on the factory.
     *        This will be the Owner role of this collection.
     * @param initializationData_ ABI encoded initialization data. This expected encoding is a struct
     *        with the properties described in the InitializerSettings structure.
     */
    function initialize(
        IHashes hashesToken_,
        address factoryMaintainerAddress_,
        address createCollectionCaller_,
        bytes memory initializationData_
    ) external override {
        require(!_initialized, "The smart contract has been already initialized.");
        // Set initialization state.
        _initialized = true;
        // Initialize the owner.
        initializeOwnership(createCollectionCaller_);
        // Set the state variables.
        hashesContract = INFT(address(hashesToken_));
        hashesGovernanceCap = hashesContract.governanceCap();
        // Decode initialization data.
        InitializerSettings[] memory newStages = abi.decode(initializationData_, (InitializerSettings[]));

        for (uint8 i = 0; i < newStages.length; i++) {
            stages.push();
            stages[i].size = newStages[i].size;
            stages[i].price = newStages[i].price;
            stages[i].onlyDaoHashes = newStages[i].onlyDaoHashes;
            stages[i].allowlistActivated = newStages[i].allowlistActivated;
            stages[i].eligibilityExtension = ICollectionNFTEligibilityPredicate(newStages[i].eligibilityExtension);
            stages[i].allowlistSize = newStages[i].tokenIdAllowlist.length;

            for (uint256 k = 0; k < newStages[i].tokenIdAllowlist.length; k++) {
                stages[i].tokenIdAllowlist[k] = newStages[i].tokenIdAllowlist[k];
            }
            
            for (uint256 j = 0; j < newStages[i].walletAllowlist.length; j++) {
                stages[i].walletAllowlist[newStages[i].walletAllowlist[j]] = true;
            }
        }

        currentStage = type(uint8).max;
        numStages = uint8(stages.length);
    }

    /**
     * @notice Sets the NFT smart contract address to be used during minting.
     * @param nftAddress The address of the NFT smart contract.
     */
    function setNftAddress(address nftAddress) external onlyOwner {
        require(address(collectionNFTContract) == address(0), "The NFT address has already been set.");
        require(nftAddress != address(0), "The NFT address cannot be a zero address.");
        collectionNFTContract = INFT(nftAddress);
    }

    /**
     * @notice Sets eligibility to mint for a specific token ID.
     * @param stage The ID of the stage.
     * @param tokenId The ID of the token.
     * @param eligibility Eligibility status.
     */
    function setTokenIdEligibility(
        uint8 stage,
        uint256 tokenId,
        bool eligibility
    ) external onlyOwner isInitialized validStage(stage) {
        (uint256 elementIndex, uint256 bitIndex) = _getTokenElementPositions(tokenId);
        if (eligibility) {
            stages[stage].tokenIdAllowlist[elementIndex] = _setBit(
                stages[stage].tokenIdAllowlist[elementIndex],
                bitIndex
            );
        } else {
            stages[stage].tokenIdAllowlist[elementIndex] = _clearBit(
                stages[stage].tokenIdAllowlist[elementIndex],
                bitIndex
            );
        }
    }

    /**
     * @notice Sets a token ID allowlist for a specified stage.
     * @param stage The ID of the stage.
     * @param tokenIdAllowlist The bitmaps that specify what token IDs are eligible to mint during the stage.
     */
    function setTokenIdAllowlist(uint8 stage, uint256[] memory tokenIdAllowlist)
        external
        onlyOwner
        isInitialized
        validStage(stage)
    {
        for (uint256 i = 0; i < tokenIdAllowlist.length; i++) {
            stages[stage].tokenIdAllowlist[i] = tokenIdAllowlist[i];
        }

        stages[stage].allowlistSize = tokenIdAllowlist.length;
    }

    /**
     * @notice Sets eligibility to mint for a specific wallet.
     * @param stage The ID of the stage.
     * @param walletAddress The wallet address.
     * @param eligibility Eligibility status.
     */
    function setWalletEligibility(
        uint8 stage,
        address walletAddress,
        bool eligibility
    ) external onlyOwner isInitialized validStage(stage) {
        stages[stage].walletAllowlist[walletAddress] = eligibility;
    }

    /**
     * @notice Sets the eligibility extension.
     * @param stage The ID of the stage.
     * @param extensionAddress The address of a CollectionNFTEligibilityPredicate smart contract.
     */
    function setEligibilityExtension(uint8 stage, address extensionAddress)
        external
        onlyOwner
        isInitialized
        validStage(stage)
    {
        stages[stage].eligibilityExtension = ICollectionNFTEligibilityPredicate(extensionAddress);
    }

    /**
     * @notice Turns minting on and off.
     * @param state Set to true to turn the minting process on, else set to false.
     */
    function setStageState(bool state) external onlyOwner isInitialized {
        stagesActive = state;
    }

    /**
     * @notice Turns off minting forever.
     */
    function closeMinting() external onlyOwner isInitialized {
        mintingClosed = true;
    }

    /**
     * @notice Starts next stage.
     */
    function startNextStage() external isInitialized onlyOwner {
        if (currentStage == type(uint8).max) {
            currentStage = 0;
        } else {
            require(++currentStage < stages.length, "No more available stages.");
        }

        startTokenId = collectionNFTContract.nonce();
    }

    /**
     * @notice Starts a specific stage.
     * @param stageIndex The index of a stage to start.
     */
    function startStage(uint8 stageIndex) external isInitialized validStage(stageIndex) onlyOwner {
        if (currentStage != type(uint256).max) {
            require(stageIndex > currentStage, "Cannot set previous stages as active.");
        }

        currentStage = stageIndex;
        startTokenId = collectionNFTContract.nonce();
    }

    /**
     * @notice Checks if a user is eligible to mint a token.
     * @param _tokenId The token ID to be minted.
     * @param _hashesTokenId The hashes token ID used to mint.
     * @return True, if the user is eligible to mint, else - false.
     */
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId)
        external
        view
        override
        isInitialized
        returns (bool)
    {
        if (
            mintingClosed ||
            !stagesActive ||
            (stages[currentStage].size != UNLIMITED_TOKENS && _tokenId >= startTokenId + stages[currentStage].size) ||
            _tokenId < startTokenId ||
            (stages[currentStage].onlyDaoHashes && _hashesTokenId >= hashesGovernanceCap)
        ) {
            return false;
        }

        bool eligibilityExtensionStatus = true;
        bool allowlistStatus = true;

        if (stages[currentStage].allowlistActivated) {
            allowlistStatus =
                _isTokenIdAllowed(currentStage, _hashesTokenId) ||
                stages[currentStage].walletAllowlist[hashesContract.ownerOf(_hashesTokenId)];
        }

        if (address(stages[currentStage].eligibilityExtension) != address(0)) {
            eligibilityExtensionStatus = stages[currentStage].eligibilityExtension.isTokenEligibleToMint(
                _tokenId,
                _hashesTokenId
            );
        }

        return allowlistStatus && eligibilityExtensionStatus;
    }

    /**
     * @notice Gets the mint fee for the current stage.
     * @param _tokenId The token ID to be minted.
     * @param _hashesTokenId The hashes token ID used to mint.
     * @return The mint fee.
     */
    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId)
        external
        view
        override
        isInitialized
        returns (uint256)
    {
        return stages[currentStage].price;
    }

    /**
     * @notice This function is used by the Factory to verify the format of ecosystem settings.
     * @dev The Default ecosystem doesn't use any ecosystem settings.
     * @param _settings ABI encoded ecosystem settings data.
     * @return The boolean result of the validation.
     */
    function verifyEcosystemSettings(bytes memory _settings) external pure override returns (bool) {
        return _settings.length == 0;
    }

    /**
     * @notice Checks if a token ID is in the allowlist.
     * @param stage The ID of the stage.
     * @param tokenId The ID of the token.
     * @return True, if token ID is allowed, else - false.
     */
    function _isTokenIdAllowed(uint8 stage, uint256 tokenId) internal view validStage(stage) returns (bool) {
        // Check if provided token ID is out of the bounds of the allowlist.
        if (tokenId >= stages[stage].allowlistSize * IDS_PER_ELEMENT) return false;

        (uint256 elementIndex, uint256 bitIndex) = _getTokenElementPositions(tokenId);
        uint256 element = stages[stage].tokenIdAllowlist[elementIndex];
        uint256 bit = 1;
        return (element & (bit << bitIndex)) > 0;
    }

    /**
     * @notice Gets token ID bit position in the allowlist array.
     * @param tokenId The ID of the token.
     * @return The element index of the array and the token bit position in the element.
     */
    function _getTokenElementPositions(uint256 tokenId) internal pure returns (uint256, uint256) {
        // The index of the element in the array of the allowlist bitfields.
        uint256 elementIndex = tokenId / IDS_PER_ELEMENT;
        // The index of the bit in the bitfield.
        uint256 bitIndex = tokenId % IDS_PER_ELEMENT;

        return (elementIndex, bitIndex);
    }

    /**
     * @notice Sets a bit in a bitfield.
     * @param bitField The bitfield.
     * @param position The position of the bit to set.
     */
    function _setBit(uint256 bitField, uint256 position) internal pure returns (uint256) {
        require(position < 256, "Exceeds the number of bits in uint256.");
        return bitField | (uint256(1) << position);
    }

    /**
     * @notice Clears a bit in a bitfield.
     * @param bitField The bitfield.
     * @param position The position of the bit to clear.
     */
    function _clearBit(uint256 bitField, uint256 position) internal pure returns (uint256) {
        require(position < 256, "Exceeds the number of bits in uint256.");
        return bitField & ~(uint256(1) << position);
    }
}