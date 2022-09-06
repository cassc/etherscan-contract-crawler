//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Warded.sol";

abstract contract WardedLiving is Warded {
    uint256 alive;

    modifier live {
        require(alive != 0, "WardedLiving/not-live");
        _;
    }

    function stop() external auth {
        alive = 0;
    }

    function run() public auth {
        alive = 1;
    }
}