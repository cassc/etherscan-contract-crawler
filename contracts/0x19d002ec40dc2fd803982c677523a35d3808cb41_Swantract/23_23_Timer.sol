pragma solidity ^0.8.0;

struct Timer {
    uint256  end;
}

library Timerlib {
    // future time in unix seconds 
    function setTimer(Timer storage self, uint256 timestamp) internal { //_timer storage timer, 
        self.end = timestamp;
    }

    function hasStarted(Timer memory self) internal pure returns (bool) {
        return self.end > 0;
    }

    function hasExpired(Timer memory self) internal view returns (bool) {
        return hasStarted(self) && self.end <= block.timestamp;
    }
}