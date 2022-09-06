// SPDX-License-Identifier: MIT

/// @title Interface for QueenE NFT Token

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/utils/IVotes.sol";

import {IQueenTraits} from "./IQueenTraits.sol";
import {IQueenLab} from "./IQueenLab.sol";
import {RoyalLibrary} from "../contracts/lib/RoyalLibrary.sol";
import {IRoyalContractBase} from "./IRoyalContractBase.sol";
import {IERC721} from "./IERC721.sol";

interface IQueenE is IRoyalContractBase, IERC721 {
  function _currentAuctionQueenE() external view returns (uint256);

  function contractURI() external view returns (string memory);

  function mint() external returns (uint256);

  function getQueenE(uint256 _queeneId)
    external
    view
    returns (RoyalLibrary.sQUEEN memory);

  function burn(uint256 queeneId) external;

  function lockMinter() external;

  function lockQueenTraitStorage() external;

  function lockQueenLab() external;

  function nominateSir(address _sir) external returns (bool);

  function getHouseSeats(uint8 _seatType) external view returns (uint256);

  function getHouseSeat(address addr) external view returns (uint256);

  function IsSir(address _address) external view returns (bool);

  function isSirReward(uint256 queeneId) external view returns (bool);

  function isMuseum(uint256 queeneId) external view returns (bool);

  function dnaMapped(uint256 dnaHash) external view returns (bool);

  function isHouseOfLordsFull() external view returns (bool);
}