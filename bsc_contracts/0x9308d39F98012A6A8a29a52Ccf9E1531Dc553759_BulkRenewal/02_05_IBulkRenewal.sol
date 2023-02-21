// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

interface IBulkRenewal {
    function rentPrice(string[] calldata names, uint duration) external view returns(uint total);

    function rentPrices(string[] calldata names, uint[] calldata durations) external view returns(uint total);

    function renewAll(string[] calldata names, uint duration) external payable;

    function makeBatchCommitmentWithConfig(string[] memory names, address owner, bytes32 secret, address resolver, address addr) view external returns (bytes32[] memory results);
    
    function batchCommit(bytes32[] memory commitments_) external;
    
    function batchRegisterWithConfig(string[] memory names, address owner, uint[] memory durations, bytes32 secret, address resolver, address addr) external payable;

}