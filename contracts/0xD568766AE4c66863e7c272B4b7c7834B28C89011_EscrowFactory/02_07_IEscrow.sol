// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IEscrow {
    function init(
        address _client,
        address _talent,
        address _resolver,
        uint256 _fee
    ) external payable;

    function refund(uint256 _amount, string memory _note) external;

    function refund(
        address _token,
        uint256 _amount,
        string memory _note
    ) external;

    function deposit(uint256, string memory) external payable;

    function deposit(
        address,
        uint256,
        uint256,
        string memory
    ) external;

    function release(uint256, string memory) external payable;

    function release(
        address _token,
        uint256 _amount,
        string memory
    ) external;

    function balanceOf(address _token) external view returns (uint256);
}