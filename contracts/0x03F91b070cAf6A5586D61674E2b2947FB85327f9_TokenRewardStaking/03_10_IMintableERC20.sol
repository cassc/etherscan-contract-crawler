//
// Made by: Omicron Blockchain Solutions
//          https://omicronblockchain.com
//



// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice ERC20-compliant interface with added
 *         function for minting new tokens to addresses
 *
 * See {IERC20}
 */
interface IMintableERC20 is IERC20 {
  /**
   * @dev Allows issuing new tokens to an address
   *
   * @dev Should have restricted access
   */
  function mint(address _to, uint256 _amount) external;
}