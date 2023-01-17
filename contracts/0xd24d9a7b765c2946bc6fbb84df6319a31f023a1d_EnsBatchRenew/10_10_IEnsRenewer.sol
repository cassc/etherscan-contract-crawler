// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IEnsRenewer {
    function renew(string calldata _name, uint256 _duration) external payable;

    function rentPrice(
        string calldata _name,
        uint256 _duration
    ) external view returns (uint256);
}