pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

library LockLib {

    enum LockType {
        None, NoBurnPool, NoIn, NoOut, NoTransaction,
        PenaltyOut, PenaltyIn, PenaltyInOrOut, Master, LiquidityAdder
    }

    struct TargetPolicy {
        LockType lockType;
        uint16 penaltyRateOver1000;
        bool isPermanent;
    }
}