// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract ArchOfPeaceEntropy is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface private immutable _coordinator;

    struct VRFRequestParams {
        bytes32 gasLane;
        uint64 subscriptionId;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
    }

    VRFRequestParams private _vrfRequestParams;

    bool private _fulfilling;

    uint256 private _entropy;

    event RandomnessRequested(uint256 requestId);

    constructor(
        address coordinator_,
        bytes32 gasLane_,
        uint64 subscriptionId_
    ) VRFConsumerBaseV2(coordinator_) {
        _coordinator = VRFCoordinatorV2Interface(coordinator_);
        _vrfRequestParams = VRFRequestParams(gasLane_, subscriptionId_, 5, 300000);
    }

    /// @notice Assumes the subscription is set sufficiently funded
    function _requestRandomWord() internal {
        uint256 requestId = _coordinator.requestRandomWords(
            _vrfRequestParams.gasLane,
            _vrfRequestParams.subscriptionId,
            _vrfRequestParams.requestConfirmations,
            _vrfRequestParams.callbackGasLimit,
            1
        );

        _fulfilling = true;

        emit RandomnessRequested(requestId);
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal virtual override {
        _entropy = randomWords[0];

        _fulfilling = false;
    }

    // TODO: cover
    function updateVRFParams(VRFRequestParams calldata newParams) public onlyOwner {
        _vrfRequestParams = newParams;
    }

    function fulfilling() public view returns (bool) {
        return _fulfilling;
    }

    function entropy() public view returns (uint256) {
        return _entropy;
    }
}