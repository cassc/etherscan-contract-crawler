// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

interface IRegistry {
    /* solhint-disable func-name-mixedcase, var-name-mixedcase */
    function get_lp_token(address pool) external returns (address);
}