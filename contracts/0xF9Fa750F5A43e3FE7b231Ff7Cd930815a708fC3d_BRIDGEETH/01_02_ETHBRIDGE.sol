pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT
import './IToken.sol';

contract BRIDGEETH {
  address public admin;
  IToken public token;
  uint256 public taxfee;


  constructor(address _token) {
    admin = msg.sender;
    token = IToken(_token);
    taxfee = 500;
  }

  function burn(uint amount) external {
    token.transferFrom(msg.sender, address(this), amount-(taxfee*(10**(token.decimals()))));
    token.transferFrom(msg.sender, admin, (taxfee*(10**(token.decimals()))));
  }

  function mint(address to, uint amount) external {
    require(msg.sender == admin, 'only admin');
    token.transferFrom(admin, to, amount);
  }
  function getContractTokenBalance() external view returns (uint256) {
    return token.balanceOf(address(this));
  }
  function withdraw(uint amount) external {
    require(msg.sender == admin, 'only admin');
    token.transfer(msg.sender, amount);
  }
  function changeAdmin(address newAdmin) external {
    require(msg.sender == admin, 'only admin');
    admin = newAdmin;
  }
  function setTaxFee(uint newTaxFee) external {
    require(msg.sender == admin, 'only admin');
    taxfee = newTaxFee;
  }
}
