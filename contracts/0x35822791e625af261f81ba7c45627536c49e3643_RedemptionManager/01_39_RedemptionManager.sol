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
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../interfaces/IDropManager.sol";
import "../interfaces/IRedemptionManager.sol";
import "../interfaces/ITokenContract.sol";
import "../libraries/GrtLibrary.sol";
import "./TokenContract.sol";
import "./Timelock.sol";

contract RedemptionManager is
  IRedemptionManager,
  AccessControl,
  IERC721Receiver,
  Timelock
{
  //#########################
  //#### STATE VARIABLES ####
  bytes32 public constant override PLATFORM_ADMIN_ROLE =
    keccak256("PLATFORM_ADMIN_ROLE");
  bytes32 public constant override WAREHOUSE_MANAGER_ROLE =
    keccak256("WAREHOUSE_MANAGER_ROLE");
  bytes32 public constant override DROP_MANAGER_ROLE =
    keccak256("DROP_MANAGER_ROLE");

  // tokenId => original token owner
  mapping(uint256 => address) public override originalOwners;
  TokenContract public immutable override liquidToken;
  TokenContract public immutable override redeemedToken;

  //#########################
  //#### IMPLEMENTATION ####

  constructor(
    address platformAdmin,
    address superUser,
    address _liquidToken,
    address _redeemedToken
  ) {
    GrtLibrary.checkZeroAddress(platformAdmin, "platform admin");
    GrtLibrary.checkZeroAddress(superUser, "super user");
    GrtLibrary.checkZeroAddress(_liquidToken, "liquid token");
    GrtLibrary.checkZeroAddress(_redeemedToken, "redeemed token");

    _grantRole(PLATFORM_ADMIN_ROLE, platformAdmin);
    _grantRole(DEFAULT_ADMIN_ROLE, superUser);
    _setRoleAdmin(WAREHOUSE_MANAGER_ROLE, PLATFORM_ADMIN_ROLE);
    _setRoleAdmin(DROP_MANAGER_ROLE, PLATFORM_ADMIN_ROLE);
    liquidToken = TokenContract(_liquidToken);
    redeemedToken = TokenContract(_redeemedToken);
  }

  function createRedemption(uint256 tokenId, uint256 releaseId)
    external
    override
  {
    if (!_getRedeemableStatus(releaseId))
      revert RedeemableStatusIncorrect(releaseId);
    originalOwners[tokenId] = msg.sender;
    emit RedemptionCreated(msg.sender, tokenId);
    liquidToken.safeTransferFrom(msg.sender, address(this), tokenId);
  }

  function finaliseRedemption(uint256[] calldata tokens) external override {
    if (!hasRole(WAREHOUSE_MANAGER_ROLE, msg.sender)) {
      revert IncorrectAccess(msg.sender);
    }
    ITokenContract.MintWithIdArgs[]
      memory mintArray = new ITokenContract.MintWithIdArgs[](tokens.length);
    uint256[] memory burnArray = new uint256[](tokens.length);

    for (uint16 i = 0; i < tokens.length; i++) {
      mintArray[i] = ITokenContract.MintWithIdArgs({
        to: originalOwners[tokens[i]],
        tokenId: tokens[i]
      });
      burnArray[i] = tokens[i];
      emit RedemptionFinalised(msg.sender, tokens[i]);
      delete originalOwners[tokens[i]];
    }
    redeemedToken.mintWithId(mintArray);
    liquidToken.burn(burnArray);
  }

  function abortRedemption(uint256 tokenId) external override {
    if (
      !(hasRole(WAREHOUSE_MANAGER_ROLE, msg.sender) ||
        hasRole(PLATFORM_ADMIN_ROLE, msg.sender))
    ) {
      revert IncorrectAccess(msg.sender);
    }
    address originalOwner = originalOwners[tokenId];
    delete originalOwners[tokenId];
    emit RedemptionAborted(msg.sender, tokenId);
    liquidToken.safeTransferFrom(address(this), originalOwner, tokenId);
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  function setTimeLock(uint256 releaseId, uint256 releaseDate) external {
    if (
      !(hasRole(PLATFORM_ADMIN_ROLE, msg.sender) ||
        hasRole(DROP_MANAGER_ROLE, msg.sender))
    ) {
      revert IncorrectAccess(msg.sender);
    }

    if (releaseDate < block.timestamp && releaseDate != 0) {
      revert ReleaseDateInvalid(releaseDate);
    }

    _setTimelock(releaseId, releaseDate);
  }
}