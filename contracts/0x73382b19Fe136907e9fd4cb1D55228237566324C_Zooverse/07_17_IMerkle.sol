pragma solidity 0.8.10;

interface IMerkle {
    function leaf(address) external pure returns (bytes32);
    function verify(bytes32 leaf, bytes32[] memory proof) external view returns (bool);
    function setRoot(bytes32 _root) external;
}