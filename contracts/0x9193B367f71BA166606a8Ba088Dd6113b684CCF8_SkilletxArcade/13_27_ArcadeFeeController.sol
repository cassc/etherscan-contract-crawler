//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "./interfaces/ILoanCore.sol";
import "./interfaces/IFeeController.sol";
import "./ArcadeAddressProvider.sol";

contract ArcadeFeeController is ArcadeAddressProvider {

  /**
   * Get Fee Controller
   * https://etherscan.io/address/0x81b2f8fc75bab64a6b144aa6d2faa127b4fa7fd9#readProxyContract#F12
   */
  function getFeeControllerAddress() 
    public
    view
    returns (address feeControllerAddress)
  {
    ILoanCore loanCore = ILoanCore(loanCoreAddress);
    feeControllerAddress = loanCore.feeController();
  }

  /**
   * Calculate the fee for originating a new loan
   * @return fee net fee given amount and originationFee
   */
  function calculateOriginationFee(uint256 amount) 
    public
    view
    returns (uint256 fee)
  {
    IFeeController feeController = IFeeController(getFeeControllerAddress());
    uint256 originationFee = feeController.getOriginationFee();

    fee = amount * originationFee / 10000;
  }

  /**
   * Calculate the fee for rolling over into a new loan
   * @return fee net fee given amount and rolloverFee
   */
  function calculateRolloverFee(uint256 amount)
    public
    view
    returns (uint256 fee)
  {
    IFeeController feeController = IFeeController(getFeeControllerAddress());
    uint256 rolloverFee = feeController.getRolloverFee();

    fee = amount * rolloverFee / 10000;
  }
}