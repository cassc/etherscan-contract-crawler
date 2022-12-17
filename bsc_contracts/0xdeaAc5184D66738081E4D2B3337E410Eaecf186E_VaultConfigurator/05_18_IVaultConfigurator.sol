pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

interface IVaultConfigurator {

  struct InitReserveInput {
    address oTokenImpl;
    uint8 underlyingAssetDecimals;
    address underlyingAsset;
    address fundAddress;
    string underlyingAssetName;
    string oTokenName;
    string oTokenSymbol;
    bytes params;
  }

  struct InitOtokenInput {
    address asset;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  struct UpdateOTokenInput {
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  /**
   * @dev Emitted when a reserve is initialized.
   * @param oToken The address of the associated oToken contract
   **/
  event ReserveInitialized(
    address indexed asset,
    address indexed oToken
  );

  /**
   * @dev Emitted when an oToken implementation is upgraded
   * @param proxy The oToken proxy address
   * @param implementation The new oToken implementation
   **/
  event OTokenUpgraded(
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when a reserve is activated
   **/
  event ReserveActivated();

  /**
   * @dev Emitted when a reserve is deactivated
   **/
  event ReserveDeactivated();

  /**
   * @dev Emitted when a reserve is frozen
   **/
  event ReserveFrozen();

  /**
   * @dev Emitted when a reserve is unfrozen
   **/
  event ReserveUnfrozen();
}