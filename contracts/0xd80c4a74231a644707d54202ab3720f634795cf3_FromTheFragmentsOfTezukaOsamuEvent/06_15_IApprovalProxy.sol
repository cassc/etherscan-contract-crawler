// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IApprovalProxy {
    function setApprovalForAll(
        address _owner,
        address _spender,
        bool _approved
    ) external;

    function isApprovedForAll(
        address _owner,
        address _spender,
        bool _original
    ) external view returns (bool);
}