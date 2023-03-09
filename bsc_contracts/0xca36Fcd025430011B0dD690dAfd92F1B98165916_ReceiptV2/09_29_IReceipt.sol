//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IReceipt {
  enum Status {
    Pending,
    InTransit,
    Delivered,
    Confirmed,
    Archived
  }

  struct ReceiptWithStatus {
    uint256 currency;
    uint256 price;
    uint256 quantity;
    uint256 totalAmount;
    bytes32 orderId;
    uint256 status;
    string reason;
  }

  event ReceiptStatus(
    uint256 indexed _receiptId,
    address indexed _setBy,
    address indexed _forWhom,
    uint256 _status,
    string _reason
  );

  function __Receipt_init(address _parent) external;

  function setCheckout(address _checkout) external;

  function setCheckerRole(address _target) external;

  function mint(
    address _to,
    uint256 _currency,
    uint256 _price,
    uint256 _quantity,
    uint256 _totalAmount,
    bytes32 _orderId,
    string calldata _metadataURI
  ) external returns (uint256);

  function setStatus(
    uint256 _receiptId,
    Status _status,
    string calldata _reason
  ) external;

  function lastReceiptId() external view returns (uint256);

  function price(uint256 _receiptId) external view returns (uint256);

  function quantity(uint256 _receiptId) external view returns (uint256);

  function totalAmount(uint256 _receiptId) external view returns (uint256);

  function status(uint256 _receiptId)
    external
    view
    returns (uint256, string memory);

  function receipt(uint256 _receiptId)
    external
    view
    returns (ReceiptWithStatus memory);
}