// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173 } from "../IERC173.sol";
import { OwnableController } from "./OwnableController.sol";
import { ProxyUpgradableController } from "../../proxy/upgradable/ProxyUpgradableController.sol";

/**
 * @title ERC173 ownership access control implementation
 * @dev Note: Upgradable implementation
 */
abstract contract OwnableProxy is IERC173, OwnableController, ProxyUpgradableController {
    /**
     * @inheritdoc IERC173
     */
    function owner() external virtual upgradable returns (address) {
        return owner_();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address newOwner) external virtual upgradable onlyOwner {
        transferOwnership_(newOwner);
    }
}