/***
 *    ██╗███╗   ██╗████████╗███████╗██████╗ ███████╗ █████╗  ██████╗███████╗
 *    ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝
 *    ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝█████╗  ███████║██║     █████╗  
 *    ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║     ██╔══╝  
 *    ██║██║ ╚████║   ██║   ███████╗██║  ██║██║     ██║  ██║╚██████╗███████╗
 *    ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝
 *                                                                          
 *    ███╗   ███╗ █████╗ ██╗  ██╗  ███████╗██████╗  ██╗                     
 *    ████╗ ████║██╔══██╗╚██╗██╔╝  ╚════██║╚════██╗███║                     
 *    ██╔████╔██║███████║ ╚███╔╝█████╗ ██╔╝ █████╔╝╚██║                     
 *    ██║╚██╔╝██║██╔══██║ ██╔██╗╚════╝██╔╝ ██╔═══╝  ██║                     
 *    ██║ ╚═╝ ██║██║  ██║██╔╝ ██╗     ██║  ███████╗ ██║                     
 *    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝     ╚═╝  ╚══════╝ ╚═╝                     
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

  ///
  /// Developer this is the standard interface for all ERC721's written by myself
  ///

interface IMAX721 is IERC165 {

  // ERC165 data
  // minterStatus() => 0x2ecd28ab
  // minterFees() => 0xd95ae162
  // minterMaximumCapacity() => 0x78c5939b
  // minterMaximumTeamMints() => 0x049157bb
  // minterTeamMintsRemaining() => 0x5c17e370
  // minterTeamMintsCount() => 0xe68b7961
  // totalSupply() => 0x18160ddd
  // IMAX721 => 0x29499a25

  // @notice will return status of Minter
  // minterStatus() => 0x2ecd28ab
  function minterStatus() external view returns (bool);

  // @notice will return minting fees
  // minterFees() => 0xd95ae162
  function minterFees() external view returns (uint256);

  // @notice will return maximum mint capacity
  // minterMaximumCapacity() => 0x78c5939b
  function minterMaximumCapacity() external view returns (uint256);

  // @notice will return maximum "team minting" capacity
  // minterMaximumTeamMints() => 0x049157bb
  function minterMaximumTeamMints() external view returns (uint256);

  // @notice will return "team mints" left
  // minterTeamMintsRemaining() => 0x5c17e370
  function minterTeamMintsRemaining() external view returns (uint256);

  // @notice will return "team mints" count
  // minterTeamMintsCount() => 0xe68b7961
  function minterTeamMintsCount() external view returns (uint256);

  // @notice will return current token count
  // totalSupply() => 0x18160ddd
  function totalSupply() external view returns (uint256);
}