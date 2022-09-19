pragma solidity ^0.8.17;
interface IPositionLockerAlgorithmInstaller {
    /// @dev sets the position lock algorithm
    function setAlgorithm(uint256 positionId) external;
}