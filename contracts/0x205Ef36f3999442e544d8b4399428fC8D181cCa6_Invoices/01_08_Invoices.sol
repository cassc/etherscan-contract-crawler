// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: @yungwknd

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

contract Invoices is AdminControl {

  struct Invoice {
    uint id;
    address to;
    address from;
    uint256 amount;
    bool paid;
    string link;
  }

  address public feeReceiver;
  uint public feeBps;
  uint public proCost;

  mapping(uint => Invoice) public invoices;

  mapping(address => uint[]) public toInvoices;
  mapping(address => uint[]) public fromInvoices;

  mapping(address => bool) public proUsers;

  function configure(address receiver, uint bps, uint cost) public adminRequired {
    feeReceiver = receiver;
    feeBps = bps;
    proCost = cost;
  }

  function getPro() public payable {
    require(msg.value == proCost, "Not enough to go pro.");
    proUsers[msg.sender] = true;
  }

  function getInvoices(address user, bool to) public view returns(Invoice[] memory) {
      uint count = to ? toInvoices[user].length : fromInvoices[user].length;
      if (count == 0) {
          return new Invoice[](0);
      } else {
          Invoice[] memory result = new Invoice[](count);
          uint256 index;
          for (index = 0; index < count; index++) {
              result[index] = invoices[to ? toInvoices[user][index] : fromInvoices[user][index]];
          }
          return result;
      }
  }

  function pay(uint id) public payable {
    Invoice storage invoice = invoices[id];
    require(invoice.to == msg.sender, "Not the recipient");
    require(invoice.paid == false, "Invoice already paid");
    uint fee = (invoice.amount * feeBps) / 10000;
    if (proUsers[msg.sender]) {
      fee = 0;
    }
    require(msg.value >= invoice.amount + fee, "Not enough funds sent");
    payable(feeReceiver).transfer(fee);
    payable(invoice.from).transfer(invoice.amount);
    invoice.paid = true;
  }

  function create(uint id, uint amount, string memory invoiceLink, address to) public {
    invoices[id] = Invoice({
      id: id,
      to: to,
      from: msg.sender,
      amount: amount,
      paid: false,
      link: invoiceLink
    });
    toInvoices[to].push(id);
    fromInvoices[msg.sender].push(id);
  }

  function withdraw(address payable recipient, uint256 amount) external adminRequired {
    (bool success,) = recipient.call{value:amount}("");
    require(success);
  }
}