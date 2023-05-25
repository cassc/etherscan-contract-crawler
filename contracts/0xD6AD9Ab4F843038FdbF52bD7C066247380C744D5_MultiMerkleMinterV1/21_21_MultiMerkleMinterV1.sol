// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

// Created By: @backseats_eth

// Forked from and inspired by ArtBlocks' MerkleMinterV1 contract
// https://github.com/ArtBlocks/artblocks-contracts/blob/32738da594e7b9d18e25011b1c7fefa4abb1bda9/contracts/archive/minter-suite/Minters/MinterMerkle/MinterMerkleV1.sol

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IGenArt721CoreContractV3_Base.sol";
import "./interfaces/IFilteredMinterMerkleV2.sol";
import "./interfaces/IMinterFilterV0.sol";
import "./MinterBase_v0_1_1.sol";

/**
 * @title Filtered Minter contract that allows tokens to be minted with ETH
 * for addresses in a Merkle allowlist.
 * This is designed to be used with GenArt721CoreContractV3 flagship or
 * engine contracts.
 * @notice Privileged Roles and Ownership:
 * This contract is designed to be managed, with limited powers.
 * Privileged roles and abilities are controlled by the project's artist, which
 * can be modified by the core contract's Admin ACL contract. Both of these
 * roles hold extensive power and can modify minter details.
 * Care must be taken to ensure that the admin ACL contract and artist
 * addresses are secure behind a multi-sig or other access control mechanism.
 * ----------------------------------------------------------------------------
 * The following functions are restricted to a project's artist:
 * - createNewStage
 * - manuallyLimitProjectMaxInvocations
 * - setProjectMaxInvocations
 * - teamMint
 * - updateMerkleRoot
 * - updatePricePerTokenInWei
 * - updateSystemAddress
 * ----------------------------------------------------------------------------
 * Additional admin and artist privileged roles may be described on other
 * contracts that this minter integrates with.
 * ----------------------------------------------------------------------------
 */
