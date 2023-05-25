pragma solidity 0.8.11;

interface IMerkle {
    function leaf(address user, uint256 count) external pure returns (bytes32);
    function verify(bytes32 leaf, bytes32[] memory proof) external view returns (bool);
    function isPermitted(address account, uint256 count, bytes32[] memory proof) external view returns (bool);
    function setRoot(bytes32 _root) external;
}