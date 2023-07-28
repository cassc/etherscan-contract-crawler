// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "./Location.sol";

interface IGraniphCountries {
    function generateLocation(uint256 cityId) external view returns (Location memory);
}