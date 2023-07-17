// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.5;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { UniERC20 } from "../Libraries/LibUniERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IProvider } from "./IProvider.sol";

interface IWethERC20 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

interface SoloMarginContract {
  struct Info {
    address owner;
    uint256 number;
  }

  struct Price {
    uint256 value;
  }

  struct Value {
    uint256 value;
  }

  struct Rate {
    uint256 value;
  }

  enum ActionType { Deposit, Withdraw, Transfer, Buy, Sell, Trade, Liquidate, Vaporize, Call }

  enum AssetDenomination { Wei, Par }

  enum AssetReference { Delta, Target }

  struct AssetAmount {
    bool sign;
    AssetDenomination denomination;
    AssetReference ref;
    uint256 value;
  }

  struct ActionArgs {
    ActionType actionType;
    uint256 accountId;
    AssetAmount amount;
    uint256 primaryMarketId;
    uint256 secondaryMarketId;
    address otherAddress;
    uint256 otherAccountId;
    bytes data;
  }

  struct Wei {
    bool sign;
    uint256 value;
  }

  function operate(Info[] calldata _accounts, ActionArgs[] calldata _actions) external;

  function getAccountWei(Info calldata _account, uint256 _marketId)
    external
    view
    returns (Wei memory);

  function getNumMarkets() external view returns (uint256);

  function getMarketTokenAddress(uint256 _marketId) external view returns (address);

  function getAccountValues(Info memory _account)
    external
    view
    returns (Value memory, Value memory);

  function getMarketInterestRate(uint256 _marketId) external view returns (Rate memory);
}

contract HelperFunct {
  /**
   * @dev get Dydx Solo Address
   */
  function getDydxAddress() public pure returns (address addr) {
    addr = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
  }

  /**
   * @dev get WETH address
   */
  function getWETHAddr() public pure returns (address weth) {
    weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  }

  /**
   * @dev Return ethereum address
   */
  function _getEthAddr() internal pure returns (address) {
    return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
  }

  /**
   * @dev Get Dydx Market ID from token Address
   */
  function _getMarketId(SoloMarginContract _solo, address _token)
    internal
    view
    returns (uint256 _marketId)
  {
    uint256 markets = _solo.getNumMarkets();
    address token = _token == _getEthAddr() ? getWETHAddr() : _token;
    bool check = false;
    for (uint256 i = 0; i < markets; i++) {
      if (token == _solo.getMarketTokenAddress(i)) {
        _marketId = i;
        check = true;
        break;
      }
    }
    require(check, "DYDX Market doesnt exist!");
  }

  /**
   * @dev Get Dydx Acccount arg
   */
  function _getAccountArgs() internal view returns (SoloMarginContract.Info[] memory) {
    SoloMarginContract.Info[] memory accounts = new SoloMarginContract.Info[](1);
    accounts[0] = (SoloMarginContract.Info(address(this), 0));
    return accounts;
  }

  /**
   * @dev Get Dydx Actions args.
   */
  function _getActionsArgs(
    uint256 _marketId,
    uint256 _amt,
    bool _sign
  ) internal view returns (SoloMarginContract.ActionArgs[] memory) {
    SoloMarginContract.ActionArgs[] memory actions = new SoloMarginContract.ActionArgs[](1);
    SoloMarginContract.AssetAmount memory amount =
      SoloMarginContract.AssetAmount(
        _sign,
        SoloMarginContract.AssetDenomination.Wei,
        SoloMarginContract.AssetReference.Delta,
        _amt
      );
    bytes memory empty;
    SoloMarginContract.ActionType action =
      _sign ? SoloMarginContract.ActionType.Deposit : SoloMarginContract.ActionType.Withdraw;
    actions[0] = SoloMarginContract.ActionArgs(
      action,
      0,
      amount,
      _marketId,
      0,
      address(this),
      0,
      empty
    );
    return actions;
  }
}

