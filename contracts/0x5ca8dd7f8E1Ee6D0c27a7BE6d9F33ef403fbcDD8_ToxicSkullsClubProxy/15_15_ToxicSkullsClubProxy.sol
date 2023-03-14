// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title ToxicSkullsClubProxy
 * @custom:website www.toxicskullsclub.io
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice Delegation proxy contract for Toxic Skulls Club.
 */
contract ToxicSkullsClubProxy is ERC1967Proxy {
    constructor(
        address _implementation,
        bytes memory _data
    ) ERC1967Proxy(_implementation, _data) {}

    receive() external payable virtual override {}
}