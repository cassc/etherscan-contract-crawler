import "./QuadGovernanceStore.sol";

//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

contract QuadGovernanceStoreV2 is QuadGovernanceStore {

    address[] internal _deletedIssuers;

    mapping(address => bool) internal _preapprovals;

}