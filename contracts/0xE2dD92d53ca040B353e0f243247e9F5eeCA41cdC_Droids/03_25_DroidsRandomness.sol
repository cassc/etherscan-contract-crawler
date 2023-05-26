// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "fpe-map/contracts/FPEMap.sol";

contract DroidsRandomness is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface private immutable _coordinator;

    struct VRFRequestParams {
        bytes32 keyHash;
        uint64 subscriptionId;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
    }

    VRFRequestParams private _vrfRequestParams;

    bool private _fulfilling = false;
    bool private _fulfilled = false;
    uint256 private _seed;

    event RandomnessRequested(uint256 requestId);
    event RandomnessFullfilled(uint256 indexed requestId, uint256 indexed result);

    constructor(
        address coordinator_,
        bytes32 keyHash_,
        uint64 subscriptionId_
    ) VRFConsumerBaseV2(coordinator_) {
        _coordinator = VRFCoordinatorV2Interface(coordinator_);
        _vrfRequestParams = VRFRequestParams(
            keyHash_,
            subscriptionId_,
            5,
            300000
        );
    }

    function _requestRandomWord() internal {
        uint256 requestId = _coordinator.requestRandomWords(
            _vrfRequestParams.keyHash,
            _vrfRequestParams.subscriptionId,
            _vrfRequestParams.requestConfirmations,
            _vrfRequestParams.callbackGasLimit,
            1
        );
        _fulfilling = true;

        emit RandomnessRequested(requestId);
    }

    function seed() public view returns (uint256) {
        return _seed;
    }

    function randomnessFulfilled() public view returns (bool) {
        return _fulfilled;
    }

    function fulfilling() public view returns (bool) {
        return _fulfilling;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal virtual override {
        _seed = randomWords[0];
        _fulfilling = false;
        _fulfilled = true;
        emit RandomnessFullfilled(requestId,_seed);
    }

    function updateVRFParams(
        VRFRequestParams calldata newParams
    ) public onlyOwner {
        _vrfRequestParams = newParams;
    }

    /**
     * @notice Reveals the collection when the seed is returned from chainlink
     * @dev Only callable by the owner
     * @dev seed will be fed to fpe-map to generate the random metadata ids
     */
    function reveal() public onlyOwner {
        require(!randomnessFulfilled(), "Seed is already set");
        require(!fulfilling(), "Seed request is already in progress");
        _requestRandomWord();
    }

}