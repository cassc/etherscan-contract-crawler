// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721CheckpointableUpgradeable {

    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    function votesToDelegate(address delegator) external view returns (uint96);

    function delegates(address delegator) external view returns (address);

    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
 
    function getCurrentVotes(address account) external view returns (uint96);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
}