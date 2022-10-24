//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface INonRewardPoolDeployer {
    function nonRewardPoolImplementation() external view returns (address);

    function deployNonRewardPool(address _proxyAdmin)
        external
        returns (address pool);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setNonRewardPoolImplementation(address _poolImplementation)
        external;

    function transferOwnership(address newOwner) external;
}