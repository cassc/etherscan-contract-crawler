// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBridgeToken {
    function rules() external view returns (uint256[] memory, uint256[] memory);

    function rule(uint256 ruleId) external view returns (uint256, uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function transfer(address _to, uint256 _value) external returns (bool);

    function owner() external view returns (address);
}