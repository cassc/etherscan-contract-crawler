// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

library SmartPoolStorage {

    bytes32 public constant sSlot = keccak256("SmartPoolStorage.storage.location");

    struct Storage {
        mapping(FeeType => Fee) fees;
        mapping(address => uint256) nets;
        address token;
        address am;
        address weth;
        uint256 cap;
        uint256 lup;
        bool suspend;
        bool allowJoin;
        bool allowExit;
    }

    struct Fee {
        uint256 ratio;
        uint256 denominator;
        uint256 lastTimestamp;
        uint256 minLine;
    }

    enum FeeType{
        JOIN_FEE, EXIT_FEE, MANAGEMENT_FEE, PERFORMANCE_FEE,TURNOVER_FEE
    }

    function load() internal pure returns (Storage storage s) {
        bytes32 loc = sSlot;
        assembly {
            s.slot := loc
        }
    }
}