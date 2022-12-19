// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface IVault {
    function token() external view returns (address);

    function apiVersion() external view returns (string memory);

    function governance() external view returns (address);

    function initialize(
        address _token,
        address _governance,
        address _rewards,
        string calldata _name,
        string calldata _symbol,
        address _guardian
    ) external;
}