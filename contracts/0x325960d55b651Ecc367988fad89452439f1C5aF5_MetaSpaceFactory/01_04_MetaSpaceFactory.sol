// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MetaSpace} from "./MetaSpace.sol";
import {IMetaSpace} from "./IMetaSpace.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MarketplaceFactory
 * @notice Manages creation of Marketplaces on MetaPlayerOne. 
 */
contract MetaSpaceFactory is IMetaSpace, Pausable {
    /**
     * @dev emits when new space creates
     */
    constructor (address owner_of_) Pausable(owner_of_) {}

    /**
     * @dev emits when new space creates
     */
    event created(address space_address, string title, address owner_of);

    /**
     * @dev allows you to create new spaces.
     * @param metadata includes all data about space. Such as title, short description, description and link to scene file.
     * @param access includes data about access token. Such as token address and access fee.
     * @param partners list of user addresses and percentages, which this addresses will receive after sales in this Marketplace.
     */ 
    function create(Metadata memory metadata, Access memory access, Partner[] memory partners, uint256 owner_fee) public notPaused {
        address[] memory partners_ = new address[](partners.length);
        uint256[] memory partners_fees = new uint256[](partners.length);
        for (uint256 i = 0; i < partners.length; i++) {
            partners_[i] = partners[i].eth_address;
            partners_fees[i] = partners[i].percentage;
        }
        MetaSpace metaspace = new MetaSpace(metadata, access, partners_, partners_fees, msg.sender, owner_fee, _owner_of);
        emit created(address(metaspace), metadata.title, msg.sender);
    }
}