// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {INFTLocker} from "../interfaces/INFTLocker.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MAHAReferralV1 is Ownable {
    INFTLocker public locker;
    IERC20 public maha;
    uint256 public minLockDuration;
    uint256 public referralDenominator = 10;
    address internal me;

    event ReferralPaid(
        address indexed who,
        address indexed referral,
        uint256 amt,
        uint256 mahax
    );

    constructor(
        INFTLocker _locker,
        IERC20 _maha,
        uint256 _minLockDuration
    ) {
        locker = _locker;
        maha = _maha;
        minLockDuration = _minLockDuration;

        maha.approve(
            address(locker),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );

        me = address(this);
    }

    function createLockWithReferral(
        uint256 _value,
        uint256 _lockDuration,
        bool _stakeNFT,
        address referral
    ) external {
        maha.transferFrom(msg.sender, me, _value);

        uint256 nftId = locker.createLockFor(
            _value,
            _lockDuration,
            msg.sender,
            _stakeNFT
        );

        if (_lockDuration > minLockDuration && referral != address(0)) {
            uint256 mahax = locker.balanceOfNFT(nftId);
            uint256 reward = mahax / referralDenominator; // give 10% of the mahax value as referral

            if (maha.balanceOf(me) > reward) {
                maha.transfer(referral, reward);
                emit ReferralPaid(referral, msg.sender, reward, mahax);
            }
        }
    }

    function setParams(uint256 _minLockDuration, uint256 _referralDenominator)
        external
        onlyOwner
    {
        minLockDuration = _minLockDuration;
        referralDenominator = _referralDenominator;
    }

    function refund() external onlyOwner {
        maha.transfer(msg.sender, maha.balanceOf(address(this)));
    }
}