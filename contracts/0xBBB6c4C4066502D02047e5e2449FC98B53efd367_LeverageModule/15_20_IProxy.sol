// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IProxy {
    function setAdmin(address newAdmin_) external;

    function setDummyImplementation(address newDummyImplementation_) external;

    function addImplementation(address implementation_, bytes4[] calldata sigs_)
        external;

    function removeImplementation(address implementation_) external;

    function getAdmin() external view returns (address);

    function getDummyImplementation() external view returns (address);

    function getImplementationSigs(address impl_)
        external
        view
        returns (bytes4[] memory);

    function getSigsImplementation(bytes4 sig_) external view returns (address);
}