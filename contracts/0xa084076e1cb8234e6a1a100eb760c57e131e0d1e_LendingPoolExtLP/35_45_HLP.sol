// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './LendingRewards.sol';

contract HLP is ERC20 {
  address public lendingPool;
  LendingRewards public lendingRewards;

  modifier onlyLendingPool() {
    require(_msgSender() == lendingPool, 'UNAUTHORIZED');
    _;
  }

  constructor() ERC20('HYPE LP', 'HLP') {
    lendingPool = _msgSender();
    lendingRewards = new LendingRewards(address(this));
  }

  function mint(address _wallet, uint256 _amount) external onlyLendingPool {
    _mint(_wallet, _amount);
  }

  function burn(address _wallet, uint256 _amount) external onlyLendingPool {
    _burn(_wallet, _amount);
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    super._transfer(sender, recipient, amount);
    _afterTokenTransfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal override {
    super._mint(account, amount);
    _afterTokenTransfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal override {
    super._burn(account, amount);
    _afterTokenTransfer(account, address(0), amount);
  }

  function _canReceiveRewards(address _wallet) internal view returns (bool) {
    return _wallet != address(0);
  }

  function _afterTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal virtual {
    if (_canReceiveRewards(_from)) {
      lendingRewards.setShare(_from, _amount, true);
    }
    if (_canReceiveRewards(_to)) {
      lendingRewards.setShare(_to, _amount, false);
    }
  }
}