contract MultiMerkleMinterV1 is ReentrancyGuard, MinterBase, IFilteredMinterMerkleV2 {
    using MerkleProof for bytes32[];
    using ECDSA for bytes32;

    // Used for unneeded protocol-conformance functions
    error ActionNotSupported();

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// Core contract address this minter interacts with
    address public immutable genArt721CoreAddress;

    /// The core contract integrates with V3 contracts
    IGenArt721CoreContractV3_Base private immutable genArtCoreContract_Base;

    /// Minter filter address this minter interacts with
    address public immutable minterFilterAddress;

    /// Minter filter this minter may interact with.
    IMinterFilterV0 private immutable minterFilter;

    /// minterType for this minter
    string public constant minterType = "MultiMerkleMinterV1";

    /// The theoretical total number of tokens that can be minted for a project on GenArt721Core
    uint256 constant ONE_MILLION = 1_000_000;

    // A mapping of project ids to their Project Config
    mapping(uint256 => ProjectConfig) public projectConfig;

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    // A ProjectConfig is specific to the MultiMerkleMinter so that it can be re-used to mint
    // multiple GenArtCoreV3-conforming projects
    struct ProjectConfig {
        // If the project has minted out
        bool maxHasBeenInvoked;

        // If the creator or artist has configured the price
        bool priceIsConfigured;

        // The id of the current stage of the mint. If 0, the project is minted out or not started
        uint8 currentStageId;

        // The count of the stages for the project. Starts at 0 for no Stages created
        uint8 stagesCount;

        // The maximum amount of tokens that can be minted for the project
        uint24 maxInvocations;

        // Which system address is the signer for the project id
        address systemAddress;

        // If a nonce has been used or not to mint the project
        mapping(string => bool) usedNonces;

        // How many times an address has minted for the project at this Stage
        mapping(uint8 => mapping(address => uint)) addressMintedCount;

        // A mapping of the id of the Stage to the Stage, sequentially from 1.
        mapping(uint8 => Stage) stages;
    }

    struct Stage {
        // The id of the Stage. Starts at 1. 0 is the null state
        uint8 id;

        // The maximum amount of tokens a wallet can mint in that stage
        uint8 transactionMaxInvocations;

        // The Unix timestamp of when the stage starts. Suffers from the 2038 problem but we'll be fine
        uint32 stageStartTime;

        // This will be the stageStartTime of the next Stage - 1
        uint32 stageEndTime;

        // Optional Merkle Root. Use 0x if not used
        bytes32 merkleRoot;

        // The price of the token for that stage
        uint256 pricePerTokenInWei;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier onlyArtist(uint256 _projectId) {
        require(msg.sender == genArtCoreContract_Base.projectIdToArtistAddress(_projectId), "Only Artist");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes contract to be a Filtered Minter for
     * `_minterFilter`, integrated with Art Blocks core contract
     * at address `_genArt721Address`.
     * @param _genArt721Address Art Blocks core contract address for
     * which this contract will be a minter.
     * @param _minterFilter Minter filter for which this will be a
     * filtered minter.
     */
    constructor(
        address _genArt721Address,
        address _minterFilter
    ) ReentrancyGuard() MinterBase(_genArt721Address) {
        genArt721CoreAddress = _genArt721Address;
        // always populate immutable engine contracts, but only use appropriate
        // interface based on isEngine in the rest of the contract
        genArtCoreContract_Base = IGenArt721CoreContractV3_Base(
            _genArt721Address
        );

        minterFilterAddress = _minterFilter;
        minterFilter = IMinterFilterV0(_minterFilter);

        require(minterFilter.genArt721CoreAddress() == _genArt721Address, "Illegal Contract Pairing");
    }

    /**
     * @notice Update the Merkle root for project `_projectId`.
     * @param _projectId Project ID to be updated.
     * @param _stageId Stage ID to be updated.
     * @param _root root of Merkle tree defining addresses allowed to mint
     * on project `_projectId`.
     */
    function updateMerkleRoot(
        uint256 _projectId,
        uint8 _stageId,
        bytes32 _root
    ) external onlyArtist(_projectId) {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        _projectConfig.stages[_stageId].merkleRoot = _root;
    }

    function updateStartingTimeForStage(
        uint256 _projectId,
        uint8 _stageId,
        uint32 _newStartingTime
    ) external onlyArtist(_projectId) {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        require(_newStartingTime > 0, "Can't be 0");
        require(_newStartingTime > block.timestamp, "Must be in the future");

        // s1: id 1
        // s2: id 2
        // stages count = 2
        if (_stageId + 1 <= _projectConfig.stagesCount) {
            // Ensure future stage exists and it doesn't collide
            Stage memory stage = _projectConfig.stages[_stageId + 1];
            require(stage.stageStartTime > 0 && _newStartingTime < stage.stageStartTime, "Stage can't start after next one");
        }

        Stage memory stage = _projectConfig.stages[_stageId];
        require(_newStartingTime < stage.stageEndTime, "Can't start after end");

        _projectConfig.stages[_stageId].stageStartTime = _newStartingTime;
    }

    /**
     * @notice Returns hashed address (to be used as merkle tree leaf).
     * Included as a public function to enable users to calculate their hashed
     * address in Solidity when generating proofs off-chain.
     * @param _address address to be hashed
     * @return bytes32 hashed address, via keccak256 (using encodePacked)
     */
    function hashAddress(address _address) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address));
    }

    /**
     * @notice Verify if address is allowed to mint on project `_projectId`.
     * @param _merkleRoot The Merkle root for the project.
     * @param _proof Merkle proof for address.
     * @param _address Addrexss to check.
     * @return inAllowlist true only if address is allowed to mint and valid
     * Merkle proof was provided
     */
    function verifyAddress(
        bytes32 _merkleRoot,
        bytes32[] calldata _proof,
        address _address
    ) public pure returns (bool) {
        return _proof.verifyCalldata(_merkleRoot, hashAddress(_address));
    }

    /**
     * @notice Syncs local maximum invocations of project `_projectId` based on
     * the value currently defined in the core contract.
     * @param _projectId Project ID to set the maximum invocations for.
     * @dev this enables gas reduction after maxInvocations have been reached -
     * core contracts shall still enforce a maxInvocation check during mint.
     */
    function setProjectMaxInvocations(uint256 _projectId) external onlyArtist(_projectId) {
        uint256 maxInvocations;
        uint256 invocations;
        (invocations, maxInvocations, , , , ) = genArtCoreContract_Base
            .projectStateData(_projectId);
        // update storage with results
        projectConfig[_projectId].maxInvocations = uint24(maxInvocations);

        // We need to ensure maxHasBeenInvoked is correctly set after manually syncing the
        // local maxInvocations value with the core contract's maxInvocations value.
        // This synced value of maxInvocations from the core contract will always be greater
        // than or equal to the previous value of maxInvocations stored locally.
        projectConfig[_projectId].maxHasBeenInvoked =
            invocations == maxInvocations;

        emit ProjectMaxInvocationsLimitUpdated(_projectId, maxInvocations);
    }

    /**
     * @notice Manually sets the local maximum invocations of project `_projectId`
     * with the provided `_maxInvocations`, checking that `_maxInvocations` is less
     * than or equal to the value of project `_project_id`'s maximum invocations that is
     * set on the core contract.
     * @dev Note that a `_maxInvocations` of 0 can only be set if the current `invocations`
     * value is also 0 and this would also set `maxHasBeenInvoked` to true, correctly short-circuiting
     * this minter's purchase function, avoiding extra gas costs from the core contract's maxInvocations check.
     * @param _projectId Project ID to set the maximum invocations for.
     * @param _maxInvocations Maximum invocations to set for the project.
     */
    function manuallyLimitProjectMaxInvocations(
        uint256 _projectId,
        uint256 _maxInvocations
    ) external onlyArtist(_projectId) {
        // CHECKS
        // ensure that the manually set maxInvocations is not greater than what is set on the core contract
        uint256 maxInvocations;
        uint256 invocations;
        (invocations, maxInvocations, , , , ) = genArtCoreContract_Base.projectStateData(_projectId);
        require(
            _maxInvocations <= maxInvocations,
            "Cannot increase project max invocations above core contract set project max invocations"
        );
        require(
            _maxInvocations >= invocations,
            "Cannot set project max invocations to less than current invocations"
        );

        // EFFECTS
        // update storage with results
        projectConfig[_projectId].maxInvocations = uint24(_maxInvocations);
        // We need to ensure maxHasBeenInvoked is correctly set after manually setting the
        // local maxInvocations value.
        projectConfig[_projectId].maxHasBeenInvoked =
            invocations == _maxInvocations;

        emit ProjectMaxInvocationsLimitUpdated(_projectId, _maxInvocations);
    }

    /**
     * @notice projectId => has project reached its maximum number of
     * invocations? Note that this returns a local cache of the core contract's
     * state, and may be out of sync with the core contract. This is
     * intentional, as it only enables gas optimization of mints after a
     * project's maximum invocations has been reached. A false negative will
     * only result in a gas cost increase, since the core contract will still
     * enforce a maxInvocation check during minting. A false positive is not
     * possible because the V3 core contract only allows maximum invocations
     * to be reduced, not increased. Based on this rationale, we intentionally
     * do not do input validation in this method as to whether or not the input
     * `_projectId` is an existing project ID.
     */
    function projectMaxHasBeenInvoked(
        uint256 _projectId
    ) external view returns (bool) {
        return projectConfig[_projectId].maxHasBeenInvoked;
    }

    // Returns the number of tokens minted for an address for a project id
    function getAddressMintedCount(uint256 _projectId, uint8 _stageId, address _address) external view returns (uint) {
        return projectConfig[_projectId].addressMintedCount[_stageId][_address];
    }

    /**
     * @notice projectId => project's maximum number of invocations.
     * Optionally synced with core contract value, for gas optimization.
     * Note that this returns a local cache of the core contract's
     * state, and may be out of sync with the core contract. This is
     * intentional, as it only enables gas optimization of mints after a
     * project's maximum invocations has been reached.
     * @dev A number greater than the core contract's project max invocations
     * will only result in a gas cost increase, since the core contract will
     * still enforce a maxInvocation check during minting. A number less than
     * the core contract's project max invocations is only possible when the
     * project's max invocations have not been synced on this minter, since the
     * V3 core contract only allows maximum invocations to be reduced, not
     * increased. When this happens, the minter will enable minting, allowing
     * the core contract to enforce the max invocations check. Based on this
     * rationale, we intentionally do not do input validation in this method as
     * to whether or not the input `_projectId` is an existing project ID.
     */
    function projectMaxInvocations(
        uint256 _projectId
    ) external view returns (uint256) {
        return uint256(projectConfig[_projectId].maxInvocations);
    }

    /**
     * @notice Updates this minter's price per token of project `_projectId`
     * to be '_pricePerTokenInWei`, in Wei.
     * This price supersedes any legacy core contract price per token value.
     * @dev Note that it is intentionally supported here that the configured
     * price may be explicitly set to `0`.
     */
    function updatePricePerTokenInWei(
        uint256 _projectId,
        uint8 _stageId,
        uint256 _pricePerTokenInWei
    ) external onlyArtist(_projectId) {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        _projectConfig.priceIsConfigured = true;
        _projectConfig.stages[_stageId].pricePerTokenInWei = _pricePerTokenInWei;
    }

    /**
    * @notice Purchases 1 or more tokens from a project
    * @param _projectId The project id
    * @param _amount The number of tokens to purchase
    * @param _signature A signature, generated from the minting site
    * @param _data abi-encoded data, generated from the minting site
    * @param _nonce A nonce, to accompany the signature
    */
    function purchaseMMM(
        uint256 _projectId,
        uint256 _amount,
        bytes calldata _signature,
        bytes calldata _data,
        bytes32[] calldata _merkleProof,
        string calldata _nonce
    ) public payable nonReentrant() {
        uint256 pid = _projectId;
        uint256 amount = _amount;
        bytes memory sig = _signature;

        // CHECKS
        ProjectConfig storage _projectConfig = projectConfig[pid];

        // Note that `maxHasBeenInvoked` is only checked here to reduce gas
        // consumption after a project has been fully minted.
        // `_projectConfig.maxHasBeenInvoked` is locally cached to reduce
        // gas consumption, but if not in sync with the core contract's value,
        // the core contract also enforces its own max invocation check during
        // minting.
        require(!_projectConfig.maxHasBeenInvoked, "Max Invocations Reached");

        // Gets the current Stage by timestamp
        Stage memory _currentStage = currentStage(pid);

        // If what we have set in storage is not the current Stage, update it
        if (_projectConfig.currentStageId != _currentStage.id) {
            _projectConfig.currentStageId = _currentStage.id;
        }

        // See function `createNewStage`
        require(_currentStage.stageStartTime != 0, "Create A Stage To Begin");

        // require artist to have configured price of token on this minter
        require(_projectConfig.priceIsConfigured, "Price Not Configured");

        // Check the price is correct
        uint256 expectedPrice = currentStagePrice(pid) * amount;
        require(msg.value == expectedPrice, "Wrong Price");

        // Ensure the nonce coming from the server hasn't already been used
        require(!_projectConfig.usedNonces[_nonce], "Nonce Used");

        // Ensure the data signed from the server is valid
        require(isValidSignature(
            _projectConfig.systemAddress, keccak256(abi.encodePacked(msg.sender, amount, _nonce)), sig),
            "Invalid Signature"
        );

        // Decode a tuple of the address and the max they can mint and ensure the data coming from the server is correct
        (address _address, uint256 maxMintCount) = abi.decode(_data, (address, uint256));
        require(_address == msg.sender, "Bad Data");

        // If server sends through a maxMintCount > 0, check how many they've minted this stage
        bool doMaxCheckForStage = maxMintCount > 0;

        // Check to see if the msg.sender is on the allowlist if the Stage has an allowlist. First checks to see if the merkle root is the 0 address
        if (address(uint160(uint256(currentStage(pid).merkleRoot))) != address(0)) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, _currentStage.merkleRoot, leaf), "Not On Allowlist");
        }

        // Ensure the amount they're minting doesn't exceed their max for the stage
        if (doMaxCheckForStage) {
            require(_projectConfig.addressMintedCount[_currentStage.id][msg.sender] + amount <= maxMintCount, "Can't Mint That Many");
        }

        // Update the record of the nonce and the overall msg.sender mint count
        _projectConfig.usedNonces[_nonce] = true;

        // Increment user's minted count for this project
        unchecked {
            _projectConfig.addressMintedCount[_currentStage.id][msg.sender] += amount;
        }

        // Mint tokens
        uint i;
        do {
            uint256 tokenId = minterFilter.mint(msg.sender, pid, msg.sender);

            // If the max has been reached, set the flag to true
            unchecked {
                if (tokenId % ONE_MILLION == _projectConfig.maxInvocations - 1) {
                    _projectConfig.maxHasBeenInvoked = true;
                    // If minted out, set this to 0.
                    _projectConfig.currentStageId = 0;
                }
            }

            unchecked { ++i; }
        } while (i < amount);

        // INTERACTIONS
        splitFundsETH(pid, msg.value, genArt721CoreAddress);
    }

    function teamMint(
        uint256 _projectId,
        address[] calldata _addresses,
        uint256[] calldata _counts
    ) external onlyArtist(_projectId) {
        require(_addresses.length == _counts.length, "Unequal arrays");

        uint256 length = _addresses.length;
        // Outer loop iterator
        uint256 i;
        // Inner loop iterator
        uint256 n;

        // Loops through the addresses
        do {
            // Loops through the tokens to mint the address
            do {
                // This will fail in the underlying contract if exceeds project invocations
                minterFilter.mint(_addresses[i], _projectId, msg.sender);
                unchecked { ++n; }
            } while (n < _counts[i]);

            unchecked { ++i; }
        } while (i < length);
    }

    function createNewStage(
        uint256 _projectId,
        uint32 _stageStartTime,
        bytes32 _merkleRoot,
        uint256 _pricePerTokenInWei,
        uint8 _transactionMaxInvocations
    ) onlyArtist(_projectId) external {
        // Ensure the Stage start time is in the future
        require(_stageStartTime > block.timestamp, "No Start Block In Past");

        // Get ProjectConfig from mapping
        ProjectConfig storage config = projectConfig[_projectId];

        // Don't create a new Stage if minted out
        require(!config.maxHasBeenInvoked, "Minted Out Cant Create New Stage");

        // Start the `stages` mapping IDs at 1 so that 0 can be a null state
        // Set the ProjectConfig's `priceIsConfigured` if this is the first Stage
        uint8 nextStageId;
        if (config.stagesCount == 0) {
             nextStageId = 1;
             config.priceIsConfigured = true;
        } else {
            nextStageId = config.stagesCount + 1;
        }

        // Set the previous Stage's end time to the new Stage's start time - 1
        if (nextStageId > 1) {
            config.stages[nextStageId - 1].stageEndTime = _stageStartTime - 1;
        }

        // Increment the ProjectConfig's Stages count (i.e. 2 stages, stagesCount = 2)
        unchecked { ++config.stagesCount; }

        // Store the new Stage
        config.stages[nextStageId] = Stage({
            id: nextStageId,
            transactionMaxInvocations: _transactionMaxInvocations,
            stageStartTime: _stageStartTime,
            stageEndTime: type(uint32).max, // temporary value; overwritten on subsequent stage creation, see a few lines above
            merkleRoot: _merkleRoot,
            pricePerTokenInWei: _pricePerTokenInWei
        });
    }

    // Returns an array of all of the Stages for a given Project id
    function allStages(uint256 _projectId) public view returns (Stage[] memory) {
        ProjectConfig storage config = projectConfig[_projectId];

        // i.e. 2 stages, length = 2
        uint8 length = config.stagesCount;
        Stage[] memory stages = new Stage[](length);

        for(uint8 i; i < length;) {
            // Add 1 to `i` here because Stages start at 1; 0 is the null state
            stages[i] = getStage(_projectId, i + 1);
            unchecked { ++i; }
        }

        return stages;
    }

    function getStage(uint256 _productId, uint8 _stageId) public view returns (Stage memory) {
        return projectConfig[_productId].stages[_stageId];
    }

    // Returns the current Stage in progress for a mint. If a Project is finished, it will return an empty Stage
    function currentStage(uint256 _projectId) public view returns (Stage memory) {
        Stage[] memory _stages = allStages(_projectId); // 0 indexed
        for(uint i; i < _stages.length;) {
            if (block.timestamp > _stages[i].stageStartTime && block.timestamp <= _stages[i].stageEndTime) {
                return _stages[i];
            }

            unchecked { ++i; }
        }

        Stage memory empty;
        return empty;
    }

    // Returns the current Stage's id
    function currentStageId(uint256 _projectId) public view returns (uint8) {
        return currentStage(_projectId).id;
    }

    // Returns the current Stage price in wei
    function currentStagePrice(uint256  _projectId) public view returns (uint256) {
        return currentStage(_projectId).pricePerTokenInWei;
    }

    // Returns the next Stage as a struct
    function nextStage(uint256  _projectId) public view returns (Stage memory) {
        ProjectConfig storage config = projectConfig[_projectId];
        Stage memory _currentStage = currentStage(_projectId);

        if (_currentStage.id == 0) {
            return _currentStage;
        } else if (config.stages[config.currentStageId + 1].id != 0) {
            return config.stages[config.currentStageId + 1];
        } else {
            Stage memory empty;
            return empty;
        }
    }

    // Returns the next Stage's price in wei
    function nextStagePrice(uint256 _projectId) external view returns (uint256) {
        return nextStage(_projectId).pricePerTokenInWei;
    }

    // Returns the next stage start time as a Unix timestamp in seconds
    function startingTimeOfNextStage(uint256 _projectId) external view returns (uint256) {
        return nextStage(_projectId).stageStartTime;
    }

    /**
     * @notice Process proof for an address. Returns Merkle root. Included to
     * enable users to easily verify a proof's validity.
     * @param _proof Merkle proof for address.
     * @param _address Address to process.
     * @return merkleRoot Merkle root for `_address` and `_proof`
     */
    function processProofForAddress(
        bytes32[] calldata _proof,
        address _address
    ) external pure returns (bytes32) {
        return _proof.processProofCalldata(hashAddress(_address));
    }

    /**
     * @notice Gets if price of token is configured, price of minting a
     * token on project `_projectId`, and currency symbol and address to be
     * used as payment. Supersedes any core contract price information.
     * @param _projectId Project ID to get price information for.
     * @return isConfigured true only if token price has been configured on
     * this minter
     * @return tokenPriceInWei current price of token on this minter - invalid
     * if price has not yet been configured
     * @return currencySymbol currency symbol for purchases of project on this
     * minter. This minter always returns "ETH"
     * @return currencyAddress currency address for purchases of project on
     * this minter. This minter always returns null address, reserved for ether
     */
    function getPriceInfo(uint256 _projectId) external view returns (
        bool isConfigured,
        uint256 tokenPriceInWei,
        string memory currencySymbol,
        address currencyAddress
    ) {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        isConfigured = _projectConfig.priceIsConfigured;
        tokenPriceInWei = currentStagePrice(_projectId);
        currencySymbol = "ETH";
        currencyAddress = address(0);
    }

    function updateSystemAddress(uint256 _projectId, address _address) external onlyArtist(_projectId) {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        _projectConfig.systemAddress = _address;
    }

    /// @notice Checks if the private key that singed the nonce matches the system address of the contract
    function isValidSignature(
        address _systemAddress,
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (bool) {
        // Artist Owner should call `updateSystemAddress` with
        // the address corresponding to the private key that
        // signs the data payload from the backend being fed into the mint function.
        require(_systemAddress != address(0), "Missing System Address");

        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == _systemAddress;
    }

    /*//////////////////////////////////////////////////////////////
                              UNSUPPORTED
    //////////////////////////////////////////////////////////////*/

    /**
    * @notice Inactive function - requires Merkle proof to purchase.
    */
    function purchase(uint256) external payable returns (uint256) {
        revert ActionNotSupported();
    }

    /**
    * @notice Inactive function - requires Merkle proof to purchase.
    */
    function purchaseTo(address, uint256) public payable returns (uint256) {
        revert ActionNotSupported();
    }

    /**
    * @notice Inactive function
    */
    function purchase(uint256, bytes32[] calldata) external payable returns (uint256) {
        revert ActionNotSupported();
    }

    /**
    * @notice Inactive function
    */
    function purchaseTo(address, uint256, bytes32[] calldata) external payable returns (uint256) {
        revert ActionNotSupported();
    }

    /**
    * @notice Inactive function
    */
    function togglePurchaseToDisabled(uint256) external pure {
        revert ActionNotSupported();
    }

}