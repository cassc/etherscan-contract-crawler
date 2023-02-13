// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../token/IDollar.sol";
import "../oracle/IOracle.sol";
import "../external/Decimal.sol";
import "../coupon/ICoupon.sol";

contract Account {
    enum Status {
        Frozen,
        Fluid,
        Locked
    }

    struct AccountState {
        uint256 staged;
        uint256 couponStaged;
        uint256 balance;
        uint256 fluidUntil;
        uint256 lockedUntil;
    }
}

contract Epoch {
    struct Global {
        uint256 start;
        uint256 period;
        uint256 current;
    }

    struct EpochState {
        uint256 bonded;
    }
}

contract Storage {
    struct Provider {
        IDollar dollar;
        IOracle oracle;
        address pool;
        ICoupon coupon;
        address dontdiememe;
    }

    struct Balance {
        uint256 supply;
        uint256 bonded;
        uint256 staged;
        uint256 couponStaged;
    }

    struct StotageState {
        Epoch.Global epoch;
        Balance balance;
        Provider provider;
        Decimal.D256 price;
        mapping(address => Account.AccountState) accounts;
        mapping(uint256 => Epoch.EpochState) epochs;
    }
}

contract State {
    Storage.StotageState _state;
}