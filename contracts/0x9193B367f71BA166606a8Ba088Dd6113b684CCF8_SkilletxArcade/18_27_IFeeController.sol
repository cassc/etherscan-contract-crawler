//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

/**
 * Skillet <> Arcade
 * Fee Controller Interface
 * https://etherscan.io/address/0x41E538817C3311ed032653bEE5487a113F8CfF9F#code
 */
interface IFeeController {
  function getRolloverFee() external view returns (uint256);
  function getOriginationFee() external view returns (uint256);
}