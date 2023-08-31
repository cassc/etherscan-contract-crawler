// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAddressProvider {
    function factory() external view returns (address);
    function paymentTokenRegistry() external view returns (address);
    function treasury() external view returns (address);
    function metadataProvider() external view returns (address);
    function accessController() external view returns (address);
}