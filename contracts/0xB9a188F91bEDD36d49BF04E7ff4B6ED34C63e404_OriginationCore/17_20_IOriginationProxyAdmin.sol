//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IOriginationProxyAdmin {
    function setProxyAdmin(address proxy, address admin) external;

    function getProxyAdmin(address proxy) external view returns (address);

    function getProxyImplementation(address proxy)
        external
        view
        returns (address);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function transferProxyOwnership(address proxy, address newAdmin) external;

    function upgrade(address proxy, address implementation) external;

    function upgradeAndCall(
        address proxy,
        address implementation,
        bytes memory data
    ) external;
}