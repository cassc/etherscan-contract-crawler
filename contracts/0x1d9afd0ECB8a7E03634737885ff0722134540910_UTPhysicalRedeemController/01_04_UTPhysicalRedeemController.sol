//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;
/* 
 *    ██████  ██   ██ ██    ██ ███████ ██  ██████  █████  ██          ██████  ███████ ██████  ███████ ███    ███ ██████  ████████ ██  ██████  ███    ██ 
 *    ██   ██ ██   ██  ██  ██  ██      ██ ██      ██   ██ ██          ██   ██ ██      ██   ██ ██      ████  ████ ██   ██    ██    ██ ██    ██ ████   ██ 
 *    ██████  ███████   ████   ███████ ██ ██      ███████ ██          ██████  █████   ██   ██ █████   ██ ████ ██ ██████     ██    ██ ██    ██ ██ ██  ██ 
 *    ██      ██   ██    ██         ██ ██ ██      ██   ██ ██          ██   ██ ██      ██   ██ ██      ██  ██  ██ ██         ██    ██ ██    ██ ██  ██ ██ 
 *    ██      ██   ██    ██    ███████ ██  ██████ ██   ██ ███████     ██   ██ ███████ ██████  ███████ ██      ██ ██         ██    ██  ██████  ██   ████ 
 *                                                                                                                                                      
 *                                                                                                                                                      
 *     ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████                                                               
 *    ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██                                                              
 *    ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████                                                               
 *    ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██                                                              
 *     ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██                                                              
 *                                                                                                                                                      *                                                                                                              
 *                                                                                                     
 *    GALAXIS - Physical Redemption Trait (logic) controller
 *
 *    This contract is used for changing trait values in a UTPhysicalRedeemStorage contract
 *
 */

import "./UTGenericTimedController.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITraitStorage {
    function setValue(uint16 _tokenId, uint8 _value) external;
    function getValues(uint16[] memory _tokenIds) external view returns (uint8[] memory);
}

// Status:
// 1 - Open to redeem
// 2 - Redeemed by user
// 3 - Item posted (optional)

contract UTPhysicalRedeemController is UTGenericTimedController {

    uint256     public constant version              = 20230619;

    uint8       public constant TRAIT_TYPE           = 3;               // Physical redemption
    string      public constant APP                  = "redeemown";     // Application in the claim URL
    uint8              constant TRAIT_OPEN_VALUE     = 1;
    uint8              constant TRAIT_REDEEMED_VALUE = 2;

    // Errors
    error UTPhysicalRedeemControllerNoToken();
    error UTPhysicalRedeemControllerNotOwnerOfToken(address);
    error UTPhysicalRedeemControllerInvalidState(uint8);

    constructor(
        address _erc721,
        address _registry,
        uint256 _startTime,
        uint256 _endTime
    ) UTGenericTimedController(_erc721, _registry, _startTime, _endTime) {
    }

    function setValue(uint16[] memory tokenId, uint8 value, address traitStorage) public checkValidity {
        if(tokenId.length == 0) {
            revert UTPhysicalRedeemControllerNoToken();
        }

        // Read all current states
        uint8[] memory values = ITraitStorage(traitStorage).getValues(tokenId);

        for(uint8 i = 0; i < tokenId.length; i++) {
            uint16 currentTokenId = tokenId[i];
            uint8  currentValue = values[i];

            // Business logic (simple)
            if(currentValue == 1 && value == 2) {
                // From state 1 - "Open to redeem" to state 2 - "Redeemed by user" - Only owner of the NFT can change it
                if(erc721.ownerOf(currentTokenId) != msg.sender) {
                    revert UTPhysicalRedeemControllerNotOwnerOfToken(msg.sender);
                }
                ITraitStorage(traitStorage).setValue(currentTokenId, 2);
            } else {
                revert UTPhysicalRedeemControllerInvalidState(value);
            }
        }
    }
}