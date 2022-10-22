// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../../metatx/ERC2771ContextInternal.sol";
import "./AccessControl.sol";

/**
 * @title Roles - with meta-transactions
 * @notice Role-based access control with meta-transactions enabled (mainly for grantRole, revokeRole, renounceRole)
 *
 * @custom:type eip-2535-facet
 * @custom:category Access
 * @custom:provides-interfaces IAccessControl
 */
contract AccessControlERC2771 is ERC2771ContextInternal, AccessControl {
    function _msgSender() internal view virtual override(Context, ERC2771ContextInternal) returns (address) {
        return ERC2771ContextInternal._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771ContextInternal) returns (bytes calldata) {
        return ERC2771ContextInternal._msgData();
    }
}