// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ICakePool.sol";
import "./interfaces/IPancakeProfile.sol";

import "hardhat/console.sol";

contract BatchFetcher {

    address public immutable cakePoolAddress;
    address public immutable pancakeProfileAddress;

    constructor(address _cakePoolAddress, address _pancakeProfileAddress) {
        cakePoolAddress = _cakePoolAddress;
        pancakeProfileAddress = _pancakeProfileAddress;
    }

    function fetchUserInfo(address _userAddress) public view returns (address userAddress, uint256 lockEndTime, uint256 lockedAmount, bool isActive) {
        userAddress = _userAddress;
        (, , , , , lockEndTime, , , lockedAmount) = ICakePool(cakePoolAddress).userInfo(_userAddress);
        isActive = IPancakeProfile(pancakeProfileAddress).getUserStatus(_userAddress);
    }

    function batchFetchUserInfo(address[] memory _userAddresses) public view returns (
        address[] memory userAddressArr,
        uint256[] memory lockEndTimeArr,
        uint256[] memory lockedAmountArr,
        bool[] memory isActiveArr
    ) {
        uint256 len = _userAddresses.length;
        address userAddress;
        uint256 lockEndTime;
        uint256 lockedAmount;
        bool isActive;
        userAddressArr = new address[](len);
        lockEndTimeArr = new uint256[](len);
        lockedAmountArr = new uint256[](len);
        isActiveArr = new bool[](len);
        for (uint256 i = 0; i < len; i++) {
            //console.log(_userAddresses[i]);
            (userAddress, lockEndTime, lockedAmount, isActive) = fetchUserInfo(_userAddresses[i]);
            userAddressArr[i] = userAddress;
            lockEndTimeArr[i] = lockEndTime;
            lockedAmountArr[i] = lockedAmount;
            isActiveArr[i] = isActive;
        }
    }
}