// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IVault } from './Vault.sol';
import { IERC20 } from '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IDex } from './IDex.sol';

contract Dex is IDex {
  struct RateValues {
    uint256 stable;
    uint256 own;
  }

  bool public isPaused = true;
  // Переменные используемые для вычисления цены
  RateValues public rateValues;
  IERC20 public ownCoin;
  IERC20 public stableCoin;
  IVault public vaultContract;

  address private owner;
  mapping (address => bool) private operators;
  mapping (address => RateValues) private bookingPrices;

  event BuyToken(address user, uint256 onwCoinAmount, uint256 stableCoinAmount);
  event SellToken(address user, uint256 onwCoinAmount, uint256 stableCoinAmount);
  event UpdatePrice(RateValues rateValues);

  // Модификатор доступа владельца
  modifier OnlyOwner() {
    require(owner == msg.sender, 'Permission denied: Owner');
    _;
  }

  // Модификатор доступа оператора
  modifier OnlyOperator() {
    require(operators[msg.sender], 'Permission denied: Operator');
    _;
  }

  // Модификатор доступа оператора или хранилища
  modifier OnlyOperatorOrVault() {
    require((
      operators[msg.sender] || address(vaultContract) == msg.sender
    ), 'Permission denied: Operator or Vault');
    _;
  }

  // Модификатор доступа хранилища
  modifier OnlyVault() {
    require(address(vaultContract) == msg.sender, 'Permission denied: Vault');
    _;
  }

  modifier NotPaused() {
    require(!isPaused, 'Dex operations is paused');
    _;
  }

  constructor() {
    owner = msg.sender;
    operators[msg.sender] = true;
  }

  function _setPause(bool pause) public OnlyOwner {
    isPaused = pause;
  }

  // Сменить владельца
  function _changeOwner(address newOwner) public OnlyOwner {
    owner = newOwner;
  }

  // Установить стейбл-коин
  function _setStableCoin(address tokenAddress) public OnlyOwner {
    stableCoin = IERC20(tokenAddress);
  }

  // Установить свой коин
  function _setOwnCoin(address tokenAddress) public OnlyOwner {
    ownCoin = IERC20(tokenAddress);
  }

  // Установить контракт хранилища
  function _setVaultContract(address vaultAddress) public OnlyOwner {
    vaultContract = IVault(vaultAddress);
  }

  // Добавить оператора
  function _addOperator(address operator) public OnlyOwner {
    operators[operator] = true;
  }

  // Удалить оператора
  function _removeOperator(address operator) public OnlyOwner {
    delete operators[operator];
  }

  // Установить rateValues
  function _setPriceRate(uint256 stable, uint256 own) public OnlyOperatorOrVault {
    rateValues = RateValues({
      stable: stable,
      own: own
    });

    emit UpdatePrice(rateValues);
  }

  // Обмен stableCoin на ownCoin
  function deposit(uint256 maxAmountToSell, uint256 amountToBuy) public NotPaused {
    require((
      maxAmountToSell * rateValues.own >= rateValues.stable * amountToBuy
    ), 'Price has been increased');

    uint256 realAmountToSell = amountToBuy * rateValues.stable / rateValues.own;

    require(realAmountToSell > 0, 'Too little amout to sell');
    require(amountToBuy > 0, 'Too little amout to buy');

    vaultContract._setAllowance(ownCoin, address(this), amountToBuy);
    stableCoin.transferFrom(msg.sender, address(vaultContract), realAmountToSell);
    ownCoin.transferFrom(address(vaultContract), msg.sender, amountToBuy);

    emit BuyToken(msg.sender, amountToBuy, realAmountToSell);
  }

  // Обмен ownCoin на stableCoin
  function withdraw(uint256 maxAmountToSell, uint256 amountToBuy) public NotPaused returns (bool) {
    require((
      amountToBuy * rateValues.own <= rateValues.stable * maxAmountToSell
    ), 'Price has been decreased');

    uint256 availableAmount = vaultContract.getAvailableAmount();

    // Если в хранилище нет доступного баланса, делаем букинг
    if (availableAmount < amountToBuy) {
      vaultContract._makeBooking(msg.sender, amountToBuy);

      bookingPrices[msg.sender] = RateValues({
        stable: rateValues.stable,
        own: rateValues.own
      });

      return false;
    }

    uint256 realAmountToSell = amountToBuy * rateValues.own / rateValues.stable;

    require(realAmountToSell > 0, 'Too little amout to sell');
    require(amountToBuy > 0, 'Too little amout to buy');

    vaultContract._setAllowance(stableCoin, address(this), amountToBuy);
    ownCoin.transferFrom(msg.sender, address(vaultContract), realAmountToSell);
    stableCoin.transferFrom(address(vaultContract), msg.sender, amountToBuy);

    emit SellToken(msg.sender, realAmountToSell, amountToBuy);
    return true;
  }

  // Завершение сделки по бронированию
  function _completeBooking(address recepient, uint256 amountToBuy) public OnlyVault NotPaused {
    RateValues memory bookedRateValues = bookingPrices[recepient];
    uint256 amountToSell = amountToBuy * bookedRateValues.own / bookedRateValues.stable;

    require(amountToSell > 0, 'Too little amout to sell');
    require(amountToBuy > 0, 'Too little amout to buy');

    vaultContract._setAllowance(stableCoin, address(this), amountToBuy);
    ownCoin.transferFrom(recepient, address(vaultContract), amountToSell);
    stableCoin.transferFrom(address(vaultContract), recepient, amountToBuy);

    emit SellToken(recepient, amountToSell, amountToBuy);
    delete bookingPrices[recepient];
  }

  // Отмена бронирования, если оно было
  function cancelBooking() public {
    vaultContract._cancelBooking(msg.sender);
  }
}