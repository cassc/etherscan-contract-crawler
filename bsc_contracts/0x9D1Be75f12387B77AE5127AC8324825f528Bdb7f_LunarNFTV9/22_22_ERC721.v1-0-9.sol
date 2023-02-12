// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "../ERC721.sol";

/**
 * @title An NFT Smart Contract
 * @author Copyright © 2022-2023 Lunar Foundation. All rights reserved.
 * @notice This is an upgrade to LunarNFT contract
 */
contract LunarNFTV9 is LunarNFT {

  /**
   * @notice shows the version of the contract being used
   * @dev the value represents the curreent version of the contract should be updated and overriden with new implementations
   * @return version -the current version of the contract
   */
  function version() external pure override returns (string memory) 
  {
    return "1.0.9";
  }
}