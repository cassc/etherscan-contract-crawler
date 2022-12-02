// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {INFTLocker} from "../interfaces/INFTLocker.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MAHAReferralV1 is Ownable {
    INFTLocker public locker;
    IERC20 public maha;
    uint256 minLockDuration;

    constructor(
        INFTLocker _locker,
        IERC20 _maha,
        uint256 _minLockDuration
    ) {
        locker = _locker;
        maha = _maha;
        minLockDuration = _minLockDuration;
    }

    function createLockWithReferral(
        uint256 _value,
        uint256 _lockDuration,
        bool _stakeNFT,
        address referral
    ) external {
        maha.transferFrom(msg.sender, address(this), _value);
        uint256 nftId = locker.createLockFor(
            _value,
            _lockDuration,
            msg.sender,
            _stakeNFT
        );

        if (_lockDuration > minLockDuration && referral != address(0)) {
            uint256 mahax = locker.balanceOfNFT(nftId);
            maha.transfer(referral, mahax / 10); // give 10% of the mahax value as referral
        }
    }

    function refund() external onlyOwner {
        maha.transfer(msg.sender, maha.balanceOf(address(this)));
    }
}