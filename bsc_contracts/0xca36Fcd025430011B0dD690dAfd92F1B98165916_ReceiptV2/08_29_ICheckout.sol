//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IReceipt} from "./IReceipt.sol";

interface ICheckout {
  enum Currency {
    BNB,
    DeHub,
    BUSD
  }

  event Purchased(
    address indexed forWhom,
    uint256 indexed receiptId,
    uint256 indexed currency,
    uint256 price,
    uint256 quantity,
    uint256 totalAmount,
    string orderId,
    string metadataURI
  );

  function setDeHubToken(IERC20Upgradeable _token) external;

  function setBUSDToken(IERC20Upgradeable _token) external;

  function setTreasuryFee(uint256 _fee) external;

  function setTreasuryWallet(address _treasury) external;

  function setReceipt(IReceipt _receipt) external;

  function purchaseByBNB(
    uint256 _quantity,
    uint256 _totalAmount,
    string calldata _orderId,
    string calldata _metadataURI
  ) external payable returns (uint256);

  function purchaseByBNBFor(
    address _forWhom,
    uint256 _quantity,
    uint256 _totalAmount,
    string calldata _orderId,
    string calldata _metadataURI
  ) external payable returns (uint256);

  function purchaseByDeHub(
    uint256 _priceInDeHub,
    uint256 _quantity,
    uint256 _totalAmount,
    string calldata _orderId,
    string calldata _metadataURI
  ) external returns (uint256);

  function purchaseByDeHubFor(
    address _forWhom,
    uint256 _priceInDeHub,
    uint256 _quantity,
    uint256 _totalAmount,
    string calldata _orderId,
    string calldata _metadataURI
  ) external returns (uint256);

  function purchaseByBUSD(
    uint256 _priceInBUSD,
    uint256 _quantity,
    uint256 _totalAmount,
    string calldata _orderId,
    string calldata _metadataURI
  ) external returns (uint256);

  function purchaseByBUSDFor(
    address _forWhom,
    uint256 _priceInBUSD,
    uint256 _quantity,
    uint256 _totalAmount,
    string calldata _orderId,
    string calldata _metadataURI
  ) external returns (uint256);
}