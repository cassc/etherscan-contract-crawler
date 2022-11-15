// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;
import "./ABDKMath64x64.sol";

interface IILockTosV2 {
    function epochUnit() external view returns(uint256);
}


/// @title LibStaking
library LibStaking
{
    struct Epoch {
        uint256 length_; // in seconds
        uint256 end; // timestamp
    }

    struct UserBalance {
        address staker;
        uint256 deposit;    //tos staking 양
        uint256 ltos;       //변환된 LTOS 양
        uint256 endTime;    //끝나는 endTime
        uint256 marketId;   //bondMarketId
    }

    function pow (int128 x, uint n) public pure returns (int128 r) {
        r = ABDKMath64x64.fromUInt (1);
        while (n > 0) {
            if (n % 2 == 1) {
                r = ABDKMath64x64.mul (r, x);
                n -= 1;
            } else {
                x = ABDKMath64x64.mul (x, x);
                n /= 2;
            }
        }
    }

    function compound (uint principal, uint ratio, uint n) public pure returns (uint) {
        return ABDKMath64x64.mulu (
                pow (
                ABDKMath64x64.add (
                    ABDKMath64x64.fromUInt (1),
                    ABDKMath64x64.divu (
                    ratio,
                    10**18)),
                n),
                principal);
    }

}