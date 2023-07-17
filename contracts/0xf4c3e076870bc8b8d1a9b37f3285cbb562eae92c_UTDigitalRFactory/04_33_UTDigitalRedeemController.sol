//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;
/*
 *    ██████  ██  ██████  ██ ████████  █████  ██          ██████  ███████ ██████  ███████ ███████ ███    ███ 
 *    ██   ██ ██ ██       ██    ██    ██   ██ ██          ██   ██ ██      ██   ██ ██      ██      ████  ████ 
 *    ██   ██ ██ ██   ███ ██    ██    ███████ ██          ██████  █████   ██   ██ █████   █████   ██ ████ ██ 
 *    ██   ██ ██ ██    ██ ██    ██    ██   ██ ██          ██   ██ ██      ██   ██ ██      ██      ██  ██  ██ 
 *    ██████  ██  ██████  ██    ██    ██   ██ ███████     ██   ██ ███████ ██████  ███████ ███████ ██      ██ 
 *                                                                                                     
 *                                                                                                       
 *     ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████  
 *    ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██ 
 *    ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████  
 *    ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██ 
 *     ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██ 
 *                                                                                                     
 *    GALAXIS - Digital Redemption Trait (logic) controller
 *
 *    This contract is used for changing trait values in a UTDigitalRedeemStorage contract
 *
 */

import "./UTGenericTimedController.sol";
import "./UTDigitalRedeemVault.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "hardhat/console.sol";

contract UTDigitalRedeemController is UTGenericTimedController, UTDigitalRedeemVault {

    uint256     public constant version     = 20230622;

    uint8       public constant TRAIT_TYPE  = 6;                // Digital redemption
    string      public constant APP         = "digitalredeem";  // Application in the claim URL

    // Errors
    error UTDigitalRedeemControllerNoToken();
    error UTDigitalRedeemControllerNotOwnerOfToken(address);
    error UTDigitalRedeemControllerInvalidState(uint8);

    constructor(
        address _erc721,
        address _registry,
        uint256 _startTime,
        uint256 _endTime,
        address _communityRegistry
    ) UTGenericTimedController(_erc721, _registry, _startTime, _endTime) BlackHolePreventionForCROwner(_communityRegistry)
    {
    }

    function setValue(uint16[] memory tokenId, uint8 value, address traitStorage) public checkValidity {
        if(tokenId.length == 0) {
            revert UTDigitalRedeemControllerNoToken();
        }

        ITraitStorage storageCtr = ITraitStorage(traitStorage);

        // Read all current states
        uint8[] memory values = storageCtr.getValues(tokenId);

        for(uint8 i = 0; i < tokenId.length; i++) {
            uint16 currentTokenId = tokenId[i];
            uint8  currentValue = values[i];

            // Business logic (simple)
            if(currentValue >= TRAIT_OPEN_VALUE && value > currentValue && value <= (TRAIT_OPEN_VALUE + storageCtr.maxTokensToRedeem()) ) {
                // From state 1 - "Open to redeem" to any state till (1 + storage.maxTokensToRedeem) - Only owner of the NFT can change it
                if(erc721.ownerOf(currentTokenId) != msg.sender) {
                    revert UTDigitalRedeemControllerNotOwnerOfToken(msg.sender);
                }

                uint8 tokensToDrop = value - currentValue;
                _requestDropFromVault(address(erc721), currentTokenId, traitStorage, tokensToDrop, storageCtr.collectionToRedeemFrom() );

                // This will happen in the VRF callback !
                // ITraitStorage(traitStorage).setValue(currentTokenId, value);
            } else {
                revert UTDigitalRedeemControllerInvalidState(value);
            }
        }
    }
}