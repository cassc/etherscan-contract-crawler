// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../keyring/integration/KeyringGuard.sol";

contract KycETH is KeyringGuard {
  string public name = "KYC Ether";
  string public symbol = "kycETH";
  uint8 public decimals = 18;
  uint public totalSupply = 0;

  event Approval(address indexed owner, address indexed spender, uint amount);
  event Transfer(address indexed from, address indexed to, uint amount);
  event Deposit(address indexed to, uint amount);
  event Withdrawal(address indexed from, uint amount);

  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;

  /**
   * @param config Keyring contract addresses. See IKycERC20.
   * @param policyId_ The unique identifier of a Policy.
   * @param maximumConsentPeriod_ The upper limit for user consent deadlines.
   */
  constructor(
    KeyringConfig memory config,
    uint32 policyId_,
    uint32 maximumConsentPeriod_
  ) KeyringGuard(config, policyId_, maximumConsentPeriod_) {}

  function depositFor() public payable {
    balanceOf[_msgSender()] += msg.value;
    totalSupply += msg.value;
    emit Deposit(_msgSender(), msg.value);
  }

  function withdrawTo(address trader, uint amount) public {
    if (trader != _msgSender()) {
      if (!isAuthorized(_msgSender(), trader)) revert Unacceptable({ reason: "trader not authorized" });
    }

    require(balanceOf[_msgSender()] >= amount);
    balanceOf[_msgSender()] -= amount;

    totalSupply -= amount;
    (bool sent, ) = trader.call{ value: amount }("");
    require(sent, "Failed to send Ether");

    emit Withdrawal(_msgSender(), amount);
  }

  function approve(address spender, uint amount) public returns (bool) {
    allowance[_msgSender()][spender] = amount;
    emit Approval(_msgSender(), spender, amount);
    return true;
  }

  function transfer(address to, uint amount) public returns (bool) {
    return transferFrom(_msgSender(), to, amount);
  }

  function transferFrom(address from, address to, uint amount) public checkKeyring(from, to) returns (bool) {
    require(balanceOf[from] >= amount);

    if (from != _msgSender() && allowance[from][_msgSender()] > 0) {
      require(allowance[from][_msgSender()] >= amount);
      allowance[from][_msgSender()] -= amount;
    }

    balanceOf[from] -= amount;
    balanceOf[to] += amount;

    emit Transfer(from, to, amount);

    return true;
  }
}