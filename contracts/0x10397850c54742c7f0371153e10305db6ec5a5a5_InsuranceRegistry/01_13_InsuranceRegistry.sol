// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IInsuranceRegistry.sol";
import "../libraries/GrtLibrary.sol";
import "../vendors/ExtendedBitmap.sol";

/// @title GRT Wines Insurance Registry
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor Sean L (slongdotexe)
/// @notice External registry contract for tracking if a Token (bottle of wine) has been damaged and thus should
///         not be able to be transferred to another user
/// @dev    Extended Bitmaps library is utilised to provide a gas efficent mechanism for rapidly manipulating large
//          quantities of boolean statuses. It is assumed that the structure of the Bitmap will be reliably calculated off-chain
contract InsuranceRegistry is IInsuranceRegistry, AccessControl {
  bytes32 public constant override PLATFORM_ADMIN_ROLE =
    keccak256("PLATFORM_ADMIN_ROLE");
  using ExtendedBitmap for ExtendedBitmap.BitMap;

  ExtendedBitmap.BitMap internal voidTokens;

  constructor(address platformAdmin, address superUser) {
    GrtLibrary.checkZeroAddress(platformAdmin, "platform admin");
    GrtLibrary.checkZeroAddress(superUser, "super user");

    _grantRole(PLATFORM_ADMIN_ROLE, platformAdmin);
    _grantRole(DEFAULT_ADMIN_ROLE, superUser);
  }

  function createInsuranceEvent(InsuranceEvent calldata insuranceEvent)
    external
    override
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    uint256 bucketOffset = insuranceEvent.firstAffectedToken >> 8;
    for (uint256 i = 0; i < insuranceEvent.affectedTokens.length; i++) {
      voidTokens.setBucket(i + bucketOffset, insuranceEvent.affectedTokens[i]);
    }
    emit InsuranceEventRegistered(
      insuranceEvent.firstAffectedToken,
      insuranceEvent.affectedTokens
    );
  }

  function checkTokenStatus(uint256 _tokenId)
    external
    view
    override
    returns (bool isTokenAffected)
  {
    isTokenAffected = voidTokens.get(_tokenId);
  }
}