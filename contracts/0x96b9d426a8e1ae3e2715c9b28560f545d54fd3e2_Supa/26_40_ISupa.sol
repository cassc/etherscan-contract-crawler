// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISupa {

  /* ============ State Change ============ */

  /**
   * Underlying needs to be approved by the sender.
   * @notice This function deposits assets of underlying tokens into the vault and grants ownership of shares to receiver.
   * @param _assets Units of the underlying asset to deposit
   * @param _receiver Address to receive the shares of the vault. Usually the sender
   * @return _shares Shares emitted to the receiver
   */
  function deposit(uint256 _assets, address _receiver) external returns (uint256 _shares);

  /**
   * Underlying needs to be approved by the sender.
   * @notice This function mints exactly shares vault shares to receiver by depositing assets of underlying tokens.
   * @param _shares Units of the underlying asset to receive
   * @param _receiver Address to receive the shares of the vault. Usually the sender
   * @return _assets Shares of the underlying asset taken from the depositor
   */
  function mint(uint256 _shares, address _receiver) external returns (uint256 _assets);
  /**
   * @notice This function burns shares from owner and send exactly assets token from the vault to receiver.
   * @param _assets Units of the underlying asset to withdraw
   * @param _receiver Address to receive the underlying asset. Usually the sender
   * @param _owner Address that owns the token shares. Usually the sender
   * @return _shares Vault shares burned
   */
  function withdraw(uint256 _assets, address _receiver, address _owner) external returns (uint256 _shares);

  /**
   * @notice This function redeems a specific number of shares from owner and send assets of underlying token from the vault to receiver.
   * @param _shares Units of the underlying asset to withdraw
   * @param _receiver Address to receive the underlying assets. Usually the sender
   * @param _owner Address that owns the token shares. Usually the sender
   * @return _assets Units of the underlying assets returned
   */
  function redeem(uint256 _shares, address _receiver, address _owner) external returns (uint256 _assets);

  /**
   * @notice This function sets the fee and fee recipient. Only owner can change it.
   * @param _fee Fee of profits to be sent to recipient. 1e18 = 100%
   * @param _feeRecipient Address to receive the fee
   */
  function setFee(uint256 _fee, address _feeRecipient) external;

  /**
   * @dev Returns to paused state.
   * Requirements:
   * - The contract must not be paused.
   * - Caller must be the owner
   */
  function pause() external;

  /**
   * @dev Returns to normal state.
   * Requirements:
   * - The contract must be paused.
   * - Caller must be the owner
   */
  function unpause() external;

  /**
   * @notice This function sets the leverage configuration
   * @param _longLeverageTimes How many times to loop the long
   * @param _shortLeverageTimes How many times to loop the short
   */
  function setLeverageConfig(uint8 _longLeverageTimes, uint8 _shortLeverageTimes) external;

  /**
   * @notice This function sets the fee and fee recipient.
   */
  function leverage() external;

  /**
   * This function unwinds the net position in AAVE to match net deposits
   * @notice There needs to be at least a difference of $10k
   */
  function unwind() external;

  /**
   * This function rebalances the position between the short and the long
   * @notice The position health factor needs to be outside the range
   */
  function rebalance() external;

  // /**
  //  * This function checks if there is any work needed to be performed by keepers
  //  * @return upkeepNeeded Whether work needs to be performed
  //  * @return performData Encoded data that contains the id of the op to perform
  //  */
  // function checkUpkeep(
  //     bytes calldata checkData
  // ) external view returns (bool upkeepNeeded, bytes memory performData);
  //
  // /**
  //  * This function performs the work according to the operation passed in bytes
  //  * @param _performData Data that contains the uint8 with the operation to perform
  //  */
  // function performUpkeep(bytes calldata _performData) external;

  /* ============ External View Functions ============ */

  /**
   * @notice This function returns the amount of underlying returned per 1e18 share
   * @return uint256 Amount of underlying per share
   */
  function pricePerShare() external view returns (uint256);

  /**
   * @notice This function returns the total amount of underlying assets held by the vault.
   * @return uint256 Total number of AUM
   */
  function totalAssets() external view returns (uint256);

  /**
   * @notice This function returns the address of the underlying token used for the vault for accounting, depositing, withdrawing.
   * @return address Vault underlying asset
   */
  function asset() external view returns (address);

  /**
   * @notice This function returns the amount of shares that would be exchanged by the vault for the amount of assets provided.
   * @param _assets Number of units of the underlying to be converted to shares at the current price
   * @return _shares Number of shares to receive
   */
  function convertToShares(uint256 _assets) external view returns (uint256 _shares);


  /**
  * @notice
  * This function returns the amount of assets that would be exchanged by the vault for the amount of shares provided.
  * @param _shares Number of shares to be exchanged to units of the underlying assets
  * @return _assets Number of units of the underlying asset that match the shares
  */
  function convertToAssets(uint256 _shares) external view returns (uint256 _assets);

  /**
   * @notice This function returns the maximum amount of underlying assets that can be deposited in a single deposit call by the receiver.
   * @param _receiver Depositor
   * @return uint256 Max amount of underlying assets to deposit
  */
  function maxDeposit(address _receiver) external view returns (uint256);

  /**
   * @notice This function allows users to simulate the effects of their deposit at the current block.
   * @param _assets Number of units of the underlying to deposit
   * @return uint256 Amount of shares to be received upon deposit
  */
  function previewDeposit(uint256 _assets) external view returns (uint256);

  /**
   * @notice This function returns the maximum amount of shares that can be minted in a single mint call by the receiver.
   * @param _receiver Receiver address
   * @return uint256 Max amount of shares that can be minted
   */
  function maxMint(address _receiver) external view returns (uint256);

  /**
   * @notice This function allows users to simulate the effects of their mint at the current block.
   * @param _shares Shares to mint
   * @return uint256 Amount of underlying assets to receive
   */
  function previewMint(uint256 _shares) external view returns (uint256);
  /**
   * @notice This function returns the maximum amount of underlying assets that can be withdrawn from the owner balance with a single withdraw call.
   * @param _owner Owner of the ERC-20 tokens
   * @return uint256 underlying assets to receive
  */
  function maxWithdraw(address _owner) external view returns (uint256);

  /**
   * @notice This function allows users to simulate the effects of their withdrawal at the current block.
   * @param _assets Number of underlying assets to withdraw
   * @return uint256 shares to burn
  */
  function previewWithdraw(uint256 _assets) external view returns (uint256);
  /**
   * @notice This function returns the maximum amount of shares that can be redeem from the owner balance through a redeem call.
   * @param _owner Owner of the vault token shares
   * @return uint256 Returns the max amount of shares that can be redeemed
   */
  function maxRedeem(address _owner) external view returns (uint256);

  /**
   * @notice This function allows users to simulate the effects of their redeemption at the current block.
   * @param _shares Shares to redeem
   * @return uint256 Number of underlying assets to receive
   */
  function previewRedeem(uint256 _shares) external view returns (uint256);

  /**
   * Get the amount of borrowed debt that needs to be repaid
   * @param _asset     The underlying asset
   * @return uint256   The borrowed balance of the asset
   */
  function getBorrowBalance(address _asset) external view returns (uint256);

  /**
   * More info https://docs.aave.com/developers/v/2.0/the-core-protocol/lendingpool#getuseraccountdata
   * Returns the status of the position. The keeper acts based on this information
   * @return bool Whether the position needs to be acted upon
   * @return uint256 Health factor of the account
   * @return uint256 Net value of the position in DAI
   */
  function getAaveAccountStatus() external view returns (bool, uint256, uint256);

  // Attr viewers
  function feeRecipient() external view returns (address);

  function fee() external view returns (uint256);

  function currentDeposits() external view returns (uint256);

  function owner() external view returns (address);

  function lastDepositAt(address _depositor) external view returns (uint256);

  function shortLeverageTimes() external view returns (uint8);

  function longLeverageTimes() external view returns (uint8);

}