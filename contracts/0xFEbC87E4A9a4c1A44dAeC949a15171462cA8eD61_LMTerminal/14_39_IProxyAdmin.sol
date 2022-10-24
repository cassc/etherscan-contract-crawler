// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IProxyAdmin {
    function addProxyAdmin(address proxy, address admin) external;

    function changeProxyAdmin(address proxy, address newAdmin) external;

    function getProxyAdmin(address proxy) external view returns (address);

    function getProxyImplementation(address proxy)
        external
        view
        returns (address);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function upgrade(address proxy, address implementation) external;
}