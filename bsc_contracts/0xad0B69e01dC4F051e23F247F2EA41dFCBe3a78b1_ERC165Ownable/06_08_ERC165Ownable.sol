// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "../access/ownable/OwnableInternal.sol";
import "./ERC165Storage.sol";
import "./IERC165Admin.sol";

/**
 * @title ERC165 - Admin - Ownable
 * @notice Standard EIP-165 management facet using Ownable extension for access control.
 *
 * @custom:type eip-2535-facet
 * @custom:category Diamonds
 * @custom:peer-dependencies IERC165
 * @custom:provides-interfaces IERC165Admin
 */
contract ERC165Ownable is IERC165Admin, OwnableInternal {
    using ERC165Storage for ERC165Storage.Layout;

    /**
     * @param interfaceIds list of interface id to set as supported
     * @param interfaceIdsToRemove list of interface id to unset as supported
     */
    function setERC165(bytes4[] calldata interfaceIds, bytes4[] calldata interfaceIdsToRemove) public onlyOwner {
        ERC165Storage.Layout storage l = ERC165Storage.layout();

        l.supportedInterfaces[type(IERC165).interfaceId] = true;

        for (uint256 i = 0; i < interfaceIds.length; i++) {
            l.supportedInterfaces[interfaceIds[i]] = true;
        }

        for (uint256 i = 0; i < interfaceIdsToRemove.length; i++) {
            l.supportedInterfaces[interfaceIdsToRemove[i]] = false;
        }
    }
}