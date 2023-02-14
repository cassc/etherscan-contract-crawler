pragma solidity >=0.8.4;

interface IETHBulkRegistrar {
    function bulkRentPrice(string[] calldata names, uint256 duration) external view returns (uint256 total);
    
    function bulkRegister(string[] calldata names, address owner, uint duration, bytes32 secret) external payable;

    function bulkCommit(bytes32[] calldata commitments) external;

    function bulkMakeCommitment(string[] calldata name, address owner, bytes32 secret) external view returns (bytes32[] memory commitments);

    function commitment(bytes32 commit) external view returns(uint256);

}