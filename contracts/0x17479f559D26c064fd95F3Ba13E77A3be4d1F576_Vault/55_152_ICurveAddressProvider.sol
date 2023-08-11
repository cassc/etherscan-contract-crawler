// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;

interface ICurveAddressProvider {
    // solhint-disable-next-line func-name-mixedcase
    function get_registry() external view returns (address);
}