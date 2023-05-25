// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract CirusToken is ERC20 {
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _supply,
    address _owner
  )
    ERC20(_name, _symbol)
  {
    _mint(_owner, _supply);
  }
}