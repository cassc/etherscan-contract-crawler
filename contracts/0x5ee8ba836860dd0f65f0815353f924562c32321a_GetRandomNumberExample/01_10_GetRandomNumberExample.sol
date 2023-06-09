// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {GeneralRandcastConsumerBase, BasicRandcastConsumerBase} from "../GeneralRandcastConsumerBase.sol";

contract GetRandomNumberExample is GeneralRandcastConsumerBase {
    /* requestId -> randomness */
    mapping(bytes32 => uint256) public randomResults;
    uint256[] public randomnessResults;

    // solhint-disable-next-line no-empty-blocks
    constructor(address adapter) BasicRandcastConsumerBase(adapter) {}

    /**
     * Requests randomness
     */
    function getRandomNumber() external returns (bytes32) {
        bytes memory params;
        return _requestRandomness(RequestType.Randomness, params);
    }

    /**
     * Callback function used by Randcast Adapter
     */
    function _fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResults[requestId] = randomness;
        randomnessResults.push(randomness);
    }

    function lengthOfRandomnessResults() public view returns (uint256) {
        return randomnessResults.length;
    }

    function lastRandomnessResult() public view returns (uint256) {
        return randomnessResults[randomnessResults.length - 1];
    }
}