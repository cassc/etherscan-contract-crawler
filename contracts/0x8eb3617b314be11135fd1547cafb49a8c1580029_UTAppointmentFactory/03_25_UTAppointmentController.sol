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
 *     ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████          
 *    ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██         
 *    ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████          
 *    ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██         
 *     ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██         
 *
 *
 *    GALAXIS - Appointment Trait (logic) controller
 *
 *    This contract is used for changing trait values in a UTAppointmentStorage contract
 *
*/

import "./UTGenericTimedController.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITraitStorage {
    function setValue(uint16 _tokenId, uint8 _value, bytes32 _eventId) external;
    function getValues(uint16[] memory _tokenIds) external view returns (uint8[] memory);
    function getTokenForEvent(bytes32 _eventId) external view returns (uint16);
}

// Status:
// 1 - Open to redeem
// 2 - Redeemed by the user (date fixed)

contract UTAppointmentController is UTGenericTimedController {

    uint256     public constant version                 = 20230619;

    uint8       public constant TRAIT_TYPE              = 4;                // Appointment trait
    string      public constant APP                     = 'appointment';    // Application in the claim URL
    uint8              constant TRAIT_OPEN_VALUE        = 1;
    uint8              constant TRAIT_REDEEMED_VALUE    = 2;

    // Errors
    error UTAppointmentControllerNoToken();
    error UTAppointmentControllerNotOwnerOfToken(address);
    error UTAppointmentControllerAppointmentAlreadyTaken();
    error UTAppointmentControllerInvalidState(uint8);

    constructor(
        address _erc721,
        address _registry,
        uint256 _startTime,
        uint256 _endTime
    ) UTGenericTimedController(_erc721, _registry, _startTime, _endTime) {
    }

    function setValue(uint16[] memory tokenId, uint8 value, bytes32[] memory eventId, address traitStorage) public checkValidity {

        if(tokenId.length == 0) {
            revert UTAppointmentControllerNoToken();
        }

        // Read all current states
        uint8[] memory values = ITraitStorage(traitStorage).getValues(tokenId);

        for(uint8 i = 0; i < tokenId.length; i++) {
            uint16 currentTokenId = tokenId[i];
            uint8  currentValue = values[i];
            bytes32 currentEventId = eventId[i];

            // Business logic (simple)
            if(currentValue == TRAIT_OPEN_VALUE && value == TRAIT_REDEEMED_VALUE) {
                // From state 1 - "Open to redeem" to state 2 - "Redeemed by the user (date fixed)" - Only owner of the NFT can change it
                if(erc721.ownerOf(currentTokenId) != msg.sender) {
                    revert UTAppointmentControllerNotOwnerOfToken(msg.sender);
                }

                // Is this event still open?
                if(ITraitStorage(traitStorage).getTokenForEvent(currentEventId) != 0) {
                    revert UTAppointmentControllerAppointmentAlreadyTaken();
                }

                ITraitStorage(traitStorage).setValue(currentTokenId, TRAIT_REDEEMED_VALUE, currentEventId);
            } else {
                revert UTAppointmentControllerInvalidState(value);
            }
        }
    }
}