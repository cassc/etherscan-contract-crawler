// SPDX-License-Identifier: Apache-2.0
// Author: Zainan Victor Zhou <[email protected]>
// Open source repo: http://zzn.li/ercref

pragma solidity >=0.7.0 <0.9.0;

/// The EIP-165 identifier of this interface is 0x4ba43d48
interface IERC_COMMIT_CORE {
    function commit(bytes32 _commitment) payable external;
}

interface IERC_COMMIT_GENERAL {
    event Commit(
        uint256 indexed _time,
        address indexed _from,
        bytes32 indexed _commitment,
        bytes _extraData);
    function commitFrom(
        address _from,
        bytes32 _commitment,
        bytes calldata _extraData)
    payable external returns(uint256);
}