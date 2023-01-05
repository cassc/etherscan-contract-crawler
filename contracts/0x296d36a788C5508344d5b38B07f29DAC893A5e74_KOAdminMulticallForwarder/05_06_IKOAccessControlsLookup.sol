// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IKOAccessControlsLookup {

    function hasAdminRole(address _address) external view returns (bool);

    function hasContractRole(address _address) external view returns (bool);

    function hasContractOrAdminRole(address _address) external view returns (bool);

}