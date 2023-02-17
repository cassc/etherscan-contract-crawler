// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title RoyaltySplitterProxy
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice ERC1967 Delegation proxy contract for RoyaltySplitter.
 */
contract RoyaltySplitterProxy is ERC1967Proxy {
    constructor(address _implementation, bytes memory _data)
        ERC1967Proxy(_implementation, _data)
    {}
}