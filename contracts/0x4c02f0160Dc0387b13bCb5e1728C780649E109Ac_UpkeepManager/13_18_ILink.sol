// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILink {
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    function approve(address _spender, uint256 _value) external returns (bool);

    function transferAndCall(address _to, uint256 _value, bytes memory _data) external returns (bool success);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool success);
}