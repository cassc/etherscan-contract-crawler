pragma solidity 0.8.12;

interface ICollection {
    function getPrimaryIdentity(address account) external view returns (uint256);
    function getPrimaryIdentityLock(address account) external view returns (uint256);
}