// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/// Imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title Contract for generating random numbers
contract VRFv2Consumer is VRFConsumerBaseV2 {

    /// Variables
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 _s_subscriptionId;       // Your subscription ID (issued on the chanlink website, and you need to approve the address of this contract on the site).
    address _vrfCoordinator;        // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 _keyHash;               // see https://docs.chain.link/docs/vrf-contracts/#configurations
    uint32 _callbackGasLimit;       // Storing each word costs about 20,000 gas, so 100,000 is a safe default for this example contract
    uint16 _requestConfirmations;   // The default is 3, but you can set this higher.
    uint32 _numWords;               // Count random values in one request.
    uint256[] public randomNums;    // Array to store generated numbers
    uint256 public s_requestId;     // requestId - Variable for internal work
    address _owner;                 // Variable to store owner address

    /// Constructor
    constructor(uint64 subscriptionId, address vrfCoordinator, bytes32 keyHash, uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        _owner = msg.sender;
        _s_subscriptionId = subscriptionId;
        _vrfCoordinator = vrfCoordinator;
        _keyHash = keyHash;
        _callbackGasLimit = callbackGasLimit;
        _requestConfirmations = requestConfirmations;
        _numWords = numWords;
    }

    /// @notice Getting owner address
    function getOwner() external view returns(address){
        return _owner;
    }
    /// @notice Chainge owner address
    /// @param owner - new owner address
    function setOwner(address owner) external onlyOwner{
        _owner = owner;
    }

    /// @notice Request for getting new random numbers
    /// to update the data, you need to wait about 2-3 minutes after the completion of the transaction
    function requestRandomWords() external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            _keyHash,
            _s_subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            _numWords
        );
    }

    /// Function for internal work
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        randomNums = randomWords;
    }

    /// Modifier to prohibit the launch of functions for everyone except the owner
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
}