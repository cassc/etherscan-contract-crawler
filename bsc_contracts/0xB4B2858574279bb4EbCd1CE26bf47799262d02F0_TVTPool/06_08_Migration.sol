// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Math.sol";
import "./Secure.sol";
import "./ITVTPool.sol";

abstract contract Migration is ITVTPool, Secure {
  using Math for uint256;

  mapping(address => UserStruct) public override users;
  mapping(address => bool) public override tvtUsers;

  function migrateFromOldPool(
    address _oldPool,
    address user,
    bool _tvtUsers
  ) external onlyOwner {
    ITVTPool oldPool = ITVTPool(_oldPool);

    (address referrer, uint8 percent, uint256 totalTree, uint256 latestWithdraw) = oldPool
      .users(user);

    users[user].percent = percent;
    users[user].referrer = referrer;
    users[user].totalTree = totalTree;
    users[user].latestWithdraw = latestWithdraw;

    delete users[user].invest;

    for (uint256 l = 0; l < oldPool.userDepositNumber(user); l++) {
      (uint256 amount, uint256 startTime) = oldPool.userDepositDetails(user, l);
      users[user].invest.push(Invest(amount.toUint128(), startTime.toUint128()));
    }

    tvtUsers[user] = _tvtUsers;
  }

  function migrateByUser() external {
    _migrate(_msgSender(), true);
  }

  function migrateIntoTVT(address[] memory _users) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      address user = _users[i];
      migrateUser(user, true);
    }
  }

  function migrateIntoNormal(address[] memory _users) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      address user = _users[i];
      migrateUser(user, false);
    }
  }

  function deleteUsers(address[] memory _users) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      _deleteUser(_users[i]);
    }
  }

  function convertUsers(address[] memory _users, bool[] memory _tvtUsers)
    external
    onlyOwner
  {
    require(_users.length == _tvtUsers.length, "Invalid length");

    for (uint256 i = 0; i < _users.length; i++) {
      tvtUsers[_users[i]] = _tvtUsers[i];
    }
  }

  function intoTVT() external {
    tvtUsers[_msgSender()] = true;
  }

  function convertUser(address _user, bool _tvtUser) external onlyOwner {
    tvtUsers[_user] = _tvtUser;
  }

  function migrateUser(address user, bool isTVT) public onlyOwner {
    if (users[user].referrer == address(0)) {
      _migrate(user, isTVT);
    } else {
      tvtUsers[user] = isTVT;
    }
  }

  function _migrate(address user, bool _tvtUsers) internal {
    require(users[user].referrer == address(0), "ALE");

    (
      address referrer,
      uint8 percent,
      uint256 totalTree,
      uint256 latestWithdraw
    ) = OLD_POOL.users(user);

    require(referrer != address(0), "NOE");

    users[user].percent = percent;
    users[user].referrer = referrer;
    users[user].totalTree = totalTree;
    users[user].latestWithdraw = latestWithdraw;

    for (uint256 l = 0; l < OLD_POOL.userDepositNumber(user); l++) {
      (uint256 amount, uint256 startTime) = OLD_POOL.userDepositDetails(user, l);
      users[user].invest.push(Invest(amount.toUint128(), startTime.toUint128()));
    }

    tvtUsers[user] = _tvtUsers;
  }

  // View Functions
  function needMigrate(address user) public view returns (bool) {
    if (users[user].referrer != address(0)) return false;
    (address referrer, , , ) = OLD_POOL.users(user);

    return referrer != address(0);
  }

  function userTotalInvest(address user)
    public
    view
    override
    returns (uint256 totalAmount)
  {
    Invest[] storage userIvest = users[user].invest;
    for (uint8 i = 0; i < userIvest.length; i++) {
      if (userIvest[i].startTime > 0) totalAmount = totalAmount.add(userIvest[i].amount);
    }
  }

  // Modify User Functions
  function addGift(address user, uint256 amount) external onlyOwner {
    users[user].invest.push(Invest(amount.toUint128(), block.timestamp.toUint128()));
  }

  function changeUserPercent(address user, uint8 percent) external onlyOwner {
    users[user].percent = percent;
  }

  function changeUserInvest(
    address user,
    uint256 index,
    Invest memory invest
  ) external onlyOwner {
    users[user].invest[index] = invest;
  }

  function changeUserReferrer(address user, address referrer) external onlyOwner {
    users[user].referrer = referrer;
  }

  function changeUserLatestWithdraw(address user, uint256 latestWithdraw)
    external
    onlyOwner
  {
    users[user].latestWithdraw = latestWithdraw;
  }

  function changeUserTotalTree(address user, uint256 totalTree) external onlyOwner {
    users[user].totalTree = totalTree;
  }

  function changeSubTree(address user, uint256 value) external onlyOwner {
    _subTree(user, value);
  }

  function removeUserInvest(address user, uint256 index) external onlyOwner {
    _withdraw(user, index);
  }

  function resetUser(address user, uint256 value) external onlyOwner {
    _reset(user, value);
  }

  // Private Functions
  function _deposit(address user, uint256 value) internal {
    users[user].invest.push(Invest(value.toUint128(), block.timestamp.toUint128()));

    address referrer = users[user].referrer;
    for (uint8 i = 0; i < 50; i++) {
      if (users[referrer].percent == 0) break;
      users[referrer].totalTree = users[referrer].totalTree.add(value);
      referrer = users[referrer].referrer;
    }
  }

  function _withdraw(address user, uint256 index) internal returns (uint256 value) {
    users[user].invest[index].startTime = 0;

    value = users[user].invest[index].amount;

    if (userTotalInvest(user) < MINIMUM_INVEST) _reset(user, value);
    else _subTree(user, value);
  }

  function _subTree(address user, uint256 value) private {
    address referrer = users[user].referrer;
    for (uint8 i = 0; i < 50; i++) {
      if (users[referrer].totalTree < value) break;
      users[referrer].totalTree = users[referrer].totalTree.sub(value);
      referrer = users[referrer].referrer;
    }
  }

  function _reset(address user, uint256 value) private {
    uint256 treeValue = users[user].totalTree.add(value);
    _subTree(user, treeValue);

    emit WithdrawTree(user, users[user].referrer, treeValue);

    users[user].percent = 0;
    users[user].totalTree = 0;

    delete users[user].invest;
  }

  function _deleteUser(address user) internal {
    delete users[user];
    delete tvtUsers[user];
  }
}