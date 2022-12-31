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

    event collectionCreated(string[3] metadata,address owner_of,uint256 price,uint96 royalty,uint256 limit,uint256 limit_per_account,address token_address,uint256 start_time,uint256 free_mint);

    function createCollection(string[3] memory metadata_,uint96 royalty_,uint256[5] memory uints,address[] memory access_tokens_,address[] memory profit_spit_addresses_,uint256[] memory profit_split_amount_) public {
        GenerativeCollectionToken token = new GenerativeCollectionToken(metadata_,msg.sender,royalty_,uints,_owner_of,access_tokens_,profit_spit_addresses_,profit_split_amount_,_randomizer_address);
        emit collectionCreated(metadata_,msg.sender,uints[0],royalty_,uints[1],uints[2],address(token),uints[3],uints[4]);
    }
}