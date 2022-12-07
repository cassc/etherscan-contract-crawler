// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SaffronPositionToken is ERC20 {
  address public pool;  // Address of SaffronV2 pool that owns this token

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    pool = msg.sender;
  }

  // Mint SAFF-LP tokens
  function mint(address _to, uint256 _amount) external returns (uint256) {
    require(msg.sender == pool, "only pool can mint");
    _mint(_to, _amount);
  }

  // Burn SAFF-LP tokens
  function burn(address _account, uint256 _amount) public {
    require(msg.sender == pool, "only pool can burn");
    _burn(_account, _amount);
  }
  
}