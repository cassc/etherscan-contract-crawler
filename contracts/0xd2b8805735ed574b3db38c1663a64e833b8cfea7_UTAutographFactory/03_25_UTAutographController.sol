//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;
/* 
 *     █████  ██    ██ ████████  ██████   ██████  ██████   █████  ██████  ██   ██          
 *    ██   ██ ██    ██    ██    ██    ██ ██       ██   ██ ██   ██ ██   ██ ██   ██          
 *    ███████ ██    ██    ██    ██    ██ ██   ███ ██████  ███████ ██████  ███████          
 *    ██   ██ ██    ██    ██    ██    ██ ██    ██ ██   ██ ██   ██ ██      ██   ██          
 *    ██   ██  ██████     ██     ██████   ██████  ██   ██ ██   ██ ██      ██   ██          
 *                                                                                         
 *                                                                                         
 *     ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████  
 *    ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██ 
 *    ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████  
 *    ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██ 
 *     ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██ 
 *                                                                                                   
 *    GALAXIS - Autograph Trait (logic) controller
 *
 *    This contract is used for changing trait values in a UTAutographStorage contract.
 *
 */

import "./UTGenericTimedController.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITraitStorage {
    function setValue(uint16 _tokenId, storageStruct memory _value) external;
    function getValues(uint16[] memory _tokenIds) external view returns (storageStruct[] memory);
}

struct storageStruct {
    uint8   state;                  // The state of the Autograph
    string  ipfsHash;               // The IPFS hash of the Autograph (if it was already signed)
}

// Status:
// 1 - Open to redeem
// 2 - Signature asked
// 3 - Signature created 

contract UTAutographController is UTGenericTimedController {

    uint256     public constant version                         = 20230619;

    uint8       public constant TRAIT_TYPE                      = 5;            // Autograph
    string      public constant APP                             = 'autograph';  // Application in the claim URL
    uint8              constant TRAIT_OPEN_VALUE                = 1;
    uint8              constant TRAIT_AUTOGRAPH_REQUESTED_VALUE = 2;

    // Errors
    error UTAutographControllerNoToken();
    error UTAutographControllerNotOwnerOfToken(address);
    error UTAutographControllerAppointmentAlreadyTaken();
    error UTAutographControllerInvalidState(uint8);

    constructor(
        address _erc721,
        address _registry,
        uint256 _startTime,
        uint256 _endTime
    ) UTGenericTimedController(_erc721, _registry, _startTime, _endTime) {
    }

    function setValue(uint16[] memory tokenId, storageStruct memory value, address traitStorage) public checkValidity {

        if(tokenId.length == 0) {
            revert UTAutographControllerNoToken();
        }

        // Read all current states
        storageStruct[] memory data = ITraitStorage(traitStorage).getValues(tokenId);

        for(uint8 i = 0; i < tokenId.length; i++) {
            uint16 currentTokenId = tokenId[i];
            storageStruct memory currentData = data[i];

            // Business logic (simple)
            if(currentData.state == TRAIT_OPEN_VALUE && value.state == TRAIT_AUTOGRAPH_REQUESTED_VALUE) {
                // From state 1 - "Open to redeem" to state 2 - "Autograph requested" - Only owner of the NFT can change it
                if(erc721.ownerOf(currentTokenId) != msg.sender) {
                    revert UTAutographControllerNotOwnerOfToken(msg.sender);
                }

                // Only the state will be updated
                currentData.state = TRAIT_AUTOGRAPH_REQUESTED_VALUE;
                ITraitStorage(traitStorage).setValue(currentTokenId, currentData);
            } else {
                revert UTAutographControllerInvalidState(value.state);
            }
        }
    }
}