// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {GenerativeCollectionToken} from "./GenerativeCollectionToken.sol";

/**
 * @author MetaPlayerOne DAO
 * @title GenerativeCollectionFactory
 */
contract GenerativeCollectionFactory {
    address private _randomizer_address;
    address private _owner_of;

    constructor(address owner_of_, address randomizer_address_) {
        _owner_of = owner_of_;
        _randomizer_address = randomizer_address_;
    }

    event collectionCreated(
        address token_address,
        address owner_of,
        string[3] metadata,
        uint256[5] drop_data,
        uint256[3] whitelist_data,
        uint96 royalty
    );

    function createCollection(
        string[3] memory metadata_,
        uint256[5] memory drop_data_,
        address[] memory access_tokens_,
        address[] memory profit_spit_addresses_,
        uint256[] memory profit_split_amount_,
        uint256[3] memory whitelist_data_,
        bool is_randomness_,
        uint96 royalty_
    ) public {
        GenerativeCollectionToken token = new GenerativeCollectionToken(
            msg.sender,
            royalty_,
            is_randomness_,
            _owner_of,
            _randomizer_address,
            metadata_,
            drop_data_,
            access_tokens_,
            profit_spit_addresses_,
            profit_split_amount_,
            whitelist_data_
        );
        emit collectionCreated(
            address(token),
            msg.sender,
            metadata_,
            drop_data_,
            whitelist_data_,
            royalty_
        );
    }
}