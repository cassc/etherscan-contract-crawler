// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

interface ISoulz {
  error PauseError();
  error NativeTokenValueError();
  error UtilityTokenValueError();
  error SoullessError();
  error NonExistantToken();
  error NativeTokenMintDisabled();
  error UtilityTokenMintDisabled();
  error TraitDoesNotExist();
  error WrongOwner();
  error EmptyStringParameter();

  function balanceOf(address owner) external view returns (uint256 balance);

  function ownerOf(uint256 tokenId) external view returns (address owner);
}