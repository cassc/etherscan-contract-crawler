// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../../../access/ownable/OwnableInternal.sol";

import "./MetadataAdminInternal.sol";
import "./MetadataStorage.sol";
import "./IMetadataAdmin.sol";

/**
 * @title Metadata - Admin - Ownable
 * @notice Allows diamond owner to change name and symbol, or freeze them forever.
 *
 * @custom:type eip-2535-facet
 * @custom:category Tokens
 * @custom:peer-dependencies IMetadata
 * @custom:provides-interfaces IMetadataAdmin
 */
contract MetadataOwnable is IMetadataAdmin, MetadataAdminInternal, OwnableInternal {
    function setName(string calldata name) external virtual override onlyOwner {
        _setName(name);
    }

    function setSymbol(string calldata symbol) external virtual override onlyOwner {
        _setSymbol(symbol);
    }

    function lockNameAndSymbol() external virtual override onlyOwner {
        _lockNameAndSymbol();
    }
}