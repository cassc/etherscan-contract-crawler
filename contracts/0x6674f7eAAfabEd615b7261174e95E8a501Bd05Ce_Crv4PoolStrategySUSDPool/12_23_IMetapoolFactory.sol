// SPDX-License-Identifier: MIT

/* solhint-disable func-name-mixedcase*/
pragma solidity 0.8.9;

interface IMetapoolFactory {
    function get_underlying_coins(address _pool) external view returns (address[8] memory _coins);

    function get_underlying_decimals(address _pool) external view returns (uint256[8] memory _decimals);
}