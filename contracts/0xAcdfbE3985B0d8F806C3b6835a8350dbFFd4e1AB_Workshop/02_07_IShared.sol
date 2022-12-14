// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

interface IShared {
  error PauseError();
  error ValueError();
  error TokenValueError();
  error SoullessError();
  error NonExistantToken();
  error TraitDoesNotExist();
  error WrongOwner();
  error EmptyStringParameter();

  struct Attributes {
    uint256 accessory;
    uint256 animation;
    uint256 background;
    uint256 body;
    uint256 bottom;
    uint256 ears;
    uint256 eyes;
    uint256 face;
    uint256 fx;
    uint256 head;
    uint256 mouth;
    uint256 overlay;
    uint256 shoes;
    uint256 top;
  }

  struct Price {
    uint256 ETH;
    uint256 M;
    uint256 RAGE;
    uint256 EGGZ;
  }
}