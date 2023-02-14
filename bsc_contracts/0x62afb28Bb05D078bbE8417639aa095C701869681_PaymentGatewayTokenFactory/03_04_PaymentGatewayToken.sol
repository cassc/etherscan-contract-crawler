// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import "./Owner.sol";
import "./ERC20.sol";

contract PaymentGatewayToken is Owner {
  event OrderEvent(string merchantId, string orderId, uint256 amount);

  event WithdrawEvent(string merchantId, uint256 amount);

  string public name;
  string public merchantId;
  address public vndtToken;

  constructor(
    string memory _name,
    string memory _merchantId,
    address _vndtToken,
    address _owner
  ) {
    name = _name;
    merchantId = _merchantId;
    vndtToken = _vndtToken;
    changeOwner(_owner);
  }

  function pay(uint256 amount, string memory orderId) public {
    // Event
    ERC20(vndtToken).transferFrom(msg.sender, address(this), amount);
    emit OrderEvent(merchantId, orderId, amount);

    // Event
    ERC20(vndtToken).transfer(this.getOwner(), amount);
    emit WithdrawEvent(merchantId, amount);
  }
}