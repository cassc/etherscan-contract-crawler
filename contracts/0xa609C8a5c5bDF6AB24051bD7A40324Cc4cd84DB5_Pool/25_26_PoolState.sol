// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../token/IDollar.sol";
import "../dao/IDAO.sol";

contract PoolAccount {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }

    struct State {
        uint256 staged;
        uint256 claimable;
        uint256 bonded;
        uint256 phantom;
        uint256 fluidUntil;
    }
}

contract PoolStorage {
    enum LPType {
        univ2,
        crv3,
        other
    }

    struct Provider {
        IERC20 lpToken;
    }

    struct Balance {
        uint256 staged;
        uint256 claimable;
        uint256 bonded;
        uint256 phantom;
        uint256 reward;
    }

    struct State {
        Balance balance;
        Provider provider;
        LPType lpType;
        uint256 ratio;
        bool paused;
        mapping(address => PoolAccount.State) accounts;
    }
}

contract PoolState {
    mapping(uint256 => PoolStorage.State) _state; // pool id => state
    uint256 poolCount;
    address daoAddress;
    address dollarAddress;
}