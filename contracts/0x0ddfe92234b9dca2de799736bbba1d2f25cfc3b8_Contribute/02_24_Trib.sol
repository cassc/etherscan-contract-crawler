// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Trib is ERC20 {
  address minter;

  modifier onlyMinter {
    require(msg.sender == minter, 'Only minter can call this function.');
    _;
  }

  constructor(address _minter) public ERC20('Contribute', 'TRIB') {
    minter = _minter;
  }

  function mint(address account, uint256 amount) external onlyMinter {
    _mint(account, amount);
  }

  function decreaseSupply(address account, uint256 amount) external onlyMinter {
    _burn(account, amount);
  }
}