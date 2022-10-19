// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Marketplace} from "./Marketplace.sol";
import {IMarketplace} from "./IMarketplace.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MarketplaceFactory
 * @notice Manages creation of Marketplaces on MetaPlayerOne. 
 */
contract MarketplaceFactory is IMarketplace {
    address private _owner_of;

    constructor(address owner_of_) {
        _owner_of = owner_of_;
    }

    event created(address space_address, string title, address owner_of);

    function create(Metadata memory metadata, Access memory access, Partner[] memory partners, uint256 owner_fee, Curator[] memory curators) public {
        address[] memory partners_ = new address[](partners.length);
        uint256[] memory partners_fees_ = new uint256[](partners.length);
        for (uint256 i = 0; i < partners.length; i++) {
            partners_[i] = partners[i].eth_address;
            partners_fees_[i] = partners[i].percentage;
        }
        address[] memory curators_ = new address[](curators.length);
        uint256[] memory curator_fees_ = new uint256[](curators.length);
        for (uint256 i = 0; i < curators.length; i++) {
            curators_[i] = curators[i].eth_address;
            curator_fees_[i] = curators[i].percentage;
        }
        Marketplace marketplace = new Marketplace(metadata, access, partners_, partners_fees_, msg.sender, owner_fee, _owner_of, curators_, curator_fees_);
        emit created(address(marketplace), metadata.title, msg.sender);
    }
}