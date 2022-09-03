// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface IRoyaltyPayee {
    function ownerReleased() external view returns (uint256);
    function ownerBalance() external view returns (uint256);
    function releaseToOwner() external;
    function ownerShare() external view returns (uint256);
    function registryReleased() external view returns (uint256);
    function registryBalance() external view returns (uint256);
    function releaseToRegistry() external;
    function registryShare() external view returns (uint256);
}