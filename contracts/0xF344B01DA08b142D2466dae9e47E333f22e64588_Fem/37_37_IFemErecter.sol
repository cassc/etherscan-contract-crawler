// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFem {
  function mint(address to, uint256 amount) external;

  function burn(address src, uint256 amount) external;

  function transferOwnership(address newOwner) external;

  function totalSupply() external view returns (uint256);
}

interface IFemErecter {
  /**
   * @notice Emitted when ETH is deposited.
   */
  event Deposit(address indexed account, uint256 amount);

  /**
   * @notice Emitted when ETH is withdrawn and FEM is burned.
   */
  event Withdraw(address indexed account, uint256 amount);

  /**
   * @notice Emitted when ETH is claimed by the DAO.
   */
  event EthClaimed(address to, uint256 amount);

  enum SaleState {
    PENDING, // Sale has not started yet
    ACTIVE, // Sale is active
    FUNDS_PENDING, // Sale complete with more than minimum ETH raised, pending use by DAO
    SUCCESS, // Sale complete with ETH claimed by DAO
    FAILURE // Sale complete with less than minimum ETH raised OR funds not used in time
  }

  /* View Functions */

  function devAddress() external view returns (address);

  function devTokenBips() external view returns (uint256);

  function ethClaimed() external view returns (bool);

  function fem() external view returns (IFem);

  function saleStartTime() external view returns (uint256);

  function saleEndTime() external view returns (uint256);

  function saleDuration() external view returns (uint256);

  function spendDeadline() external view returns (uint256);

  function minimumEthRaised() external view returns (uint256);

  function depositedAmount(address) external view returns (uint256);

  /// @notice Reports the current state of the token sale.
  function state() external view returns (SaleState);

  /* Actions */

  /// @notice Claim ETH raised through the sale for the DAO.
  /// note: Only callable if {state()} is {SaleState.FUNDS_PENDING}
  function claimETH(address to) external;

  /// @notice Deposit ETH in exchange for equivalent amount of FEM.
  /// note: Only callable if {state()} is {SaleState.ACTIVE}
  function deposit() external payable;

  /// @notice Burn FEM in exchange for equivalent amount of ETH.
  /// note: Only callable if {state()} is {SaleState.FAILURE}
  function burnFem(uint256 amount) external;
}