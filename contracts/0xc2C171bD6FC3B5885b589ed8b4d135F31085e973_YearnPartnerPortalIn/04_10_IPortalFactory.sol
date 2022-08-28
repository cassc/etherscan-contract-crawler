/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

import "./IPortalRegistry.sol";

interface IPortalFactory {
    function fee() external view returns (uint256 fee);

    function registry() external view returns (IPortalRegistry registry);
}