contract ProviderDYDX is IProvider, HelperFunct {
  using SafeMath for uint256;
  using UniERC20 for IERC20;

  bool public donothing = true;

  //Provider Core Functions

  /**
   * @dev Deposit ETH/ERC20_Token.
   * @param _asset: token address to deposit. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to deposit.
   */
  function deposit(address _asset, uint256 _amount) external payable override {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

    uint256 marketId = _getMarketId(dydxContract, _asset);

    if (_asset == _getEthAddr()) {
      IWethERC20 tweth = IWethERC20(getWETHAddr());
      tweth.deposit{ value: _amount }();
      tweth.approve(getDydxAddress(), _amount);
    } else {
      IWethERC20 tweth = IWethERC20(_asset);
      tweth.approve(getDydxAddress(), _amount);
    }

    dydxContract.operate(_getAccountArgs(), _getActionsArgs(marketId, _amount, true));
  }

  /**
   * @dev Withdraw ETH/ERC20_Token.
   * @param _asset: token address to withdraw. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to withdraw.
   */
  function withdraw(address _asset, uint256 _amount) external payable override {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

    uint256 marketId = _getMarketId(dydxContract, _asset);

    dydxContract.operate(_getAccountArgs(), _getActionsArgs(marketId, _amount, false));

    if (_asset == _getEthAddr()) {
      IWethERC20 tweth = IWethERC20(getWETHAddr());

      tweth.approve(address(tweth), _amount);

      tweth.withdraw(_amount);
    }
  }

  /**
   * @dev Borrow ETH/ERC20_Token.
   * @param _asset token address to borrow.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to borrow.
   */
  function borrow(address _asset, uint256 _amount) external payable override {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

    uint256 marketId = _getMarketId(dydxContract, _asset);

    dydxContract.operate(_getAccountArgs(), _getActionsArgs(marketId, _amount, false));

    if (_asset == _getEthAddr()) {
      IWethERC20 tweth = IWethERC20(getWETHAddr());

      tweth.approve(address(_asset), _amount);

      tweth.withdraw(_amount);
    }
  }

  /**
   * @dev Payback borrowed ETH/ERC20_Token.
   * @param _asset token address to payback.(For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
   * @param _amount: token amount to payback.
   */
  function payback(address _asset, uint256 _amount) external payable override {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());

    uint256 marketId = _getMarketId(dydxContract, _asset);

    if (_asset == _getEthAddr()) {
      IWethERC20 tweth = IWethERC20(getWETHAddr());
      tweth.deposit{ value: _amount }();
      tweth.approve(getDydxAddress(), _amount);
    } else {
      IWethERC20 tweth = IWethERC20(_asset);
      tweth.approve(getDydxAddress(), _amount);
    }

    dydxContract.operate(_getAccountArgs(), _getActionsArgs(marketId, _amount, true));
  }

  /**
   * @dev Returns the current borrowing rate (APR) of a ETH/ERC20_Token, in ray(1e27).
   * @param _asset: token address to query the current borrowing rate.
   */
  function getBorrowRateFor(address _asset) external view override returns (uint256) {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());
    uint256 marketId = _getMarketId(dydxContract, _asset);
    SoloMarginContract.Rate memory _rate = dydxContract.getMarketInterestRate(marketId);
    return (_rate.value).mul(1e9).mul(365 days);
  }

  /**
   * @dev Returns the borrow balance of a ETH/ERC20_Token.
   * @param _asset: token address to query the balance.
   */
  function getBorrowBalance(address _asset) external view override returns (uint256) {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());
    uint256 marketId = _getMarketId(dydxContract, _asset);
    SoloMarginContract.Info memory account =
      SoloMarginContract.Info({ owner: msg.sender, number: 0 });
    SoloMarginContract.Wei memory structbalance = dydxContract.getAccountWei(account, marketId);
    return structbalance.value;
  }

  /**
   * @dev Returns the borrow balance of a ETH/ERC20_Token.
   * @param _asset: token address to query the balance.
   */
  function getDepositBalance(address _asset) external view override returns (uint256) {
    SoloMarginContract dydxContract = SoloMarginContract(getDydxAddress());
    uint256 marketId = _getMarketId(dydxContract, _asset);
    SoloMarginContract.Info memory account =
      SoloMarginContract.Info({ owner: msg.sender, number: 0 });
    SoloMarginContract.Wei memory structbalance = dydxContract.getAccountWei(account, marketId);
    return structbalance.value;
  }
}