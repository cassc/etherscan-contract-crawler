// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAlloyxTreasury {
  function addEarningGfiFee(uint256 _amount) external;

  function addRepaymentFee(uint256 _amount) external;

  function addRedemptionFee(uint256 _amount) external;

  function addDuraToFiduFee(uint256 _amount) external;

  function getAllUsdcFees() external view returns (uint256);

  function getAllGfiFees() external view returns (uint256);

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function transferERC20(
    address _tokenAddress,
    address _account,
    uint256 _amount
  ) external;

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _from the address to transfer from
   * @param _account the address to transfer
   * @param _amount the amount to transfer
   * @param _tokenAddress the token address to transfer
   */
  function transferERC20From(
    address _from,
    address _tokenAddress,
    address _account,
    uint256 _amount
  ) external;

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _account the address to transfer
   * @param _tokenId the token ID to transfer
   * @param _tokenAddress the token address to transfer
   */
  function transferERC721(
    address _tokenAddress,
    address _account,
    uint256 _tokenId
  ) external;

  /**
   * @notice Transfer certain amount token of certain address to some other account
   * @param _from the address to transfer from
   * @param _account the address to transfer
   * @param _tokenId the token ID to transfer
   * @param _tokenAddress the token address to transfer
   */
  function transferERC721From(
    address _from,
    address _tokenAddress,
    address _account,
    uint256 _tokenId
  ) external;

  /**
   * @notice Approve certain amount token of certain address to some other account
   * @param _account the address to approve
   * @param _amount the amount to approve
   * @param _tokenAddress the token address to approve
   */
  function approveERC20(
    address _tokenAddress,
    address _account,
    uint256 _amount
  ) external;

  /**
   * @notice Approve certain amount token of certain address to some other account
   * @param _account the address to approve
   * @param _tokenId the token ID to transfer
   * @param _tokenAddress the token address to approve
   */
  function approveERC721(
    address _tokenAddress,
    address _account,
    uint256 _tokenId
  ) external;
}