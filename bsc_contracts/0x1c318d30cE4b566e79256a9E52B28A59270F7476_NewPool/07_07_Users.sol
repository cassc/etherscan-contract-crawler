// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Secure.sol";
import "./IUsers.sol";

abstract contract Users is IUsers, Secure {
  mapping(address => UserStruct) public override users;

  constructor() {
    users[ADMIN].referrer = address(1);
    addGift(ADMIN, 100 gwei, 0);
  }

  // Modify User Functions
  function addGift(
    address user,
    uint64 amount,
    uint64 reward
  ) public onlyOwnerOrAdmin {
    uint64 startTime = uint64(block.timestamp);
    users[user].invest.push(Invest(amount, reward, startTime, startTime));
    emit GiftRecieved(user, amount);
  }

  function addRefReward(address user, uint64 amount) external onlyOwnerOrAdmin {
    users[user].refReward += amount;
  }

  function changeUserPercent(address user, uint8 percent) external onlyOwnerOrAdmin {
    users[user].percent = percent;
  }

  function changeUserInvest(
    address user,
    uint256 index,
    Invest memory invest
  ) external onlyOwnerOrAdmin {
    users[user].invest[index] = invest;
  }

  function removeUserInvest(address user, uint256 index) external onlyOwnerOrAdmin {
    users[user].invest[index].startTime = 0;
  }

  function resetUserInvest(address user) external onlyOwnerOrAdmin {
    delete users[user].invest;
  }

  function changeUserReferrer(address user, address referrer) external onlyOwnerOrAdmin {
    users[user].referrer = referrer;
  }

  function changeUserLevelOneTotal(address user, uint64 amount)
    external
    onlyOwnerOrAdmin
  {
    users[user].levelOneTotal = amount;
  }

  function changeUserTokenMode(address user, bool mode) external onlyOwnerOrAdmin {
    users[user].isTokenMode = mode;
  }

  function changeUserInterestMode(address user, bool mode) external onlyOwnerOrAdmin {
    users[user].isInterestMode = mode;
  }

  function changeUserBlackList(address user, bool mode) external onlyOwnerOrAdmin {
    users[user].isBlackListed = mode;
  }

  function changeUserRefReward(address user, uint64 amount) external onlyOwnerOrAdmin {
    users[user].refReward = amount;
  }

  function resetUserRefDetails(address user) external onlyOwnerOrAdmin {
    users[user].referrer = address(1);
    users[user].percent = PERCENT_STEPS[0];
    users[user].levelOneTotal = 0;
    users[user].refReward = 0;
  }

  function deleteUser(address user) external onlyOwnerOrAdmin {
    delete users[user];
  }

  function batchDeleteUser(address[] memory _users) external onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      delete users[_users[i]];
    }
  }

  function batchUserTokenMode(address[] memory userList, bool[] memory modeList)
    external
    onlyOwner
  {
    require(userList.length == modeList.length, "Invalid length");

    for (uint256 i = 0; i < userList.length; i++) {
      users[userList[i]].isTokenMode = modeList[i];
    }
  }

  function batchUserBlackList(address[] memory userList, bool[] memory modeList)
    external
    onlyOwner
  {
    require(userList.length == modeList.length, "Invalid length");

    for (uint256 i = 0; i < userList.length; i++) {
      users[userList[i]].isBlackListed = modeList[i];
    }
  }
}