//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IPoolDeployer {
    function fungibleOriginationPoolImplementation()
        external
        view
        returns (address);

    function deployFungibleOriginationPool(address _proxyAdmin)
        external
        returns (address pool);

    function setFungibleOriginationPoolImplementation(
        address _fungibleOriginationPoolImplementation
    ) external;

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}