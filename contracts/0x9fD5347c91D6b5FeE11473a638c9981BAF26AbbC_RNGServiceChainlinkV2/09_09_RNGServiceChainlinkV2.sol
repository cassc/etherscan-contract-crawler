// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "./interfaces/IRNGServiceChainlinkV2.sol";

import "./chainlink/VRFConsumerBaseV2.sol";

import "../owner-manager/Manageable.sol";

contract RNGServiceChainlinkV2 is
    IRNGServiceChainlinkV2,
    VRFConsumerBaseV2,
    Manageable
{
    /* ========== Global Variables ========== */

    /// @dev Reference to the VRFCoordinatorV2 deployed contract
    VRFCoordinatorV2Interface internal vrfCoordinator;

    /// @dev A counter for the number of requests made used for request IDs
    uint32 internal requestCounter;

    /// @dev Chainlink VRF subscription ID
    uint64 internal subscriptionId;

    /// @dev Hash of the public key used to verify the VRF proof
    bytes32 internal keyHash;

    /// @dev A lists of random numbers from past requests mapped by internal
    ///      request ID
    mapping(uint32 => uint256[]) internal randomNumbers;

    /// @dev A list of flags that indicates if internal request ID is completed
    ///      or not
    mapping(uint32 => bool) internal requestCompleted;

    /// @dev A list of blocks to be locked at based on past requests mapped by
    ///      request ID
    mapping(uint32 => uint32) internal requestLockBlock;

    /// @dev A mapping from Chainlink request IDs to internal request IDs
    mapping(uint256 => uint32) internal chainlinkRequestIds;

    /* ============ Events ============ */

    /**
     * @notice Emitted when the Chainlink VRF key hash is set
     * @param keyHash Chainlink VRF key hash
     */
    event KeyHashSet(bytes32 keyHash);

    /**
     * @notice Emitted when the Chainlink VRF subscription ID is set
     * @param subscriptionId Chainlink VRF subscription ID
     */
    event SubscriptionIdSet(uint64 subscriptionId);

    /**
     * @notice Emitted when the Chainlink VRF Coordinator address is set
     * @param vrfCoordinator Address of the VRF Coordinator
     */
    event VrfCoordinatorSet(VRFCoordinatorV2Interface indexed vrfCoordinator);

    /* ============ Constructor ============ */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ============ Initialize ============ */

    /**
     * @notice Constructs RNGServiceChainlinkV2 with passed parameters.
     * @param _owner Owner of the contract
     * @param _vrfCoordinator Address of the VRF Coordinator
     * @param _subscriptionId Chainlink VRF subscription ID
     * @param _keyHash Hash of the public key used to verify the VRF proof
     */
    function initialize(
        address _owner,
        VRFCoordinatorV2Interface _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) external virtual initializer {
        __RNGServiceChainlinkV2_init(
            _owner,
            _vrfCoordinator,
            _subscriptionId,
            _keyHash
        );
    }

    /* ============== External ============== */

    /// @inheritdoc IRNGService
    function requestRandomNumbers(
        uint32 numWords
    )
        external
        override
        onlyManager
        returns (uint32 requestId, uint32 lockBlock)
    {
        (uint16 minRequestConfirmations, uint32 maxGasLimit, ) = vrfCoordinator
            .getRequestConfig();
        uint256 _vrfRequestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            minRequestConfirmations,
            maxGasLimit,
            numWords
        );

        ++requestCounter;

        uint32 _requestCounter = requestCounter;

        requestId = _requestCounter;
        lockBlock = uint32(block.number);

        chainlinkRequestIds[_vrfRequestId] = _requestCounter;
        requestLockBlock[_requestCounter] = lockBlock;

        emit RandomNumbersRequested(
            _requestCounter,
            _vrfRequestId,
            numWords,
            msg.sender
        );
    }

    /// @inheritdoc IRNGService
    function isRequestCompleted(
        uint32 _internalRequestId
    ) external view returns (bool isCompleted) {
        return requestCompleted[_internalRequestId];
    }

    /// @inheritdoc IRNGService
    function getRandomNumbers(
        uint32 _internalRequestId
    ) external view returns (uint256[] memory numbers) {
        return randomNumbers[_internalRequestId];
    }

    /// @inheritdoc IRNGService
    function getLastRequestId() external view returns (uint32 requestId) {
        return requestCounter;
    }

    /// @inheritdoc IRNGService
    function getRequestFee()
        external
        pure
        returns (address feeToken, uint256 requestFee)
    {
        return (address(0), 0);
    }

    /// @inheritdoc IRNGServiceChainlinkV2
    function getKeyHash() external view returns (bytes32) {
        return keyHash;
    }

    /// @inheritdoc IRNGServiceChainlinkV2
    function getSubscriptionId() external view returns (uint64) {
        return subscriptionId;
    }

    /// @inheritdoc IRNGServiceChainlinkV2
    function getVrfCoordinator()
        external
        view
        returns (VRFCoordinatorV2Interface)
    {
        return vrfCoordinator;
    }

    /// @inheritdoc IRNGServiceChainlinkV2
    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        _setSubscriptionId(_subscriptionId);
    }

    /// @inheritdoc IRNGServiceChainlinkV2
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        _setKeyHash(_keyHash);
    }

    /* ============== Internal ============== */

    /**
     * @notice Callback function called by VRF Coordinator
     * @dev The VRF Coordinator will only call it once it has verified the proof
     *      associated with the randomness.
     * @param _vrfRequestId Chainlink VRF request ID
     * @param _randomWords Chainlink VRF array of random words (numbers)
     */
    function fulfillRandomWords(
        uint256 _vrfRequestId,
        uint256[] memory _randomWords
    ) internal override {
        uint32 _internalRequestId = chainlinkRequestIds[_vrfRequestId];

        require(
            _internalRequestId > 0,
            "RNGServiceChainlinkV2/requestId-incorrect"
        );

        randomNumbers[_internalRequestId] = _randomWords;
        requestCompleted[_internalRequestId] = true;

        emit RandomNumbersCompleted(_internalRequestId, _randomWords);
    }

    /**
     * @notice Set Chainlink VRF Coordinator contract address.
     * @param _vrfCoordinator Chainlink VRF Coordinator contract address
     */
    function _setVRFCoordinator(
        VRFCoordinatorV2Interface _vrfCoordinator
    ) internal {
        require(
            address(_vrfCoordinator) != address(0),
            "RNGServiceChainlinkV2/vrf-coordinator-not-zero-addr"
        );

        vrfCoordinator = _vrfCoordinator;

        emit VrfCoordinatorSet(_vrfCoordinator);
    }

    /**
     * @notice Set Chainlink VRF subscription ID associated with this contract.
     * @param _subscriptionId Chainlink VRF subscription ID
     */
    function _setSubscriptionId(uint64 _subscriptionId) internal {
        require(
            _subscriptionId > 0,
            "RNGServiceChainlinkV2/subscriptionId-gt-zero"
        );

        subscriptionId = _subscriptionId;

        emit SubscriptionIdSet(_subscriptionId);
    }

    /**
     * @notice Set Chainlink VRF key hash.
     * @param _keyHash Chainlink VRF key hash
     */
    function _setKeyHash(bytes32 _keyHash) internal {
        require(
            _keyHash != bytes32(0),
            "RNGServiceChainlinkV2/keyHash-not-empty"
        );

        keyHash = _keyHash;

        emit KeyHashSet(_keyHash);
    }

    /**
     * @notice Constructs RNGServiceChainlinkV2 with passed parameters.
     * @param _owner Owner of the contract
     * @param _vrfCoordinator Address of the VRF Coordinator
     * @param _subscriptionId Chainlink VRF subscription ID
     * @param _keyHash Hash of the public key used to verify the VRF proof
     */
    function __RNGServiceChainlinkV2_init(
        address _owner,
        VRFCoordinatorV2Interface _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) internal onlyInitializing {
        __Manageable_init_unchained(_owner);
        __VRFConsumerBaseV2_init_unchained(address(_vrfCoordinator));
        __RNGServiceChainlinkV2_init_unchained(
            _vrfCoordinator,
            _subscriptionId,
            _keyHash
        );
    }

    /**
     * @notice Unchained initialization of RNGServiceChainlinkV2 contract.
     * @param _vrfCoordinator Address of the VRF Coordinator
     * @param _subscriptionId Chainlink VRF subscription ID
     * @param _keyHash Hash of the public key used to verify the VRF proof
     */
    function __RNGServiceChainlinkV2_init_unchained(
        VRFCoordinatorV2Interface _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) internal onlyInitializing {
        _setVRFCoordinator(_vrfCoordinator);
        _setSubscriptionId(_subscriptionId);
        _setKeyHash(_keyHash);
    }
}