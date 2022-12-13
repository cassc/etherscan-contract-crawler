// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../token/ProjectToken.sol";
import "../tokenpool/INFTCollectorRewards.sol";

/// @title ITreasury
/// @notice This contract allows receiving ETH, ERC20 and ERC721 tokens.
/// Only owner can transfer these tokens
interface ITreasury {
  event EthReceived(address from, uint256 amount);
  event EthSent(address to, uint256 amount);
  event Erc20Sent(address to, address erc20, uint256 amount);
  event Erc721Sent(address to, address erc721, uint256 tokenID);

  /**
   * @dev Transfer eth to given address
   * @param amount Amount being transferred
   * @param to Recipient of the transfer
   */
  function transferETH(uint256 amount, address payable to) external;

  /**
   * @dev Transfer from the ERC20 balance of this contract to given address
   * @param erc721ContractAddr Contract address of the erc721 token
   * @param tokenId The tokenId being transferred
   * @param transferTo Recipient of the transfer
   */
  function transferERC721(
    address erc721ContractAddr,
    uint256 tokenId,
    address transferTo
  ) external;

  /**
   * @dev Transfer from the ERC20 balance of this contract to given address
   * @param erc20ContractAddr Contract address of the erc20 token
   * @param amount Amount of transfer
   * @param transferTo Recipient of the transfer
   */
  function transferERC20(
    address erc20ContractAddr,
    uint256 amount,
    address transferTo
  ) external;

  function burnProjectToken(ProjectToken projectToken, uint256 amount) external;

  /**
   * @dev Transfer ERC20 tokens to NFTCollectorRewards and invoke the deposit function
   */
  function transferERC20ToNFTCollectorRewards(
    address erc20ContractAddr,
    INFTCollectorRewards nftCollectorRewards,
    uint256 amount
  ) external;

  function transferERC20BatchWithVesting(
    address erc20ContractAddr,
    uint256[] memory amount,
    address[] memory transferTo,
    uint64[] memory vestingStartTimestamps,
    uint64[] memory vestingDurationSeconds
  ) external;

  /**
   * @dev Transfer from the ERC20 balance of another contract
   * using the allowance mechanism to given address
   * @param erc20ContractAddr Contract address of the erc20 token
   * @param fromAddr Source of transfer
   * @param amount Amount of transfer
   * @param transferTo Recipient of the transfer
   */
  function transferERC20Allowance(
    address erc20ContractAddr,
    address fromAddr,
    uint256 amount,
    address transferTo
  ) external;
}