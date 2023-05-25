// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

contract SideVesting is AccessControl, ReentrancyGuard {
  bytes32 public constant DEV = keccak256('DEV');

  address public dev;
  IERC20 public side;
  uint256 public start;
  uint256 public end;

  mapping(address => uint256) public toDistribute;
  mapping(address => uint256) public distributed;
  mapping(address => uint256) public lastUpdated;

  constructor(
    address _side,
    uint256 _start,
    uint256 _end
  ) {
    require(_end > _start, 'End should come after start');

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    grantRole(DEV, msg.sender);
    dev = msg.sender;

    side = IERC20(_side);
    start = _start;
    end = _end;
  }

  function claim() external nonReentrant {
    _claim(msg.sender);
  }

  function getAmountToClaim(address _account) public view returns (uint256) {
    uint256 lastDistributed = lastUpdated[_account] > start ? lastUpdated[_account] : start;

    if (block.timestamp >= end) {
      return toDistribute[_account] - distributed[_account];
    } else {
      return (toDistribute[_account] * (block.timestamp - lastDistributed)) / (end - start);
    }
  }

  function _claim(address _account) internal {
    require(block.timestamp >= start, 'Cannot claim before start');
    require(distributed[_account] < toDistribute[_account], 'Already claimed all SIDE');

    uint256 amount = getAmountToClaim(_account);
    require(amount > 0, 'No SIDE to claim');

    lastUpdated[_account] = block.timestamp;
    distributed[_account] += amount;
    side.transfer(_account, amount);
  }

  function claimDev(address _account) external onlyRole(DEV) {
    _claim(_account);
  }

  function setAmountToDistributeDev(address _account, uint256 _amount) external onlyRole(DEV) {
    toDistribute[_account] = _amount;
  }

  function setAmountsToDistributeDev(address[] memory _accounts, uint256[] memory _amounts) external onlyRole(DEV) {
    for (uint256 i = 0; i < _accounts.length; i++) {
      toDistribute[_accounts[i]] = _amounts[i];
    }
  }

  // Withdraws an amount of ETH stored on the contract
  function withdrawDev(uint256 _amount) external onlyRole(DEV) {
    payable(msg.sender).transfer(_amount);
  }

  // Withdraws an amount of ERC20 tokens stored on the contract
  function withdrawERC20Dev(address _erc20, uint256 _amount) external onlyRole(DEV) {
    IERC20(_erc20).transfer(msg.sender, _amount);
  }

  function changeDev(address _dev) external onlyRole(DEV) {
    revokeRole(DEV, dev);
    grantRole(DEV, _dev);
    dev = _dev;
  }

  function revokeDev(address _devToRevoke) external onlyRole(DEV) {
    revokeRole(DEV, _devToRevoke);
  }
}