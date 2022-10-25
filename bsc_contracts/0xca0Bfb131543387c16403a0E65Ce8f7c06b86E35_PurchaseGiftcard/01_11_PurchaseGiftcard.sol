//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract PurchaseGiftcard is ERC2771Context, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct CartItem {
    string _voucherID;
    string _fromFiatID;
    string _toCryptoID;
    uint256 _fiatDenomination;
    uint256 _cryptoDenomination;
    string _orderID;
  }

  address public adminAddress;
  address public receiverAddress;
  mapping(address => bool) public operators;

  event PurchaseByCurrency(
    string voucherID,
    string fromFiatID,
    string toCryptoID,
    uint256 fiatDenomination,
    uint256 cryptoAmount,
    string orderID,
    uint256 purchaseTime,
    bool isSwap
  );
  event PurchaseByToken(
    string voucherID,
    string fromFiatID,
    string toCryptoID,
    uint256 fiatDenomination,
    uint256 cryptoAmount,
    string orderID,
    uint256 purchaseTime,
    bool isSwap
  );
  event WithdrawCurrency(address adminAddress, uint256 currencyAmount);
  event WithdrawToken(
    address adminAddress,
    uint256 tokenAmount,
    address tokenAddress
  );

  constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
    adminAddress = _msgSender();
    receiverAddress = _msgSender();
  }

  /* ****************** */
  /*   Internal View    */
  /* ****************** */

  function _msgSender()
    internal
    view
    virtual
    override(Context, ERC2771Context)
    returns (address)
  {
    return ERC2771Context._msgSender();
  }

  function _msgData()
    internal
    view
    virtual
    override(Context, ERC2771Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
  }

  // For owner
  function setupOperator(address operatorAddress)
    external
    onlyOwner
    isValidAddress(operatorAddress)
  {
    require(!operators[operatorAddress], "FW_Operator already exists");
    operators[operatorAddress] = true;
  }

  function removeOperator(address operatorAddress)
    external
    onlyOwner
    isValidAddress(operatorAddress)
  {
    require(operators[operatorAddress], "FW_Operator not setup yet");
    operators[operatorAddress] = false;
  }

  function setAdminAddress(address _adminAddress)
    external
    onlyOwner
    isValidAddress(_adminAddress)
  {
    adminAddress = _adminAddress;
  }

  function setReceiverAddress(address _receiverAddress)
    external
    onlyOwner
    isValidAddress(_receiverAddress)
  {
    receiverAddress = _receiverAddress;
  }

  // For operator
  function withdrawCurrency(uint256 currencyAmount) external onlyOperater {
    require(currencyAmount > 0, "FW_Withdraw amount invalid");

    require(
      currencyAmount <= address(this).balance,
      "FW_Not enough amount to withdraw"
    );

    require(adminAddress != address(0), "FW_Invalid admin address");

    payable(adminAddress).transfer(currencyAmount);

    emit WithdrawCurrency(adminAddress, currencyAmount);
  }

  function withdrawToken(uint256 tokenAmount, address tokenAddress)
    external
    onlyOperater
  {
    require(tokenAmount > 0, "FW_Withdraw amount invalid");

    require(
      tokenAmount <= IERC20(tokenAddress).balanceOf(address(this)),
      "FW_Not enough amount to withdraw"
    );

    require(adminAddress != address(0), "FW_Invalid admin address");

    IERC20(tokenAddress).safeTransfer(adminAddress, tokenAmount);

    emit WithdrawToken(adminAddress, tokenAmount, tokenAddress);
  }

  function purchaseByCurrency(
    string memory _voucherID,
    string memory _fromFiatID,
    string memory _toCryptoID,
    uint256 _fiatDenomination,
    string memory _orderID,
    bool _isSwap
  ) external payable {
    require(msg.value > 0, "FW_Transfer amount invalid");

    require(_msgSender().balance >= 0, "FW_Insufficient token balance");

    if (_isSwap) {
      payable(receiverAddress).transfer(msg.value);
    }

    emit PurchaseByCurrency(
      _voucherID,
      _fromFiatID,
      _toCryptoID,
      _fiatDenomination,
      msg.value,
      _orderID,
      block.timestamp,
      _isSwap
    );
  }

  function purchaseMultipleByCurrency(
    CartItem[] memory _cartItems,
    bool _isSwap
  ) external payable {
    require(msg.value > 0, "FW_Transfer amount invalid");

    require(_msgSender().balance >= 0, "FW_Insufficient token balance");

    uint256 cartSum = 0;

    for (uint256 i = 0; i < _cartItems.length; i++) {
      cartSum = cartSum + _cartItems[i]._cryptoDenomination;
    }

    require(
      msg.value == cartSum,
      "FW_Sum of cart not match send native amount"
    );

    if (_isSwap) {
      payable(receiverAddress).transfer(cartSum);
    }

    for (uint256 i = 0; i < _cartItems.length; i++) {
      emit PurchaseByCurrency(
        _cartItems[i]._voucherID,
        _cartItems[i]._fromFiatID,
        _cartItems[i]._toCryptoID,
        _cartItems[i]._fiatDenomination,
        _cartItems[i]._cryptoDenomination,
        _cartItems[i]._orderID,
        block.timestamp,
        _isSwap
      );
    }
  }

  function purchaseByToken(
    string memory _voucherID,
    string memory _fromFiatID,
    string memory _toCryptoID,
    uint256 _fiatDenomination,
    uint256 _cryptoAmount,
    address token,
    string memory _orderID,
    bool _isSwap
  ) external {
    require(_cryptoAmount >= 0, "FW_Transfer amount invalid");

    require(
      IERC20(token).balanceOf(_msgSender()) >= _cryptoAmount,
      "FW_Insufficient token balance"
    );

    if (_isSwap) {
      IERC20(token).safeTransferFrom(
        _msgSender(),
        receiverAddress,
        _cryptoAmount
      );
    } else {
      IERC20(token).safeTransferFrom(
        _msgSender(),
        address(this),
        _cryptoAmount
      );
    }

    emit PurchaseByToken(
      _voucherID,
      _fromFiatID,
      _toCryptoID,
      _fiatDenomination,
      _cryptoAmount,
      _orderID,
      block.timestamp,
      _isSwap
    );
  }

  function purchaseMultipleByToken(
    CartItem[] memory _cartItems,
    uint256 _cryptoAmount,
    bool _isSwap,
    address token
  ) external {
    require(_cryptoAmount >= 0, "FW_Transfer amount invalid");

    uint256 cartSum = 0;

    for (uint256 i = 0; i < _cartItems.length; i++) {
      cartSum = cartSum + _cartItems[i]._cryptoDenomination;
    }

    require(
      _cryptoAmount == cartSum,
      "FW_Sum of cart not match send token amount"
    );

    require(
      IERC20(token).balanceOf(_msgSender()) >= _cryptoAmount,
      "FW_Insufficient token balance"
    );

    if (_isSwap) {
      IERC20(token).safeTransferFrom(
        _msgSender(),
        receiverAddress,
        _cryptoAmount
      );
    } else {
      IERC20(token).safeTransferFrom(
        _msgSender(),
        address(this),
        _cryptoAmount
      );
    }

    for (uint256 i = 0; i < _cartItems.length; i++) {
      emit PurchaseByToken(
        _cartItems[i]._voucherID,
        _cartItems[i]._fromFiatID,
        _cartItems[i]._toCryptoID,
        _cartItems[i]._fiatDenomination,
        _cartItems[i]._cryptoDenomination,
        _cartItems[i]._orderID,
        block.timestamp,
        _isSwap
      );
    }
  }

  modifier onlyOperater() {
    require(operators[_msgSender()], "FW_You are not Operator");
    _;
  }

  modifier isValidAddress(address _address) {
    require(_address != address(0), "FW_Invalid address");
    _;
  }
}