// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITieredSalesInternal.sol";

interface ITieredSalesAdmin {
    function configureTiering(uint256, ITieredSalesInternal.Tier calldata) external;

    function configureTiering(uint256[] calldata, ITieredSalesInternal.Tier[] calldata) external;
}