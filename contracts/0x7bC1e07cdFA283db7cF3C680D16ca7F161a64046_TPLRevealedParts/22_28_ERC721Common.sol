// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

import {WithMeta} from "../WithMeta.sol";
import {WithMinters} from "../WithMinters.sol";
import {WithOperatorFilter} from "../WithOperatorFilter/WithOperatorFilter.sol";

import {IERC721Common} from "./IERC721Common.sol";

/// @title ERC721Common
/// @author dev by @dievardump
/// @notice contains all the goodies that can be added to any implementation of ERC721 (OZ, ERC721A, ...)
///         without needing any implementation specific tweaks
contract ERC721Common is IERC721Common, Ownable, ERC2981, WithMeta, WithMinters, WithOperatorFilter {
    constructor(ERC721CommonConfig memory config) {
        if (config.minters.length > 0) {
            _addMinters(config.minters);
        }

        if (bytes(config.baseURI).length > 0) {
            _setBaseURI(config.baseURI);
        }

        if (bytes(config.contractURI).length > 0) {
            contractURI = config.contractURI;
        }

        if (config.metadataManager != address(0)) {
            metadataManager = config.metadataManager;
        }

        if (config.royaltyReceiver != address(0)) {
            _setDefaultRoyalty(config.royaltyReceiver, config.royaltyFeeNumerator);
        }
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    //// @notice Allows to add minters to this contract
    /// @param newMinters the new minters to add
    function addMinters(address[] calldata newMinters) external onlyOwner {
        _addMinters(newMinters);
    }

    //// @notice Allows to remove minters from this contract
    /// @param oldMinters the old minters to remove
    function removeMinters(address[] calldata oldMinters) external onlyOwner {
        _removeMinters(oldMinters);
    }

    /// @notice Allows owner to update metadataManager
    /// @param newMetadataManager the new address of the third eye
    function setMetadataManager(address newMetadataManager) external onlyOwner {
        metadataManager = newMetadataManager;
    }

    /// @notice Allows owner to update contractURI
    /// @param newContractURI the new contract URI
    function setContractURI(string calldata newContractURI) external onlyOwner {
        contractURI = newContractURI;
    }

    /// @notice allows owner to change the royalties receiver and fees
    /// @param receiver the royalties receiver
    /// @param feeNumerator the fees to ask for; fees are expressed in basis points so 1 == 0.01%, 500 = 5%, 10000 = 100%
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public virtual onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice allows owner to set the collection base URI value
    /// @param newBaseURI the new base URI
    function setBaseURI(string calldata newBaseURI) public onlyOwner {
        _setBaseURI(newBaseURI);
    }

    /// @notice Allows owner to switch on/off the OperatorFilter
    /// @param newIsEnabled the new state
    function setIsOperatorFilterEnabled(bool newIsEnabled) public onlyOwner {
        isOperatorFilterEnabled = newIsEnabled;
    }
}