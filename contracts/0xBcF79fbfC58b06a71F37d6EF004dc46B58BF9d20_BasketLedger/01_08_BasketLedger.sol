// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract BasketLedger is Ownable {
  using SafeERC20 for IERC20;

  // vault -> account -> amount
  mapping (address => mapping (address => uint256)) public xlpSupply;
  mapping (address => bool) public managers;

  event Deposit(uint256 basketId, address vault, address account, uint256 amount);
  event Withraw(uint256 basketId, address vault, address account, uint256 amount);

  modifier onlyManager() {
    require(managers[msg.sender], "LiquidC Basket Ledger: !manager");
    _;
  }

  function deposit(uint256 _basketId, address _account, address _vault, uint256 _amount) public {
    IERC20(_vault).safeTransferFrom(msg.sender, address(this), _amount);
    xlpSupply[_vault][_account] = xlpSupply[_vault][_account] + _amount;
    emit Deposit(_basketId, _vault, _account, _amount);
  }

  function withdraw(uint256 _basketId, address _account, address _vault, uint256 _amount) public onlyManager returns(uint256) {
    if (_amount > xlpSupply[_vault][_account]) {
      _amount = xlpSupply[_vault][_account];
    }
    if (_amount > 0) {
      xlpSupply[_vault][_account] = xlpSupply[_vault][_account] - _amount;
      IERC20(_vault).safeTransfer(msg.sender, _amount);
      emit Withraw(_basketId, _vault, _account, _amount);
      return _amount;
    }
    return 0;
  }

  function setManager(address _account, bool _access) public onlyOwner {
    managers[_account] = _access;
  }
}