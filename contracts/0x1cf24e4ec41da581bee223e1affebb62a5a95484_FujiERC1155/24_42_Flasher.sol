// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;
pragma experimental ABIEncoderV2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { UniERC20 } from "../Libraries/LibUniERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IFujiAdmin } from "../IFujiAdmin.sol";
import { Errors } from '../Libraries/Errors.sol';

import { ILendingPool, IFlashLoanReceiver } from "./AaveFlashLoans.sol";
import {
  Actions,
  Account,
  DyDxFlashloanBase,
  ICallee,
  ISoloMargin
} from "./DyDxFlashLoans.sol";
import { FlashLoan } from "./LibFlashLoan.sol";
import { IVault } from "../Vaults/IVault.sol";

interface IFliquidator {

  function executeFlashClose(address _userAddr, address vault, uint256 _Amount, uint256 flashloanfee) external;

  function executeFlashLiquidation(address _userAddr,address _liquidatorAddr, address vault, uint256 _debtAmount, uint256 flashloanfee) external;
}

contract Flasher is
  DyDxFlashloanBase,
  IFlashLoanReceiver,
  ICallee,
  Ownable
{

  using SafeMath for uint256;
  using UniERC20 for IERC20;

  IFujiAdmin private _fujiAdmin;

  address public aave_lending_pool;
  address public dydx_solo_margin;

  receive() external payable {}

  constructor() public {

    aave_lending_pool = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    dydx_solo_margin = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

  }

  modifier isAuthorized() {
    require(
      msg.sender == _fujiAdmin.getController() ||
      msg.sender == _fujiAdmin.getFliquidator() ||
      msg.sender == owner(),
      Errors.VL_NOT_AUTHORIZED
    );
    _;
  }

  modifier isAuthorizedExternal() {
    require(
      msg.sender == dydx_solo_margin ||
      msg.sender == aave_lending_pool,
      Errors.VL_NOT_AUTHORIZED
    );
    _;
  }

  /**
  * @dev Sets the fujiAdmin Address
  * @param _newFujiAdmin: FujiAdmin Contract Address
  */
  function setFujiAdmin(address _newFujiAdmin) public onlyOwner {
    _fujiAdmin = IFujiAdmin(_newFujiAdmin);
  }


  /**
  * @dev Routing Function for Flashloan Provider
  * @param info: struct information for flashLoan
  * @param _flashnum: integer identifier of flashloan provider
  */
  function initiateFlashloan(FlashLoan.Info memory info, uint8 _flashnum) public isAuthorized {
    if(_flashnum==0) {
      initiateAaveFlashLoan(info);
    } else if(_flashnum==1) {
      initiateDyDxFlashLoan(info);
    }
  }

  // ===================== DyDx FlashLoan ===================================

  /**
  * @dev Initiates a DyDx flashloan.
  * @param info: data to be passed between functions executing flashloan logic
  */
  function initiateDyDxFlashLoan(
    FlashLoan.Info memory info
  ) internal {

    ISoloMargin solo = ISoloMargin(dydx_solo_margin);

    // Get marketId from token address
    uint256 marketId = _getMarketIdFromTokenAddress(solo, info.asset);

    // 1. Withdraw $
    // 2. Call callFunction(...)
    // 3. Deposit back $
    Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

    operations[0] = _getWithdrawAction(marketId, info.amount);
    // Encode FlashLoan.Info for callFunction
    operations[1] = _getCallAction(abi.encode(info));
    // add fee of 2 wei
    operations[2] = _getDepositAction(marketId, info.amount.add(2));

    Account.Info[] memory accountInfos = new Account.Info[](1);
    accountInfos[0] = _getAccountInfo(address(this));

    solo.operate(accountInfos, operations);
  }

  /**
  * @dev Executes DyDx Flashloan, this operation is required
  * and called by Solo when sending loaned amount
  * @param sender: Not used
  * @param account: Not used
  */
  function callFunction(
    address sender,
    Account.Info memory account,
    bytes memory data
  ) external override isAuthorizedExternal {
    sender;
    account;

    FlashLoan.Info memory info = abi.decode(data, (FlashLoan.Info));

    //Estimate flashloan payback + premium fee of 2 wei,
    uint amountOwing = info.amount.add(2);

    // Transfer to Vault the flashloan Amount
    IERC20(info.asset).uniTransfer(payable(info.vault), info.amount);

    if (info.callType == FlashLoan.CallType.Switch) {
      IVault(info.vault)
      .executeSwitch(info.newProvider, info.amount, 2);
    }
    else if (info.callType == FlashLoan.CallType.Close) {
      IFliquidator(info.fliquidator)
      .executeFlashClose(info.user, info.vault, info.amount, 2);
    }
    else {
      IFliquidator(info.fliquidator)
      .executeFlashLiquidation(info.user, info.userliquidator, info.vault, info.amount, 2);
    }

    //Approve DYDXSolo to spend to repay flashloan
    IERC20(info.asset).approve(dydx_solo_margin, amountOwing);
  }


  // ===================== Aave FlashLoan ===================================

  /**
  * @dev Initiates an Aave flashloan.
  * @param info: data to be passed between functions executing flashloan logic
  */
  function initiateAaveFlashLoan(
    FlashLoan.Info memory info
  ) internal {

    //Initialize Instance of Aave Lending Pool
    ILendingPool aaveLp = ILendingPool(aave_lending_pool);

    //Passing arguments to construct Aave flashloan -limited to 1 asset type for now.
    address receiverAddress = address(this);
    address[] memory assets = new address[](1);
    assets[0] = address(info.asset);
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = info.amount;

    // 0 = no debt, 1 = stable, 2 = variable
    uint256[] memory modes = new uint256[](1);
    modes[0] = 0;

    address onBehalfOf = address(this);
    bytes memory params = abi.encode(info);
    uint16 referralCode = 0;

    //Aave Flashloan initiated.
    aaveLp.flashLoan(
      receiverAddress,
      assets,
      amounts,
      modes,
      onBehalfOf,
      params,
      referralCode
    );
  }

  /**
  * @dev Executes Aave Flashloan, this operation is required
  * and called by Aaveflashloan when sending loaned amount
  */
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external override isAuthorizedExternal returns (bool) {
    initiator;

    FlashLoan.Info memory info = abi.decode(params, (FlashLoan.Info));

    //Estimate flashloan payback + premium fee,
    uint amountOwing = amounts[0].add(premiums[0]);

    // Transfer to the vault ERC20
    IERC20(assets[0]).uniTransfer(payable(info.vault), amounts[0]);

    if (info.callType == FlashLoan.CallType.Switch) {
      IVault(info.vault)
      .executeSwitch(info.newProvider, amounts[0], premiums[0]);
    }
    else if (info.callType == FlashLoan.CallType.Close) {
      IFliquidator(info.fliquidator)
      .executeFlashClose(info.user, info.vault, amounts[0], premiums[0]);
    }
    else {
      IFliquidator(info.fliquidator)
      .executeFlashLiquidation(info.user, info.userliquidator, info.vault, amounts[0],premiums[0]);
    }

    //Approve aaveLP to spend to repay flashloan
    IERC20(assets[0]).uniApprove(payable(aave_lending_pool), amountOwing);

    return true;
  }

}