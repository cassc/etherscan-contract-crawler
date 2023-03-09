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

    function fetchUserInfo(address _userAddress) public view returns (uint256 lockEndTime, uint256 lockedAmount, bool isActive) {
        (, , , , , lockEndTime, , , lockedAmount) = ICakePool(cakePoolAddress).userInfo(_userAddress);
        isActive = IPancakeProfile(pancakeProfileAddress).getUserStatus(_userAddress);
    }

    function batchFetchUserInfo(address[] calldata _userAddresses) public view returns (
        uint256[] memory lockEndTimeArr,
        uint256[] memory lockedAmountArr,
        bool[] memory isActiveArr
    ) {
        uint256 len = _userAddresses.length;
        uint256 lockEndTime;
        uint256 lockedAmount;
        bool isActive;
        for (uint256 i = 0; i < len; i++) {
            (lockEndTime, lockedAmount, isActive) = fetchUserInfo(_userAddresses[i]);
            lockEndTimeArr[i] = lockEndTime;
            lockedAmountArr[i] = lockedAmount;
            isActiveArr[i] = isActive;
        }
    }
}

// 0x45c54210128a065de780C4B0Df3d16664f7f859e,0xdf4dbf6536201370f95e06a0f8a7a70fe40e388a
// 0x1DF5bd59312EC550f63c62D0e5116623aeE18F33