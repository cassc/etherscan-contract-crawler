// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IAddressProvider {
    /* solhint-disable func-name-mixedcase, var-name-mixedcase */
    function get_registry() external view returns (address);
}