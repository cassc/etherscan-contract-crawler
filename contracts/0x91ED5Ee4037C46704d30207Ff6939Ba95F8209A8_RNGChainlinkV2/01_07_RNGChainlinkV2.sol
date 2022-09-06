// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RNGChainlinkV2Interface} from "../interfaces/RNGChainlinkV2Interface.sol";

contract RNGChainlinkV2 is RNGChainlinkV2Interface, VRFConsumerBaseV2, Ownable {
    /* ============ Global Variables ============ */

    address public s_manager;

    /// @dev Reference to the VRFCoordinatorV2 deployed contract
    VRFCoordinatorV2Interface internal vrfCoordinator;

    /// @dev A counter for the number of requests made used for request ids
    uint32 internal requestCounter;

    /// @dev Chainlink VRF subscription id
    uint64 internal subscriptionId;

    /// @dev Hash of the public key used to verify the VRF proof
    bytes32 internal keyHash;

    /// @dev A list of random numbers from past requests mapped by request id
    mapping(uint32 => uint256) internal randomNumbers;

    /// @dev A list of blocks to be locked at based on past requests mapped by request id
    mapping(uint32 => uint32) internal requestLockBlock;

    /// @dev A mapping from Chainlink request ids to internal request ids
    mapping(uint256 => uint32) internal chainlinkRequestIds;

    /* ============ Events ============ */

    /**
     * @notice Emitted when the Chainlink VRF keyHash is set
     * @param keyHash Chainlink VRF keyHash
     */
    event KeyHashSet(bytes32 keyHash);

    /**
     * @notice Emitted when the Chainlink VRF subscription id is set
     * @param subscriptionId Chainlink VRF subscription id
     */
    event SubscriptionIdSet(uint64 subscriptionId);

    /**
     * @notice Emitted when the Chainlink VRF Coordinator address is set
     * @param vrfCoordinator Address of the VRF Coordinator
     */
    event VrfCoordinatorSet(VRFCoordinatorV2Interface indexed vrfCoordinator);

    /* ============ Constructor ============ */

    /**
     * @notice Constructor of the contract
     * @param _vrfCoordinator Address of the VRF Coordinator
     * @param _subscriptionId Chainlink VRF subscription id
     * @param _keyHash Hash of the public key used to verify the VRF proof
     */
    constructor(
        VRFCoordinatorV2Interface _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(address(_vrfCoordinator)) {
        _setVRFCoordinator(_vrfCoordinator);
        _setSubscriptionId(_subscriptionId);
        _setKeyhash(_keyHash);
    }

    modifier onlyManager() {
        require(
            msg.sender == s_manager,
            "Manager: Only manager contract can call this function"
        );
        _;
    }

    /* ============ External Functions ============ */

    function requestRandomNumber()
        external
        override
        returns (uint32 requestId, uint32 lockBlock)
    {
        uint256 _vrfRequestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            3,
            1000000,
            1
        );

        requestCounter++;
        uint32 _requestCounter = requestCounter;

        requestId = _requestCounter;
        chainlinkRequestIds[_vrfRequestId] = _requestCounter;

        lockBlock = uint32(block.number);
        requestLockBlock[_requestCounter] = lockBlock;

        emit RandomNumberRequested(_requestCounter, msg.sender);
    }

    function isRequestComplete(uint32 _internalRequestId)
        external
        view
        override
        returns (bool isCompleted)
    {
        return randomNumbers[_internalRequestId] != 0;
    }

    function randomNumber(uint32 _internalRequestId)
        external
        view
        override
        returns (uint256 randomNum)
    {
        return randomNumbers[_internalRequestId];
    }

    function getLastRequestId()
        external
        view
        override
        returns (uint32 requestId)
    {
        return requestCounter;
    }

    function getRequestFee()
        external
        pure
        override
        returns (address feeToken, uint256 requestFee)
    {
        return (address(0), 0);
    }

    function getKeyHash() external view override returns (bytes32) {
        return keyHash;
    }

    function getSubscriptionId() external view override returns (uint64) {
        return subscriptionId;
    }

    function getVrfCoordinator()
        external
        view
        override
        returns (VRFCoordinatorV2Interface)
    {
        return vrfCoordinator;
    }

    function setSubscriptionId(uint64 _subscriptionId)
        external
        override
        onlyOwner
    {
        _setSubscriptionId(_subscriptionId);
    }

    function setKeyhash(bytes32 _keyHash) external override onlyOwner {
        _setKeyhash(_keyHash);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Callback function called by VRF Coordinator
     * @dev The VRF Coordinator will only call it once it has verified the proof associated with the randomness.
     * @param _vrfRequestId Chainlink VRF request id
     * @param _randomWords Chainlink VRF array of random words
     */
    function fulfillRandomWords(
        uint256 _vrfRequestId,
        uint256[] memory _randomWords
    ) internal override {
        uint32 _internalRequestId = chainlinkRequestIds[_vrfRequestId];
        require(_internalRequestId > 0, "RNGChainLink/requestId-incorrect");

        uint256 _randomNumber = _randomWords[0];
        randomNumbers[_internalRequestId] = _randomNumber;

        emit RandomNumberCompleted(_internalRequestId, _randomNumber);
    }

    /**
     * @notice Set Chainlink VRF coordinator contract address.
     * @param _vrfCoordinator Chainlink VRF coordinator contract address
     */
    function _setVRFCoordinator(VRFCoordinatorV2Interface _vrfCoordinator)
        internal
    {
        require(
            address(_vrfCoordinator) != address(0),
            "RNGChainLink/vrf-not-zero-addr"
        );
        vrfCoordinator = _vrfCoordinator;
        emit VrfCoordinatorSet(_vrfCoordinator);
    }

    /**
     * @notice Set Chainlink VRF subscription id associated with this contract.
     * @param _subscriptionId Chainlink VRF subscription id
     */
    function _setSubscriptionId(uint64 _subscriptionId) internal {
        require(_subscriptionId > 0, "RNGChainLink/subId-gt-zero");
        subscriptionId = _subscriptionId;
        emit SubscriptionIdSet(_subscriptionId);
    }

    function setManager(address _manager) public onlyOwner {
        s_manager = _manager;
    }

    /**
     * @notice Set Chainlink VRF keyHash.
     * @param _keyHash Chainlink VRF keyHash
     */
    function _setKeyhash(bytes32 _keyHash) internal {
        require(_keyHash != bytes32(0), "RNGChainLink/keyHash-not-empty");
        keyHash = _keyHash;
        emit KeyHashSet(_keyHash);
    }
}