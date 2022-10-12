//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BridgeOut {
  uint256 public minClaimValue;
  address public token;
  address public manager;
  mapping(address => uint256) public balance;
  mapping(address => bool) accountsClaim;
  address[] public allUserAddress;

  event Withdrawal(address indexed _from, uint256 _value);

  modifier manager_only() {
    require(manager == msg.sender, "NOT MANAGER");
    _;
  }

  constructor(
    address _manager,
    address _token,
    uint256 _minClaimValue
  ) {
    require(_manager != address(0), "ADDRESS 0");
    token = _token;
    manager = _manager;
    minClaimValue = _minClaimValue;
  }

  function setManager(address _manager) external manager_only {
    require(_manager != address(0), "ADDRESS 0");
    manager = _manager;
  }

  function setMinClaimValue(uint256 _minClaimValue) external manager_only {
    minClaimValue = _minClaimValue;
  }

  function claimRequest() external payable {
    require(msg.value >= minClaimValue, "value is less than minClaimValue");
    payable(manager).transfer(msg.value);
    allUserAddress.push(msg.sender);
    accountsClaim[msg.sender] = true;
  }

  function claim(address _account, uint256 _amount) external manager_only {
    require(accountsClaim[_account], "need claim request to pay fee");
    require(
      ERC20(token).transferFrom(manager, _account, _amount),
      "TransferFrom failed"
    );
    balance[_account] += _amount;
    delete (accountsClaim[_account]);
    emit Withdrawal(_account, _amount);
  }

  function seeAllUserAddress() public view returns (address[] memory) {
    return allUserAddress;
  }
}