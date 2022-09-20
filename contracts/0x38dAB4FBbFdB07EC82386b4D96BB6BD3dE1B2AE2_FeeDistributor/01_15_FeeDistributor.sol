// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import {console} from "hardhat/console.sol";
import {INFTLocker} from "../interfaces/INFTLocker.sol";
import {IFeeDistributor} from "../interfaces/IFeeDistributor.sol";

contract FeeDistributor is Ownable, IFeeDistributor, ReentrancyGuard {
    uint256 public constant WEEK = 7 * 86400;
    uint256 public constant TOKEN_CHECKPOINT_DEADLINE = 86400;

    uint256 public startTime;
    uint256 public timeCursor;
    mapping(uint256 => uint256) public timeCursorOf;
    mapping(uint256 => uint256) public userEpochOf;

    uint256 public lastTokenTime;
    uint256[1000000000000000] public tokensPerWeek;

    INFTLocker public locker;
    IERC20 public token;
    uint256 public tokenLastBalance;

    uint256[1000000000000000] public veSupply; // VE total supply at week bounds

    bool public isKilled;
    bool public canCheckpointToken = true;

    constructor(
        address _votingEscrow,
        uint256 _startTime,
        address _token
    ) {
        uint256 t = (_startTime / WEEK) * WEEK;
        startTime = t;
        lastTokenTime = t;
        timeCursor = t;
        token = IERC20(_token);
        locker = INFTLocker(_votingEscrow);
    }

    function _checkpointToken() internal {
        // console.log("_checkpointToken(...)");
        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 toDistribute = tokenBalance - tokenLastBalance;
        tokenLastBalance = tokenBalance;

        uint256 t = lastTokenTime;
        uint256 sinceLast = block.timestamp - t;
        lastTokenTime = block.timestamp;

        uint256 thisWeek = (t / WEEK) * WEEK;
        uint256 nextWeek = 0;

        for (uint256 index = 0; index < 20; index++) {
            nextWeek = thisWeek + WEEK;
            if (block.timestamp < nextWeek) {
                if (sinceLast == 0 && block.timestamp == t)
                    tokensPerWeek[thisWeek] += toDistribute;
                else
                    tokensPerWeek[thisWeek] +=
                        (toDistribute * (block.timestamp - t)) /
                        sinceLast;
                break;
            } else {
                if (sinceLast == 0 && nextWeek == t)
                    tokensPerWeek[thisWeek] += toDistribute;
                else
                    tokensPerWeek[thisWeek] +=
                        (toDistribute * (nextWeek - t)) /
                        sinceLast;
            }
            t = nextWeek;
            thisWeek = nextWeek;
        }

        emit CheckpointToken(block.timestamp, toDistribute);
    }

    function checkpointToken() external override {
        require(
            msg.sender == owner() ||
                (canCheckpointToken &&
                    (block.timestamp >
                        lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)),
            "not owner or not allowed"
        );
        _checkpointToken();
    }

    function _findTimestampEpoch(uint256 _timestamp)
        internal
        view
        returns (uint256)
    {
        uint256 min = 0;
        uint256 max = locker.epoch();

        for (uint256 index = 0; index < 128; index++) {
            if (min >= max) {
                break;
            }
            uint256 mid = (min + max + 2) / 2;
            INFTLocker.Point memory pt = locker.pointHistory(mid);

            if (pt.ts <= _timestamp) min = mid;
            else max = mid - 1;
        }

        return min;
    }

    function _findTimestampUserEpoch(
        uint256 nftId,
        uint256 _timestamp,
        uint256 maxUserEpoch
    ) internal view returns (uint256) {
        uint256 min = 0;
        uint256 max = maxUserEpoch;

        for (uint256 index = 0; index < 128; index++) {
            if (min >= max) {
                break;
            }
            uint256 mid = (min + max + 2) / 2;
            INFTLocker.Point memory pt = locker.userPointHistory(nftId, mid);

            if (pt.ts <= _timestamp) min = mid;
            else max = mid - 1;
        }

        return min;
    }

    function _checkpointTotalSupply() internal {
        // console.log("_checkpointTotalSupply(...)");
        uint256 t = timeCursor;
        uint256 roundedTimestamp = (block.timestamp / WEEK) * WEEK;

        locker.checkpoint();

        for (uint256 index = 0; index < 20; index++) {
            if (t > roundedTimestamp) break;
            else {
                uint256 epoch = _findTimestampEpoch(t);
                INFTLocker.Point memory pt = locker.pointHistory(epoch);

                int128 dt = 0;

                if (t > pt.ts) dt = int128(uint128(t - pt.ts));
                veSupply[t] = Math.max(uint128(pt.bias - pt.slope * dt), 0);
            }

            t += WEEK;
        }

        timeCursor = t;
    }

    function checkpointTotalSupply() external override {
        _checkpointTotalSupply();
    }

    function _claim(uint256 nftId, uint256 _lastTokenTime)
        internal
        returns (uint256)
    {
        require(locker.isStaked(nftId), "nft not staked");

        // console.log("inside claim");

        uint256 userEpoch = 0;
        uint256 toDistribute = 0;

        uint256 maxUserEpoch = locker.userPointEpoch(nftId);
        uint256 _startTime = startTime;

        // console.log("if maxUserEpoch = 0", maxUserEpoch);
        if (maxUserEpoch == 0) return 0;

        uint256 weekCursor = timeCursorOf[nftId];
        // console.log("weekCursor     =", weekCursor);

        if (weekCursor == 0)
            userEpoch = _findTimestampUserEpoch(
                nftId,
                _startTime,
                maxUserEpoch
            );
        else userEpoch = userEpochOf[nftId];

        if (userEpoch == 0) userEpoch = 1;

        INFTLocker.Point memory userPoint = locker.userPointHistory(
            nftId,
            userEpoch
        );

        // console.log("userEpoch      =", userEpoch);
        // console.log("weekCursor     =", weekCursor);

        if (weekCursor == 0)
            weekCursor = ((userPoint.ts + WEEK - 1) / WEEK) * WEEK;

        // console.log("weekCursor     =", weekCursor);
        // console.log("_lastTokenTime =", _lastTokenTime);
        // console.log("_startTime     =", _startTime);
        // console.log(
        //     "weekCursor >= _lastTokenTime",
        //     weekCursor >= _lastTokenTime
        // );

        if (weekCursor >= _lastTokenTime) return 0;

        if (weekCursor >= _startTime) weekCursor = _startTime;

        INFTLocker.Point memory oldUserPoint = INFTLocker.Point(0, 0, 0, 0);

        for (uint256 index = 0; index < 50; index++) {
            if (weekCursor >= _lastTokenTime) break;

            if (weekCursor >= userPoint.ts && userEpoch <= maxUserEpoch) {
                userEpoch += 1;
                oldUserPoint = userPoint;

                if (userEpoch > maxUserEpoch)
                    userPoint = INFTLocker.Point(0, 0, 0, 0);
                else userPoint = locker.userPointHistory(nftId, userEpoch);
            } else {
                int128 dt = int128(uint128(weekCursor - oldUserPoint.ts));
                uint256 balanceOf = Math.max(
                    uint128(oldUserPoint.bias - dt * oldUserPoint.slope),
                    0
                );

                if (balanceOf == 0 && userEpoch > maxUserEpoch) break;
                if (balanceOf > 0)
                    toDistribute +=
                        (balanceOf * tokensPerWeek[weekCursor]) /
                        veSupply[weekCursor];

                weekCursor += WEEK;
            }
        }

        userEpoch = Math.min(maxUserEpoch, userEpoch - 1);
        userEpochOf[nftId] = userEpoch;
        timeCursorOf[nftId] = weekCursor;

        emit Claimed(nftId, toDistribute, userEpoch, maxUserEpoch);
        return toDistribute;
    }

    function claim(uint256 nftId)
        external
        override
        nonReentrant
        returns (uint256)
    {
        require(!isKilled, "killed");

        if (block.timestamp >= timeCursor) _checkpointTotalSupply();

        uint256 _lastTokenTime = lastTokenTime;

        if (
            canCheckpointToken &&
            (block.timestamp > lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)
        ) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;

        uint256 amount = _claim(nftId, _lastTokenTime);
        address who = locker.ownerOf(nftId);

        if (amount != 0) {
            tokenLastBalance -= amount;
            token.transfer(who, amount);
        }

        return amount;
    }

    function claimMany(uint256[] memory nftIds)
        external
        override
        nonReentrant
        returns (bool)
    {
        require(!isKilled, "killed");
        if (block.timestamp >= timeCursor) _checkpointTotalSupply();

        uint256 _lastTokenTime = lastTokenTime;

        if (
            canCheckpointToken &&
            (block.timestamp > lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)
        ) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;

        for (uint256 index = 0; index < nftIds.length; index++) {
            uint256 amount = _claim(nftIds[index], _lastTokenTime);
            address who = locker.ownerOf(nftIds[index]);

            if (amount != 0) {
                tokenLastBalance -= amount;
                token.transfer(who, amount);
            }
        }

        return true;
    }

    // @external
    // def burn(_coin: address) -> bool:
    //     """
    //     @notice Receive 3CRV into the contract and trigger a token checkpoint
    //     @param _coin Address of the coin being received (must be 3CRV)
    //     @return bool success
    //     """
    //     assert _coin == self.token
    //     assert not self.isKilled
    //     amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    //     if amount != 0:
    //         ERC20(_coin).transferFrom(msg.sender, self, amount)
    //         if self.canCheckpointToken and (block.timestamp > self.lastTokenTime + TOKEN_CHECKPOINT_DEADLINE):
    //             self._checkpoint_token()
    //     return True

    function toggleAllowCheckpointToken() external onlyOwner {
        canCheckpointToken = !canCheckpointToken;
        emit ToggleAllowCheckpointToken(canCheckpointToken);
    }

    function killMe() external onlyOwner {
        isKilled = true;
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function recoverBalance(IERC20 _coin) external onlyOwner {
        _coin.transfer(msg.sender, _coin.balanceOf(address(this)));
    }
}