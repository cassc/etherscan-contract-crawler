// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC20 Airdrop contract
 * @author artpumpkin
 */
contract Airdrop {

   /**
   * @notice Airdrops tokens to addresses
   * @param token ERC20 token to airdrop
   * @param addresses Array of user addresses to airdrop to
   * @param amounts Array of airdropped amounts of each user
   * @dev The caller must be the owner of the ERC20 tokens that needs to be airdropped
   * Make sure to approve the amount before airdropping or else it will fail
   */
  function airdrop(IERC20 token, address[] calldata addresses, uint256[] calldata amounts) external {
    for (uint256 i = 0; i < addresses.length; i++) {
      token.transferFrom(msg.sender, addresses[i], amounts[i]);
    }

    emit Airdropped(token, addresses, amounts);
  }

  event Airdropped(IERC20 token, address[] addresses, uint256[] amounts);
}