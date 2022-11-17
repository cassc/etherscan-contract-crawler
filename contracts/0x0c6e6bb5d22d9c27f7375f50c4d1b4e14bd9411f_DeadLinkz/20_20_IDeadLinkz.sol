// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC721AUpgradeable} from "@erc721a-upgradable/IERC721AUpgradeable.sol";

interface IDeadLinkz is IERC721AUpgradeable {
    function mint(uint256 quantity, bytes calldata signature) external payable;
}