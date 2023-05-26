// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '../access/ElyfiAccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol';

contract ElyfiToken is ERC20Snapshot, ElyfiAccessControl {
  uint256 internal constant TOTAL_SUPPLY = 100000000 ether;

  /// Token address tow
  address internal _newElyfiToken;

  event Migrate(address indexed user, uint256 amount);

  constructor() ERC20('ELFI Token', 'ELFI') {
    _mint(msg.sender, TOTAL_SUPPLY);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function newElyfiToken() public view returns (address) {
    return _newElyfiToken;
  }

  function snapshot() external onlySnapshotMaker returns (uint256) {
    return _snapshot();
  }

  function burn(uint256 amount) public virtual {
    _burn(_msgSender(), amount);
  }

  function initMigration(address newElyfiToken_) public onlyAdmin {
    require(_newElyfiToken != address(0), "Already Initialized");

    _newElyfiToken = newElyfiToken_;
  }

  // For migration
  function migrate() public {
    require(_newElyfiToken != address(0), "Not Initialized");

    uint256 userBalance = balanceOf(msg.sender);

    require(userBalance != 0, "Invalid account");

    _burn(msg.sender, userBalance);

    IERC20(_newElyfiToken).transfer(msg.sender, userBalance);

    emit Migrate(msg.sender, userBalance);
  }
}