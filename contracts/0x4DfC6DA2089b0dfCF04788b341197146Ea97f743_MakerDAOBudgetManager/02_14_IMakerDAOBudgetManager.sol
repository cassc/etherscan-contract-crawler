// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title MakerDAOBudgetManager contract
/// @notice Contains all the views and methods used for handling DAI vesting
interface IMakerDAOBudgetManager {
  // Events

  /// @notice Emitted when Governor adds an invoice to be charged
  /// @param _nonce The number ID of the invoice
  /// @param _gasCostETH The amount of gas invoiced in ETH
  /// @param _claimableDai The equivalent amount of DAI to be charged for the gas amount
  /// @param _description A text description to explain the nature of the invoice
  event InvoicedGas(uint256 indexed _nonce, uint256 _gasCostETH, uint256 _claimableDai, string _description);

  /// @notice Emitted when Governor removes an incorrect invoice
  /// @param _nonce The number ID of the deleted invoice
  event DeletedInvoice(uint256 indexed _nonce);

  /// @notice Emitted when the DAI vest mechanism is executed
  /// @param _claimed The amount of DAI used to reduce invoice debt
  /// @param _refilled The amount of DAI sent to the Keep3rJob to refill credits
  /// @dev The total sum _claimed + _refilled + _returned should be equivalent to vested DAI
  event ClaimedDai(uint256 _claimed, uint256 _refilled);

  /// @notice Emitted when Governor changes the Keep3r and Job addresses
  /// @param _keep3r The address of Keep3r where the job is registered
  /// @param _job The address of the Job contract
  /// @dev Both parameters are changed together to avoid any broken references
  event Keep3rJobSet(address _keep3r, address _job);

  /// @notice Emitted when Governor changes the Keeper address
  /// @param _keeper The address allowed to upkeep the claim function
  event KeeperSet(address _keeper);

  /// @notice Emitted when new network payment adapter has been setted
  /// @param _networkPaymentAdapter The address of the network payment adapter
  event NetworkPaymentAdapterSet(address _networkPaymentAdapter);

  // Errors

  /// @notice Throws when the invoice to be deleted has already been claimed
  error IMakerDAOBudgetManager_InvoiceClaimed();
  /// @notice Throws when an unallowed address tries to trigger upkeep
  error IMakerDAOBudgetManager_OnlyKeeper();

  // Views

  /// @notice The address of DAI
  function DAI() external view returns (address _dai);

  /// @notice Sum of invoiced DAI amount minus already claimed DAI
  /// @return _dai The amount of DAI currently in debt to the contract
  function daiToClaim() external returns (uint256 _dai);

  /// @return _networkPaymentAdapter
  function networkPaymentAdapter() external returns (address _networkPaymentAdapter);

  /// @return _job The address of the Job contract
  function job() external returns (address _job);

  /// @return _keep3r The address of Keep3r where the job is registered
  function keep3r() external returns (address _keep3r);

  /// @return _keeper The address allowed to upkeep the claim function
  function keeper() external returns (address _keeper);

  /// @notice Maps the invoice ID to the invoiced DAI amount
  /// @param _invoiceNonce The invoice ID
  /// @return _invoiceDai The amount of invoiced DAI
  function invoiceAmount(uint256 _invoiceNonce) external returns (uint256 _invoiceDai);

  /// @notice Current invoice nonce
  /// @param _currentNonce The index of the current nonce
  function invoiceNonce() external returns (uint256 _currentNonce);

  /// @notice Amount of credits available
  /// @return _daiCredits The amount of DAI credits on the Keep3r Job
  function getDaiCredits() external view returns (uint256 _daiCredits);

  // Methods

  /// @notice Allows Governor to add invoices
  /// @param _gasCostETH The amount of gas invoiced in ETH
  /// @param _claimableDai The equivalent amount of DAI to be charged for the gas amount
  /// @param _description A text description to explain the nature of the invoice
  function invoiceGas(
    uint256 _gasCostETH,
    uint256 _claimableDai,
    string memory _description
  ) external;

  /// @notice Allows Governor to remove an unclaimed invoice
  /// @param _invoiceNonce The number ID of the deleted invoice
  function deleteInvoice(uint256 _invoiceNonce) external;

  /// @notice Allows Governor to trigger DAI vest
  function claimDai() external;

  /// @notice Allows Keeper to trigger DAI vest
  function claimDaiUpkeep() external;

  /// @notice Allows Governor to set new Keep3rJob
  /// @param _keep3r The address of Keep3r where the job is registered
  /// @param _job The address of the Job contract
  function setKeep3rJob(address _keep3r, address _job) external;

  /// @notice Allows Governor to set new Keeeper
  /// @param _keeper The address allowed to upkeep the claim function
  function setKeeper(address _keeper) external;

  /// @notice Allows Governor to set new network payment adapter
  /// @param _networkPaymentAdapter The address of the network payment adapter
  function setNetworkPaymentAdapter(address _networkPaymentAdapter) external;
}