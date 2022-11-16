// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ISoloMargin.sol";

import '../IWETH.sol';
import '../IFlashLoan.sol';

contract DydxFlashloanBase {
  using SafeMath for uint;

  address constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
  address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  struct FlashLoanDydxData {
    address user;
    address aggregator;
    uint256 value;
    bytes trades;
  }

  // -- Internal Helper functions -- //

  function _getMarketIdFromTokenAddress(address _solo, address token)
    internal
    view
    returns (uint)
  {
    ISoloMargin solo = ISoloMargin(_solo);

    uint numMarkets = solo.getNumMarkets();

    address curToken;
    for (uint i = 0; i < numMarkets; i++) {
      curToken = solo.getMarketTokenAddress(i);

      if (curToken == token) {
        return i;
      }
    }

    revert("No marketId found for provided token");
  }

  function _getRepaymentAmountInternal(uint amount) internal pure returns (uint) {
    // Needs to be overcollateralize
    // Needs to provide +2 wei to be safe
    return amount.add(2);
  }

  function _getAccountInfo() internal view returns (Account.Info memory) {
    return Account.Info({owner: address(this), number: 1});
  }

  function _getWithdrawAction(uint marketId, uint amount)
    internal
    view
    returns (Actions.ActionArgs memory)
  {
    return
      Actions.ActionArgs({
        actionType: Actions.ActionType.Withdraw,
        accountId: 0,
        amount: Types.AssetAmount({
          sign: false,
          denomination: Types.AssetDenomination.Wei,
          ref: Types.AssetReference.Delta,
          value: amount
        }),
        primaryMarketId: marketId,
        secondaryMarketId: 0,
        otherAddress: address(this),
        otherAccountId: 0,
        data: ""
      });
  }

  function _getCallAction(bytes memory data)
    internal
    view
    returns (Actions.ActionArgs memory)
  {
    return
      Actions.ActionArgs({
        actionType: Actions.ActionType.Call,
        accountId: 0,
        amount: Types.AssetAmount({
          sign: false,
          denomination: Types.AssetDenomination.Wei,
          ref: Types.AssetReference.Delta,
          value: 0
        }),
        primaryMarketId: 0,
        secondaryMarketId: 0,
        otherAddress: address(this),
        otherAccountId: 0,
        data: data
      });
  }

  function _getDepositAction(uint marketId, uint amount)
    internal
    view
    returns (Actions.ActionArgs memory)
  {
    return
      Actions.ActionArgs({
        actionType: Actions.ActionType.Deposit,
        accountId: 0,
        amount: Types.AssetAmount({
          sign: true,
          denomination: Types.AssetDenomination.Wei,
          ref: Types.AssetReference.Delta,
          value: amount
        }),
        primaryMarketId: marketId,
        secondaryMarketId: 0,
        otherAddress: address(this),
        otherAccountId: 0,
        data: ""
      });
  }

  function callFunction(
      address sender,
      Account.Info memory account,
      bytes memory data
  ) public virtual {
    require(msg.sender == SOLO, "!dydx solo");
    require(sender == address(this), "!this contract");

    FlashLoanDydxData memory mcd = abi.decode(data, (FlashLoanDydxData));

    // convert WETH to ETH
    IWETH(WETH).withdraw(mcd.value);

    // transfer ETH to loaner
    payable(mcd.user).transfer(mcd.value);

    // calculate repay amount (_amount + (2 wei))
    uint repayAmount = _getRepaymentAmountInternal(mcd.value);
    uint fee = repayAmount - mcd.value;

    // proceed trades
    IFlashLoanReceiver(mcd.user).onFlashLoanReceived(mcd.aggregator, mcd.value, fee, mcd.trades);

    // no need send to dydx here, it will be repaid automatically
    // Repay ETH(Convert to WETH and approve for repay)
    IWETH(WETH).deposit{value: repayAmount}();
    IERC20(WETH).approve(SOLO, repayAmount);
  }
}