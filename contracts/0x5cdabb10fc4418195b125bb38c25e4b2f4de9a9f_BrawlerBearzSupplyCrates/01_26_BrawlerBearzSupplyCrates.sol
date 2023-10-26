// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./common/NativeMetaTransaction.sol";
import "./interfaces/IBrawlerBearzDynamicItems.sol";
import "./interfaces/IBrawlerBearzSupplyCrates.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**************************************************
 * @title BrawlerBearzSupplyCrates
 * @author @scottybmitch
 **************************************************/

contract BrawlerBearzSupplyCrates is
    AccessControl,
    ERC2771Context,
    ReentrancyGuard,
    VRFConsumerBaseV2,
    NativeMetaTransaction,
    IBrawlerBearzSupplyCrates
{
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 private constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 private constant SUPPLY_CRATE_TYPE =
        keccak256(abi.encodePacked("SUPPLY_CRATE"));

    // Chainklink VRF V2
    VRFCoordinatorV2Interface immutable COORDINATOR;
    bytes32 public immutable keyHash;
    uint64 public immutable subscriptionId;
    uint16 constant numWords = 1;

    // Crate global properties
    bool public isPaused = true;
    bool public useVRF = false;

    /// @notice Nonce counter for pseudo requests
    uint256 private requestNonce;

    /// @dev requestId => drop config at time of request
    mapping(uint256 => SupplyDropRequest) private requestIdToRequestConfig;

    /// @dev crateId => Supply crate
    mapping(uint16 => SupplyCrateConfig) public supplyCrateConfiguration;

    /// @notice Vendor item contract
    IBrawlerBearzDynamicItems public vendorContract;

    constructor(
        address _vendorContractAddress,
        address _vrfV2Coordinator,
        address _trustedForwarder,
        bytes32 keyHash_,
        uint64 subscriptionId_
    ) VRFConsumerBaseV2(_vrfV2Coordinator) ERC2771Context(_trustedForwarder) {
        // Chainlink integration
        COORDINATOR = VRFCoordinatorV2Interface(_vrfV2Coordinator);
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;

        // Item contract
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);

        // Contract roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        _setupRole(MODERATOR_ROLE, _msgSender());
    }

    /// @dev AJ-walker alias algo selection O(1), probabilities and alias computed off-chain and saved as configuration
    function _chooseItem(
        uint256 seed,
        uint16[] memory probabilities,
        uint16[] memory aliases
    ) internal pure returns (uint16) {
        unchecked {
            uint256 traitSeed = seed & 0xFFFF;
            uint16 trait = uint16(traitSeed % probabilities.length);
            if (traitSeed >> 8 < probabilities[trait]) return trait;
            return aliases[trait];
        }
    }

    function _processFulfillment(
        uint256 requestId,
        SupplyCrateConfig memory config,
        uint256 randomness,
        uint16 openAmount,
        address requester
    ) internal {
        uint256 dropQuantity = config.quantity * openAmount;
        uint256[] memory ids = new uint256[](dropQuantity);
        uint256 seed;
        uint256 indexChosen;

        for (uint256 i = 0; i < dropQuantity; ) {
            seed = (randomness / ((i + 1) * 10)) % 2**32;

            indexChosen = _chooseItem(
                seed,
                config.probabilities,
                config.aliases
            );

            ids[i] = config.itemIds[indexChosen];

            unchecked {
                ++i;
            }
        }

        // Drop items from item contract to requester
        vendorContract.dropItems(requester, ids);

        emit CrateItemsDropped(
            requestId,
            randomness,
            config.crateId,
            requester,
            ids
        );
    }

    /// @dev Handle setting request configuration for a given request id
    function _handleCrateOpeningRequest(
        uint256 requestId,
        uint16 crateTokenId,
        uint16 openAmount,
        address requester
    ) internal {
        // Stores intermediate request state for later consumption
        requestIdToRequestConfig[requestId] = SupplyDropRequest({
            requester: requester,
            crateId: crateTokenId,
            openAmount: openAmount
        });
    }

    /// @dev Handle minting items related to a supply drop request
    function _handleCrateOpeningFulfillment(
        uint256 requestId,
        uint256 randomness
    ) internal {
        SupplyDropRequest storage requestConfig = requestIdToRequestConfig[
            requestId
        ];
        _processFulfillment(
            requestId,
            supplyCrateConfiguration[requestConfig.crateId],
            randomness,
            requestConfig.openAmount,
            requestConfig.requester
        );
    }

    /**
     * @notice Opens a crate by burning the represented token
     * @param crateTokenId - The token id of the owned supply crate item
     * @param openAmount - The amount of creates to open
     */
    function open(uint16 crateTokenId, uint16 openAmount) public nonReentrant {
        require(!isPaused, "!live");
        require(openAmount > 0, "!enough");

        SupplyCrateConfig storage config = supplyCrateConfiguration[
            crateTokenId
        ];

        require(config.crateId == crateTokenId, "!exists");

        address requester = _msgSender();

        // Burn crate tokens for exchange
        vendorContract.burnItemForOwnerAddress(
            crateTokenId,
            openAmount,
            requester
        );

        uint256 requestId;

        // Process crate opening sequence thru chainlink vrf or pseudorandom randomness
        if (useVRF == true) {
            requestId = COORDINATOR.requestRandomWords(
                _keyHash(),
                _subscriptionId(),
                3,
                300000,
                numWords
            );

            _processRandomnessRequest(
                requestId,
                crateTokenId,
                openAmount,
                requester
            );

            emit RandomnessRequest(requestId, crateTokenId);
        } else {
            // Bump internal request nonce for request id usage
            unchecked {
                requestNonce++;
            }

            _processFulfillment(
                requestNonce,
                supplyCrateConfiguration[crateTokenId],
                pseudorandom(requestNonce),
                openAmount,
                requester
            );
        }
    }

    /**
     * @notice Returns the config information of specific set of crate token ids
     * @param crateTokenIds - token ids to check against
     * @return bytes[]
     */
    function configurationOf(uint16[] memory crateTokenIds)
        external
        view
        returns (bytes[] memory)
    {
        bytes[] memory configs = new bytes[](crateTokenIds.length);
        SupplyCrateConfig storage config;
        string memory name;

        for (uint256 i; i < crateTokenIds.length; i++) {
            uint16 crateTokenId = crateTokenIds[i];

            config = supplyCrateConfiguration[crateTokenId];
            name = vendorContract.getItemName(crateTokenId);

            configs[i] = abi.encode(
                config.crateId,
                name,
                config.quantity,
                config.itemIds
            );
        }
        return configs;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        _processRandomnessFulfillment(requestId, randomWords[0]);
    }

    /// @dev Bastardized "randomness", if we want it
    function pseudorandom(uint256 nonce) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.prevrandao, nonce)
                )
            );
    }

    /**
     * Moderator functions
     */

    /**
     * @dev Set moderator address by owner
     * @param moderator address of moderator
     * @param approved true to add, false to remove
     */
    function setModerator(address moderator, bool approved)
        external
        onlyRole(OWNER_ROLE)
    {
        require(moderator != address(0), "!valid");

        if (approved) {
            _grantRole(MODERATOR_ROLE, moderator);
        } else {
            _revokeRole(MODERATOR_ROLE, moderator);
        }
    }

    /**
     * @notice Sets crate configuration
     * @param config The config object representing the crate drop
     */
    function setSupplyCrateConfig(SupplyCrateConfig calldata config)
        public
        onlyRole(MODERATOR_ROLE)
    {
        require(config.crateId > 0, "Invalid crate token id");
        require(config.quantity > 0, "Drop quantity should be greater than 0");
        require(config.itemIds.length > 0, "Must have at least 1 item");
        require(
            config.probabilities.length == config.aliases.length,
            "Invalid config"
        );

        // Check valid supply crate item
        string memory itemType = vendorContract.getItemType(config.crateId);

        require(
            SUPPLY_CRATE_TYPE == keccak256(abi.encodePacked(itemType)),
            "!crate"
        );

        supplyCrateConfiguration[config.crateId] = config;
    }

    /**
     * @notice Sets the pause state
     * @param _isPaused The pause state
     */
    function setPaused(bool _isPaused) external onlyRole(MODERATOR_ROLE) {
        isPaused = _isPaused;
    }

    /**
     * Chainlink integration
     */

    /// @dev Handle randomness request
    function _processRandomnessRequest(
        uint256 requestId,
        uint16 crateTokenId,
        uint16 openAmount,
        address requester
    ) internal {
        _handleCrateOpeningRequest(
            requestId,
            crateTokenId,
            openAmount,
            requester
        );
    }

    /// @dev Handles randomness fulfillment
    function _processRandomnessFulfillment(
        uint256 requestId,
        uint256 randomness
    ) internal {
        _handleCrateOpeningFulfillment(requestId, randomness);
    }

    function _keyHash() internal view returns (bytes32) {
        return keyHash;
    }

    function _subscriptionId() internal view returns (uint64) {
        return subscriptionId;
    }

    /**
     * Owner functions
     */

    /// @dev Sets the contract address for the item to burn
    function setVendorContract(address _vendorContractAddress)
        external
        onlyRole(OWNER_ROLE)
    {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /// @dev Determines whether to use VRF or not
    function setUseVRF(bool _useVRF) external onlyRole(OWNER_ROLE) {
        useVRF = _useVRF;
    }

    /**
     * Native meta transactions
     */

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}