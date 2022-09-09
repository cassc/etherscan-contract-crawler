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

  struct Purchase {
    string orderID;
    uint256 cryptoAmount;
    address cryptoContract;
    uint256 purchaseTime;
  }

  address public adminAddress;
  address public receiverAddress;
  mapping(address => bool) public operators;
  mapping(address => Purchase[]) public purchaseHistory;
  mapping(string => bool) public refundHistory;
  mapping(address => bool) public tokens;

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
  event RefundCurrency(string orderID);
  event RefundToken(string orderID);

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
  function setupToken(address _token) external onlyOperater {
    require(!tokens[_token], "FW_Token already setup");

    tokens[_token] = true;
  }

  function removeToken(address _token) external onlyOperater {
    require(tokens[_token], "FW_Token not setup yet");

    tokens[_token] = false;
  }

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
    isTokenExist(tokenAddress)
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

  function refundOrder(string memory orderID, address buyer)
    external
    onlyOperater
    isValidAddress(buyer)
  {
    (
      string memory existingOrderID,
      uint256 cryptoAmount,
      address cryptoContract
    ) = _findPurchase(orderID, buyer);

    require(bytes(existingOrderID).length > 0, "FW_Order not found");

    require(
      !refundHistory[existingOrderID],
      "FW_Purchase has been already refunded"
    );

    require(cryptoAmount > 0, "FW_Refund amount invalid");

    if (cryptoContract == address(0)) {
      require(
        cryptoAmount <= address(this).balance,
        "FW_Not enough amount of native token to refund"
      );

      payable(buyer).transfer(cryptoAmount);

      refundHistory[existingOrderID] = true;

      emit RefundCurrency(existingOrderID);
    } else {
      require(
        cryptoAmount <= IERC20(cryptoContract).balanceOf(address(this)),
        "FW_Not enough amount of token to refund"
      );

      IERC20(cryptoContract).safeTransfer(buyer, cryptoAmount);

      refundHistory[existingOrderID] = true;

      emit RefundToken(existingOrderID);
    }
  }

  // For user
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

    Purchase memory purchase = Purchase({
      orderID: _orderID,
      cryptoAmount: msg.value,
      cryptoContract: address(0),
      purchaseTime: block.timestamp
    });
    purchaseHistory[_msgSender()].push(purchase);

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

  function purchaseByToken(
    string memory _voucherID,
    string memory _fromFiatID,
    string memory _toCryptoID,
    uint256 _fiatDenomination,
    uint256 _cryptoAmount,
    address token,
    string memory _orderID,
    bool _isSwap
  ) external isTokenExist(token) {
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

    Purchase memory purchase = Purchase({
      orderID: _orderID,
      cryptoAmount: _cryptoAmount,
      cryptoContract: token,
      purchaseTime: block.timestamp
    });

    purchaseHistory[_msgSender()].push(purchase);

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

  modifier onlyOperater() {
    require(operators[_msgSender()], "FW_You are not Operator");
    _;
  }

  modifier isValidAddress(address _address) {
    require(_address != address(0), "FW_Invalid address");
    _;
  }

  modifier isTokenExist(address _address) {
    require(tokens[_address] == true, "FW_Token is not exist");
    _;
  }

  // Help functions
  function _findPurchase(string memory _orderID, address _buyer)
    internal
    view
    isValidAddress(_buyer)
    returns (
      string memory orderID,
      uint256 cryptoAmount,
      address cryptoContract
    )
  {
    require(bytes(_orderID).length > 0, "FW_OrderID must not be empty");

    for (uint256 i = 0; i < purchaseHistory[_buyer].length; i++) {
      if (
        keccak256(abi.encodePacked(purchaseHistory[_buyer][i].orderID)) ==
        keccak256(abi.encodePacked(_orderID))
      ) {
        return (
          purchaseHistory[_buyer][i].orderID,
          purchaseHistory[_buyer][i].cryptoAmount,
          purchaseHistory[_buyer][i].cryptoContract
        );
      }
    }
  }
}