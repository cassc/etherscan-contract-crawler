// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

library ExchangeOrderbook {
  // Order struct
  struct Order {
    address owner;
    uint256 depositAmount;
  }

  // Order Linked List
  struct OrderStorage {
    /// Hashmap-style linked list of prices to route orders
    // key: price, value: order indices linked hashmap
    mapping(uint256 => mapping(uint32 => uint32)) list;
    mapping(uint32 => Order) orders;
    mapping(uint32 => bool) canceled;
    // Head of the linked list(i.e. lowest ask price / highest bid price)
    mapping(uint256 => uint32) head;
    // count of the orders, used for array allocation
    uint32 count;
    address engine;
  }

  // for orders, lower depositAmount are next, higher depositAmount comes first
  function _insertId(
    OrderStorage storage self,
    uint256 price,
    uint32 id,
    uint256 amount
  ) internal {
    uint32 last = 0;
    uint32 head = self.head[price];
    mapping(uint32 => uint32) storage list = self.list[price];
    mapping(uint32 => Order) storage orders = self.orders;
    // insert order to the linked list
    // if the list is empty
    if (head == 0 || amount > self.orders[head].depositAmount) {
      self.head[price] = id;
      list[id] = head;
      return;
    }
    // Traverse through list until we find the right spot where id's deposit amount is higher than next
    while (head != 0) {
      // what if order deposit amount is bigger than the next order's deposit amount?
      uint32 next = list[head];
      if (amount < orders[next].depositAmount) {
        // Keep traversing
        head = list[head];
        last = next;
      } else if (amount > orders[next].depositAmount) {
        // This is either order is cancelled or order is at the end of the list
        if (orders[next].depositAmount == 0) {
          // what if order is canceled and order id still stays in the list?
          // if order is canceled and stays in the list, there is at least a next order in the list
          if (self.canceled[head]) {
            // Keep traversing
            head = list[head];
            last = next;
          } else {
            // Insert order at the end of the list
            list[head] = id;
            list[id] = 0;
            return;
          }
        }
        // Insert order in the middle of the list
        list[head] = id;
        list[id] = next;
        return;
      }
      // what if there is same order with same deposit amount?
      else if (amount == orders[next].depositAmount) {
        list[id] = list[head];
        list[head] = id;
        return;
      }
    }
  }

  // pop front
  function _fpop(
    OrderStorage storage self,
    uint256 price
  ) internal returns (uint256) {
    uint32 first = self.head[price];
    if (first == 0) {
      return 0;
    }
    uint32 next = self.list[price][first];
    self.head[price] = next;
    delete self.list[price][first];
    return first;
  }

  function _createOrder(
    OrderStorage storage self,
    address owner,
    uint256 depositAmount
  ) internal returns (uint32 id) {
    Order memory order = Order({ owner: owner, depositAmount: depositAmount });
    // prevent order overflow, order id must start from 1
    self.count = self.count == 0 || self.count == type(uint32).max
      ? 1
      : self.count + 1;
    self.orders[self.count] = order;
    return self.count;
  }

  function _decreaseOrder(
    OrderStorage storage self,
    uint256 price,
    uint32 id,
    uint256 amount
  ) internal {
    uint256 decreased = self.orders[id].depositAmount - amount;
    if (decreased == 0) {
      _deleteOrder(self, price, id);
    } else {
      self.orders[id].depositAmount = decreased;
    }
  }

  function _deleteOrder(
    OrderStorage storage self,
    uint256 price,
    uint32 id
  ) internal {
    uint32 last = 0;
    uint32 head = self.head[price];
    uint16 i;
    mapping(uint32 => uint32) storage list = self.list[price];
    // delete id in the order linked list
    if (head == id) {
      self.head[price] = list[head];
      delete list[id];
    } else {
      // search for the order id in the linked list
      while (head != 0 && i < 30) {
        uint32 next = list[head];
        if (head == id) {
          list[last] = next;
          delete list[id];
          break;
        }
        last = head;
        head = next;
        ++i;
      }
    }
    // delete order
    delete self.orders[id];
    // add canceled info to see if the order was deleted in the list
    if (i == 30) {
      self.canceled[id] = true;
    }
    return;
  }

  // show n order ids at the price in the orderbook
  function _getOrderIds(
    OrderStorage storage self,
    uint256 price,
    uint32 n
  ) internal view returns (uint32[] memory) {
    uint32 head = self.head[price];
    uint32[] memory orders = new uint32[](n);
    uint32 i = 0;
    while (head != 0 && i < n) {
      orders[i] = head;
      head = self.list[price][head];
      i++;
    }
    return orders;
  }

  function _getOrders(
    OrderStorage storage self,
    uint256 price,
    uint32 n
  ) internal view returns (Order[] memory) {
    uint32 head = self.head[price];
    Order[] memory orders = new Order[](n);
    uint32 i = 0;
    while (head != 0 && i < n) {
      orders[i] = self.orders[head];
      head = self.list[price][head];
      i++;
    }
    return orders;
  }

  function _head(
    OrderStorage storage self,
    uint256 price
  ) internal view returns (uint32) {
    return self.head[price];
  }

  function _isEmpty(
    OrderStorage storage self,
    uint256 price
  ) internal view returns (bool) {
    return self.head[price] == 0;
  }

  function _next(
    OrderStorage storage self,
    uint256 price,
    uint32 curr
  ) internal view returns (uint32) {
    return self.list[price][curr];
  }

  function _getOrder(
    OrderStorage storage self,
    uint32 id
  ) internal view returns (Order memory) {
    return self.orders[id];
  }
}