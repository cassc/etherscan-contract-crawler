// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16 <0.9.0;

import {
    ERC721A, ERC721ACommon
} from "ethier/contracts/erc721/ERC721ACommon.sol";

import {ERC721ATransferRestrictedBase} from
    "./ERC721ATransferRestrictedBase.sol";

/**
 * @notice Extension of ERC721 transfer restrictions with manual restriction
 * setter.
 */
contract ERC721ATransferRestricted is ERC721ATransferRestrictedBase {
    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The current restrictions.
     */
    TransferRestriction internal _transferRestriction;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(
        string memory name_,
        string memory symbol_,
        address payable royaltiesReceiver_,
        uint96 royaltyBasisPoints_
    )
        ERC721ATransferRestrictedBase(
            name_,
            symbol_,
            royaltiesReceiver_,
            royaltyBasisPoints_
        )
    {}

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Sets the transfer restrictions.
     * @dev Only callable by the contract owner.
     */
    function setTransferRestriction(TransferRestriction restriction)
        public
        onlyOwner
    {
        _transferRestriction = restriction;
    }

    /**
     * @notice Returns the stored transfer restrictions.
     */
    function transferRestriction()
        public
        view
        virtual
        override
        returns (TransferRestriction)
    {
        return _transferRestriction;
    }

    /**
     * @notice Modifier that allows functions to bypass the transfer
     * restriction.
     */
    modifier bypassTransferRestriction() {
        TransferRestriction before = _transferRestriction;
        _transferRestriction =
            ERC721ATransferRestrictedBase.TransferRestriction.None;
        _;
        _transferRestriction = before;
    }
}