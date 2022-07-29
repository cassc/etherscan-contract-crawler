// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ICurveRegistry.sol";

interface ICurveAddressProvider {
    function get_registry() external view returns (ICurveRegistry);

    function get_address(uint256 i) external view returns (address);
}