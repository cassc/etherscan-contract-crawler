// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract Adminer {
  address private _adminer;

  constructor() {
    _adminer = msg.sender;
  }

  modifier onlyAdminer() {
    require(adminer() == msg.sender, "Adminer: caller is not the owner");
    _;
  }

  function adminer() public view virtual returns (address) {
    return _adminer;
  }

  function transferOwnership(address newAdminer) public virtual onlyAdminer {
    require(newAdminer != address(0), "Adminer: new owner is the zero address");
    _adminer = newAdminer;
  }
}

contract BrandingOrder is Adminer {
  struct Order {
    OrderInfo info;
    bytes signature;
  }

  struct OrderInfo {
    string id;
    uint256 orderType;
    address owner;
    address contractAddress;
    uint256 tokenId;
    uint256 price;
    uint256 amount;
    uint256 createTime;
    uint256 effectTime;
  }

  struct OrderFulfill {
    string id;
    address owner;
    uint256 amount;
    uint256 time;
  }

  WETH public weth = WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  address payable public platformAddress;

  uint256 public platformFee;

  string[] private _orderIds;

  mapping (string => OrderFulfill[]) private _fulfillsMap;

  mapping (string => bool) private _cancelMap;

  constructor(address payable _platformAddress, uint256 _platformFee) {
    setPlatformAddress(_platformAddress);
    setPlatformFee(_platformFee);
    transferOwnership(_platformAddress);
  }

  function verifyOrder(Order calldata order) public pure returns (bool) {
    OrderInfo calldata info = order.info;
    bytes32 hash = keccak256(abi.encodePacked(
      info.id,
      info.orderType,
      info.owner,
      info.contractAddress,
      info.tokenId,
      info.price,
      info.amount,
      info.createTime,
      info.effectTime
    ));
    bytes32 message = ECDSA.toEthSignedMessageHash(hash);
    address signatureOwner = ECDSA.recover(message, order.signature);
    return signatureOwner == info.owner;
  }

  function fulfillOrder(Order calldata order, uint256 amount, address to) external payable {
    require(verifyOrder(order), "Order verification failed");

    OrderInfo calldata info = order.info;
    address owner = info.owner;

    require(owner != msg.sender, "Sender should not be the owner");
    require(!checkHasCanceled(info), "Order has canceled");
    require(!checkHasExpired(info), "Order has expired");
    require(getRemainAmount(info) >= amount, "Insufficient number of remaining");

    if (info.orderType == 0) {
      ERC1155(info.contractAddress).safeTransferFrom(owner, to, info.tokenId, amount, order.signature);

      uint256 totalPrice = amount * info.price;
      require(msg.value >= totalPrice, "Underpayment");

      uint256 platformReceiveBalance = ((totalPrice / 100) * platformFee) / 10;

      (bool platformReceiveSuccess, ) = platformAddress.call{ value: platformReceiveBalance }("");
      require(platformReceiveSuccess, "Owner failed to receive eth");

      (bool ownerReceiveSuccess, ) = payable(owner).call{ value: totalPrice - platformReceiveBalance }("");
      require(ownerReceiveSuccess, "Owner failed to receive eth");

      if (msg.value > totalPrice) {
        (bool returnSuccess, ) = msg.sender.call{ value: msg.value - totalPrice }("");
        require(returnSuccess, "Sender failed to receive eth");
      }
    } else if (info.orderType == 1) {
      ERC1155(info.contractAddress).safeTransferFrom(msg.sender, owner, info.tokenId, amount, order.signature);

      uint256 totalPrice = amount * info.price;
      uint256 platformReceiveBalance = ((totalPrice / 100) * platformFee) / 10;

      weth.transferFrom(owner, platformAddress, platformReceiveBalance);
      weth.transferFrom(owner, msg.sender, totalPrice - platformReceiveBalance);
    }

    string calldata orderId = info.id;
    OrderFulfill memory fulfill = OrderFulfill(orderId, msg.sender, amount, block.timestamp);
    _fulfillsMap[orderId].push(fulfill);

    if (_fulfillsMap[orderId].length == 1) {
      _orderIds.push(orderId);
    }
  }

  function cancelOrder(Order[] calldata orders) external {
    for (uint i = 0; i < orders.length; i++) {
      Order calldata order = orders[i];
      OrderInfo calldata info = order.info;

      require(msg.sender == info.owner, "Sender must be the owner");
      require(verifyOrder(order), "Order verification failed");
      
      _cancelMap[info.id] = true;
    }
  }

  function getRemainAmount(OrderInfo calldata info) public view returns (uint256) {
    uint256 remainAmount = info.amount;
    OrderFulfill[] memory fulfills = _fulfillsMap[info.id];
    for (uint256 index = 0; index < fulfills.length; index++) {
      remainAmount -= fulfills[index].amount;
    }
    return remainAmount;
  }

  function checkHasFinished(OrderInfo calldata info) public view returns (bool) {
    return getRemainAmount(info) == 0;
  }

  function checkHasCanceled(OrderInfo calldata info) public view returns (bool) {
    return _cancelMap[info.id];
  }

  function checkHasExpired(OrderInfo calldata info) public view returns (bool) {
    return info.createTime + info.effectTime < block.timestamp;
  }

  function checkIsValid(OrderInfo calldata info) public view returns (bool) {
    return !(checkHasFinished(info) || checkHasCanceled(info) || checkHasExpired(info));
  }

  function getOrderFulfills(string calldata orderId) public view returns (OrderFulfill[] memory) {
    return _fulfillsMap[orderId];
  }

  function getOrderFulfills(address owner) public view returns (OrderFulfill[] memory) {
    OrderFulfill[] memory fulfills = new OrderFulfill[](0);
    for (uint256 index = 0; index < _orderIds.length; index++) {
      OrderFulfill[] memory _fulfills = _fulfillsMap[_orderIds[index]];
      for (uint256 _index = 0; _index < _fulfills.length; _index++) {
        OrderFulfill memory fulfill = _fulfills[_index];
        if (fulfill.owner == owner) {
          fulfills = _fulfillsPush(fulfills, fulfill);
        }
      }
    }
    return fulfills;
  }

  function _fulfillsPush(OrderFulfill[] memory fulfills, OrderFulfill memory fulfill) private pure returns(OrderFulfill[] memory) {
    OrderFulfill[] memory temp = new OrderFulfill[](fulfills.length + 1);
    for (uint256 index = 0; index < fulfills.length; index++) {
      temp[index] = fulfills[index];
    }
    temp[temp.length - 1] = fulfill;
    return temp;
  }

  function setPlatformAddress(address payable _platformAddress) public onlyAdminer {
    require(_platformAddress != address(0), "Platform Address is error");
    platformAddress = _platformAddress;
  }

  function setPlatformFee(uint256 _platformFee) public onlyAdminer {
    require(_platformFee <= 1000, "Platform fee is error");
    platformFee = _platformFee;
  }

  function withdraw() external onlyAdminer {
    uint256 wethBalance = weth.balanceOf(address(this));
    if (wethBalance > 0) {
      weth.transferFrom(address(this), platformAddress, wethBalance);
    }
    
    (bool success, ) = platformAddress.call{ value: address(this).balance }("");
		require(success, "Withdraw fail");
  }

  fallback() external payable {}
  receive() external payable {}
}

interface ERC1155 {
  function balanceOf(address owner, uint256 tokenId) external returns (uint256);
	function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

interface WETH {
  function balanceOf(address owner) external returns (uint256);
	function transferFrom(address from, address to, uint256 balance) external;
}