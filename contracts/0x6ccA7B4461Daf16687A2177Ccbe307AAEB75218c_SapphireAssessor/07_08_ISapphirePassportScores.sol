// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {SapphireTypes} from "./SapphireTypes.sol";

interface ISapphirePassportScores {
    function currentEpoch() external view returns (uint256);

    function rootsHistory(uint256 _epoch) external view returns (bytes32, uint256);

    function isPaused() external view returns (bool);

    function merkleRootDelayDuration() external view returns (uint256);

    function merkleRootUpdater() external view returns (address);
    
    function pauseOperator() external view returns (address);

    /**
     * Reverts if proof is invalid
     */
    function verify(SapphireTypes.ScoreProof calldata _proof) external view returns(bool);
    
    function updateMerkleRoot(bytes32 _newRoot) external;

    function setMerkleRootUpdater(address _merkleRootUpdater) external;

    function setMerkleRootDelay(uint256 _delay) external;

    function setPause(bool _status) external;
}