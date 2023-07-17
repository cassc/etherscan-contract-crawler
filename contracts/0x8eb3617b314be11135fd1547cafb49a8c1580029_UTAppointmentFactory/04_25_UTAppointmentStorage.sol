//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;
/* 
 *     █████  ██████  ██████   ██████  ██ ███    ██ ████████ ███    ███ ███████ ███    ██ ████████ 
 *    ██   ██ ██   ██ ██   ██ ██    ██ ██ ████   ██    ██    ████  ████ ██      ████   ██    ██    
 *    ███████ ██████  ██████  ██    ██ ██ ██ ██  ██    ██    ██ ████ ██ █████   ██ ██  ██    ██    
 *    ██   ██ ██      ██      ██    ██ ██ ██  ██ ██    ██    ██  ██  ██ ██      ██  ██ ██    ██    
 *    ██   ██ ██      ██       ██████  ██ ██   ████    ██    ██      ██ ███████ ██   ████    ██    
 *                                                                                                 
 *                                                                                                 
 *    ███████ ████████  ██████  ██████   █████   ██████  ███████                                   
 *    ██         ██    ██    ██ ██   ██ ██   ██ ██       ██                                        
 *    ███████    ██    ██    ██ ██████  ███████ ██   ███ █████                                     
 *         ██    ██    ██    ██ ██   ██ ██   ██ ██    ██ ██                                        
 *    ███████    ██     ██████  ██   ██ ██   ██  ██████  ███████                                   
 *
 *
 *    GALAXIS - Appointment Trait Storage
 *
 */

import "./UTGenericDroppableStorage.sol";

contract UTAppointmentStorage is UTGenericDroppableStorage {

    uint256     public constant version    = 20230619;

    uint8       public constant TRAIT_TYPE = 4;     // Appointment trait

    // -- Trait storage per tokenID --
    // tokenID => uint8 value
    mapping(uint16 => uint8) data;

    // --- Event storage ---
    // event ID => tokenId
    // 0 is a sentinel value, so we store tokenId+1 in the mapping
    mapping( bytes32 => uint16 ) public tokenIdByEvent;
    // tokenID => event ID
    mapping( uint16 => bytes32 ) public eventByTokenId;

    // Events
    event updateTraitEvent(uint16 indexed _tokenId, uint8 _newData);

    constructor(
        address _registry,
        uint16 _traitId
    ) UTGenericStorage(_registry, _traitId) {
    }

    // Update multiple token values at once
    // EventIds could not be updated here, as those should be unique (use setValue per tokenId)!
    function setData(uint16[] memory _tokenIds, uint8[] memory _value) public onlyAllowed {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            data[_tokenIds[i]] = _value[i];
            emit updateTraitEvent(_tokenIds[i], _value[i]);
        }
    }

    // update one token value
    function setValue(uint16 _tokenId, uint8 _value, bytes32 _eventId) public onlyAllowed {
        data[_tokenId] = _value;
        // Reserve the eventId for the tokenId
        tokenIdByEvent[_eventId] = _tokenId + 1;        // 0 is sentinel value, so we add 1
        eventByTokenId[_tokenId] = _eventId;
        emit updateTraitEvent(_tokenId, _value);
    }

    // get trait value for one token
    function getValue(uint16 _tokenId) public view returns (uint8) {
        return data[_tokenId];
    }

    // get trait values for an array of tokens
    function getValues(uint16[] memory _tokenIds) public view returns (uint8[] memory) {
        uint8[] memory retval = new uint8[](_tokenIds.length);
        for(uint16 i = 0; i < _tokenIds.length; i++) {
            retval[i] = data[_tokenIds[i]];
        }
        return retval;
    }

    // get trait values for a range of tokens
    function getValues(uint16 _start, uint16 _len) public view returns (uint8[] memory) {
        uint8[] memory retval = new uint8[](_len);
        for(uint16 i = 0; i < _len; i++) {
            retval[i] = data[i+_start];
        }
        return retval;
    }

    // get token (+1) which has the eventId (tokens starts from 1 as 0 means unused token)
    function getTokenForEvent(bytes32 _eventId) public view returns (uint16) {
        return tokenIdByEvent[_eventId];
    }

    // --- For interface: IGenericDroppableStorage ---
    // These functions must be implemented for this trait to be used with UTGenericDropper contract

    // Update one token value to TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return bool - was the trait actually opened (or already in a non initial state)?
    function addTraitToToken(uint16 _tokenId) public onlyAllowed returns(bool wasSet) {
        if (data[_tokenId] == TRAIT_INITIAL_VALUE) {
            data[_tokenId] = TRAIT_OPEN_VALUE;
            emit updateTraitEvent(_tokenId, TRAIT_OPEN_VALUE);
            return true;
        } else {
            return false;            
        }
    }

    // Update multiple token to value TRAIT_OPEN_VALUE (unified trait opener for each storage)
    // used by the traitDropper contracts
    // return: number of tokens actually set (not counting tokens already had the trait opened)
    // addTraitToToken() was not called from the loop to skip the recurring "onlyAllowed"
    function addTraitOnMultiple(uint16[] memory tokenIds) public onlyAllowed returns(uint16 changes) {
        for (uint16 i = 0; i < tokenIds.length; i++) {
            if (data[tokenIds[i]] == TRAIT_INITIAL_VALUE) {
                data[tokenIds[i]] = TRAIT_OPEN_VALUE;
                emit updateTraitEvent(tokenIds[i], TRAIT_OPEN_VALUE);
                changes++;
            }
        }
    }

    // Was the trait activated (meaning it has non zero uint8 value)
    function hasTrait(uint16 _tokenId) public view returns(bool) {
        return getValue(_tokenId) != 0;
    }

    // Read the generic part of the trait (the uint8 status value)
    function getUint8Value(uint16 _tokenId) public view returns(uint8) {
        return getValue(_tokenId);
    }

    // Read the generic part of the trait for multiple tokens (the uint8 status value)
    function getUint8Values(uint16[] memory _tokenIds) public view returns (uint8[] memory) {
        return getValues(_tokenIds);
    }
}