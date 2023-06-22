// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

import '../interfaces/HegicPool/IHegicPoolMetadata.sol';
import './Governable.sol';

contract zHEGIC is ERC20, Governable {

  IHegicPoolMetadata public pool;

  constructor() public
    ERC20('zHEGIC', 'zHEGIC')
    Governable(msg.sender) {
  }

  modifier onlyPool {
    require(msg.sender == address(pool), 'zHEGIC/only-pool');
    _;
  }

  modifier onlyPoolOrGovernor {
    require(msg.sender == address(pool) || msg.sender == governor, 'zHEGIC/only-pool-or-governor');
    _;
  }

  function setPool(address _newPool) external onlyPoolOrGovernor {
    require(IHegicPoolMetadata(_newPool).isHegicPool(), 'zHEGIC/not-setting-a-hegic-pool');
    pool = IHegicPoolMetadata(_newPool);
  }

  function mint(address account, uint256 amount) external onlyPool {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external onlyPool {
    _burn(account, amount);
  }

  // Governable
  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  function acceptGovernor() external override onlyPendingGovernor {
    _acceptGovernor();
  }
}