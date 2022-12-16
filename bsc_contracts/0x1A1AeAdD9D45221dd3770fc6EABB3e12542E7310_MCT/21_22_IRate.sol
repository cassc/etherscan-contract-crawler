// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRate {

    function rates(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    function isActive(bytes32 _rateHash) external view returns (bool);

    function createRate(bytes32 _rateHash, uint256 _price, uint256 _singleApy, uint256 _lpApy) external;

    function updateRate(bytes32 _rateHash, uint256 _price, uint256 _singleApy, uint256 _lpApy) external;

    function deleteRate(bytes32 _rateHash) external;

}