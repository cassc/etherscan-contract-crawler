// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract BlackList is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => bool) public isBlacklisted;
    EnumerableSet.AddressSet private blackList;

    function addBlackList(address _user) public onlyOwner {
        require(!isBlacklisted[_user], "user already blacklisted");
        blackList.add(_user);
        isBlacklisted[_user] = true;
    }

    function removeFromBlacklist(address _user) public onlyOwner {
        require(isBlacklisted[_user], "user already whitelisted");
        blackList.remove(_user);
        isBlacklisted[_user] = false;
    }

    function getUserBlackList() public view returns (address[] memory) {
        uint256 totalBlackList = blackList.length();
        address[] memory result = new address[](totalBlackList);
        for (uint256 i = 0; i < totalBlackList; i++) {
            result[i] = blackList.at((i));
        }
        return result;
    }
}