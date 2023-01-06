// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMintValidator {
    function validate(uint256 _amount, uint256 _maxAmount, uint256 _value, bytes32[] calldata _merkleProof) external;
    function maxAmount() external view returns(uint256); // 1人当たりの最大発行点数
}