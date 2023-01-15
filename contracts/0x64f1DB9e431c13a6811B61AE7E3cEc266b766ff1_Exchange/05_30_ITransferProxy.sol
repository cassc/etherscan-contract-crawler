// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";

/**
 * @title  SBINFT market non-native asset transfer protocol
 */
interface ITransferProxy is IERC165Upgradeable {
  /**
   * @notice Safe transfer ERC20 token
   * @dev only registered operators could call this function(i.e. Exchange)
   *
   * @param _token IERC20 token address
   * @param _from address from
   * @param _to address to
   * @param _value uint256 value
   */
  function erc20safeTransferFrom(
    IERC20 _token,
    address _from,
    address _to,
    uint256 _value
  ) external;

  /**
   * @notice Safe transfer ERC721 token
   * @dev only registered operators could call this function(i.e. Exchange)
   *
   * @param _token IERC721 token address
   * @param _from address current owner address
   * @param _to address new to be owner address
   * @param _tokenId uint256 token id to transfer
   */
  function erc721safeTransferFrom(
    IERC721 _token,
    address _from,
    address _to,
    uint256 _tokenId
  ) external;

  /**
   * @notice Safe transfer ERC1155 token
   * @dev only registered operators could call this function(i.e. Exchange)
   *
   * @param _token IERC1155 token address
   * @param _from address current owner address
   * @param _to address new to be owner address
   * @param _tokenId uint256 token id to transfer
   * @param _value uint256 count of token to transfer
   * @param _data bytes extra data if needed
   */
  function erc1155safeTransferFrom(
    IERC1155 _token,
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _value,
    bytes calldata _data
  ) external;
}