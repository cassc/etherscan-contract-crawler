// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';


contract GeneratedToken is ERC20 {

  address internal deployer;

  modifier onlyDeployer() {
    require(msg.sender == deployer, 'unauthorized');
    _;
  }

  constructor (string memory name_, string memory symbol_) ERC20(name_, symbol_) {
    deployer = msg.sender;
  }

  function mint(address account, uint256 amount) external onlyDeployer {
    super._mint(account, amount);
  }

  function burn(address account, uint256 amount) external onlyDeployer {
    super._burn(account, amount);
  }
}