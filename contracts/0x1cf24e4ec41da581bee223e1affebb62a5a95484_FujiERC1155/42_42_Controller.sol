// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IVault } from "./Vaults/IVault.sol";
import { IProvider } from "./Providers/IProvider.sol";
import { Flasher } from "./Flashloans/Flasher.sol";
import { FlashLoan } from "./Flashloans/LibFlashLoan.sol";
import { IFujiAdmin } from "./IFujiAdmin.sol";
import { Errors } from "./Libraries/Errors.sol";

//import "hardhat/console.sol"; //test line

interface IVaultExt is IVault {

  //Asset Struct
  struct VaultAssets {
    address collateralAsset;
    address borrowAsset;
    uint64 collateralID;
    uint64 borrowID;
  }

  function vAssets() external view returns(VaultAssets memory);

}

interface IProviderExt is IProvider {
  // Temp
  function getBorrowBalanceExact(address _asset, address who) external returns(uint256);
}


contract Controller is Ownable {

  using SafeMath for uint256;

  IFujiAdmin private _fujiAdmin;

  //Refinancing Variables
  bool public greenLight;
  //uint256 public lastRefinancetimestamp;

  //deltaAPRThreshold: Expressed in ray (1e27), where 1ray = 100% APR
  uint256 public deltaAPRThreshold;

  //Modifiers
  modifier isAuthorized() {
    require(
      msg.sender == owner() ||
      msg.sender == address(this),
      Errors.VL_NOT_AUTHORIZED);
    _;
  }

  constructor() public {

    deltaAPRThreshold = 1e25;
    greenLight = false;

  }

  //Administrative functions

  /**
  * @dev Sets the fujiAdmin Address
  * @param _newFujiAdmin: FujiAdmin Contract Address
  */
  function setFujiAdmin(address _newFujiAdmin) public isAuthorized{
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
  }

  /**
  * @dev Changes the conditional Threshold for a provider switch
  * @param _newThreshold: percent decimal in ray (example 25% =.25 x10^27)
  */
  function setDeltaAPRThreshold(uint256 _newThreshold) external isAuthorized {
    deltaAPRThreshold = _newThreshold;
  }

  /**
  * @dev Sets the Green light to proceed with a Refinancing opportunity
  * @param _lightstate: True or False
  */
  function setLight(bool _lightstate) public isAuthorized {
    greenLight = _lightstate;
  }

  /**
  * @dev Sets a new provider to called Vault, returns true on success
  * @param _vaultAddr: fuji Vault address to which active provider will change
  * @param _newProviderAddr: fuji address of new Provider
  */
  function _setProvider(address _vaultAddr,address _newProviderAddr) internal {
    //Create vault instance and call setActiveProvider method in that vault.
    IVault(_vaultAddr).setActiveProvider(_newProviderAddr);
  }

  /**
  * @dev Sets current timestamp after a refinancing cycle
  */
  /*
  function _setRefinanceTimestamp() internal {
    lastRefinancetimestamp = block.timestamp;
  }
  */

  //Controller Core functions

  /**
  * @dev Performs refinancing routine, performs checks for verification
  * @param _vaultAddr: fuji Vault address
  * @param _ratioA: ratio to determine how much of debtposition to move
  * @param _ratioB: _ratioA/_ratioB <= 1, and > 0
  * @param _flashnum: integer identifier of flashloan provider
  * @param isCompoundActiveProvider: indicate if activeProvider is Compound
  */
  function doRefinancing(
    address _vaultAddr,
    uint256 _ratioA,
    uint256 _ratioB,
    uint8 _flashnum,
    bool isCompoundActiveProvider
  ) external {

    // Check Protocol have allowed to refinance
    require(
      greenLight,
      Errors.RF_NO_GREENLIGHT
    );

    IVault vault = IVault(_vaultAddr);
    vault.updateF1155Balances();
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vaultAddr).vAssets();

    // Check if there is an opportunity to Change provider with a lower borrowing Rate
    (bool opportunityTochange, address newProvider) = checkRates(_vaultAddr);

    require(opportunityTochange,Errors.RF_CHECK_RATES_FALSE);

    // Check Vault borrowbalance and apply ratio (consider compound or not)
    uint256 debtPosition = isCompoundActiveProvider ?
    IProviderExt(
      vault.activeProvider()).getBorrowBalanceExact(vAssets.borrowAsset,_vaultAddr) :
      vault.borrowBalance(vault.activeProvider());
    uint256 applyRatiodebtPosition = debtPosition.mul(_ratioA).div(_ratioB);

    // Check Ratio Input and Vault Balance at ActiveProvider
    require(
      debtPosition >= applyRatiodebtPosition &&
      applyRatiodebtPosition > 0,
      Errors.RF_INVALID_RATIO_VALUES
    );

    greenLight = false;

    //Initiate Flash Loan Struct
    FlashLoan.Info memory info = FlashLoan.Info({
      callType: FlashLoan.CallType.Switch,
      asset: vAssets.borrowAsset,
      amount: applyRatiodebtPosition,
      vault: _vaultAddr,
      newProvider: newProvider,
      user: address(0),
      userliquidator: address(0),
      fliquidator: address(0)
    });

    Flasher(payable(_fujiAdmin.getFlasher())).initiateFlashloan(info, _flashnum);

    //Set the new provider in the Vault
    _setProvider(_vaultAddr, newProvider);
  }

  /**
  * @dev Performs a forced refinancing routine
  * @param _vaultAddr: fuji Vault address
  * @param _newProvider: new provider address
  * @param _ratioA: ratio to determine how much of debtposition to move
  * @param _ratioB: _ratioA/_ratioB <= 1, and > 0
  * @param _flashnum: integer identifier of flashloan provider
  * @param isCompoundActiveProvider: indicate if activeProvider is Compound
  */
  function forcedRefinancing(
    address _vaultAddr,
    address _newProvider,
    uint256 _ratioA,
    uint256 _ratioB,
    uint8 _flashnum,
    bool isCompoundActiveProvider
  ) external isAuthorized {

    IVault vault = IVault(_vaultAddr);
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vaultAddr).vAssets();
    vault.updateF1155Balances();

    // Check Vault borrowbalance and apply ratio (consider compound or not)
    uint256 debtPosition = isCompoundActiveProvider ?
    IProviderExt(
      vault.activeProvider()).getBorrowBalanceExact(vAssets.borrowAsset,_vaultAddr) :
      vault.borrowBalance(vault.activeProvider());
    uint256 applyRatiodebtPosition = debtPosition.mul(_ratioA).div(_ratioB);

    // Check Ratio Input and Vault Balance at ActiveProvider
    require(
      debtPosition >= applyRatiodebtPosition &&
      applyRatiodebtPosition > 0,
      Errors.RF_INVALID_RATIO_VALUES
    );

    //Initiate Flash Loan Struct
    FlashLoan.Info memory info = FlashLoan.Info({
      callType: FlashLoan.CallType.Switch,
      asset: vAssets.borrowAsset,
      amount: applyRatiodebtPosition,
      vault: _vaultAddr,
      newProvider: _newProvider,
      user: address(0),
      userliquidator: address(0),
      fliquidator: address(0)
    });

    Flasher(payable(_fujiAdmin.getFlasher())).initiateFlashloan(info, _flashnum);

  }

  /**
  * @dev Compares borrowing rates from providers of a vault
  * @param _vaultAddr: Fuji vault address
  */
  function checkRates(address _vaultAddr) public view returns(bool opportunityTochange, address newProvider) {
    //Get the array of Providers from _vaultAddr
    address[] memory arrayOfProviders = IVault(_vaultAddr).getProviders();
    IVaultExt.VaultAssets memory vAssets = IVaultExt(_vaultAddr).vAssets();

    //Call and check borrow rates for all Providers in array for _vaultAddr
    uint256 currentRate = IProvider(IVault(_vaultAddr).activeProvider()).getBorrowRateFor(vAssets.borrowAsset);
    uint256 newRate = currentRate;

    for (uint i=0; i < arrayOfProviders.length; i++) {
      if(
        newRate > IProvider(arrayOfProviders[i]).getBorrowRateFor(vAssets.borrowAsset)
      ){
        newProvider = arrayOfProviders[i];
        newRate = IProvider(arrayOfProviders[i]).getBorrowRateFor(vAssets.borrowAsset);
      }
    }
    if( currentRate.sub(newRate) >= deltaAPRThreshold) {
      opportunityTochange = true;
    }
  }
}