// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVotingPower {

    function setVotingPower(string memory card, uint256 _votingPower) external;

    function getVotingPower(string memory card) external view returns (uint256 _votingPower);

    function setMultiplier(string memory sequenceName, uint256 _multiplier) external;

    function getMultiplier(string memory sequenceName) external view returns(uint256 _multiplier);

    function setDivisor(uint256 _divisor) external;

    function getDivisor() external view returns (uint256 _divisor);

    function setMinimumVotingPower(uint256 power) external;

    function getMinimumVotingPower() external view returns(uint256 _minimumVotingPower);
}