pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RandomNumberConsumer is VRFConsumerBase, Ownable {

    event FulfilledVRF(bytes32 indexed requestId, uint256 indexed randomness);

    bytes32 internal keyHash;
    uint256 internal fee;

    mapping(bytes32 => uint256) public randomResult;
    mapping(address => bool) public approvedRandomnessRequesters;

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint _fee
    )
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _link  // LINK Token
        ) public
    {
        keyHash = _keyHash;
        fee = _fee;
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(approvedRandomnessRequesters[msg.sender], "RandomNumberConsumer::getRandomNumber: msg.sender is not an approved requester of randomness");
        require(LINK.balanceOf(address(this)) >= fee, "RandomNumberConsumer::getRandomNumber: Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    function setRandomnessRequesterApproval(address _requester, bool _approvalStatus) public onlyOwner {
        approvedRandomnessRequesters[_requester] = _approvalStatus;
    }

    /**
     * Reads fulfilled randomness for a given request ID
     */
    function readFulfilledRandomness(bytes32 requestId) public view returns (uint256) {
        return randomResult[requestId];
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult[requestId] = randomness;
        emit FulfilledVRF(requestId, randomness);
    }

    function withdrawLink(address _destination) external onlyOwner returns (bool) {
      LINK.transferFrom(address(this), _destination, LINK.balanceOf(address(this)));
    }
}