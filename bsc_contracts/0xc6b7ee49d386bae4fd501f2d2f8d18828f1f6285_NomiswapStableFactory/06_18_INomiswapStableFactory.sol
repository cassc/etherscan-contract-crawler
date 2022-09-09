// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

import "./INomiswapFactory.sol";

interface INomiswapStableFactory is INomiswapFactory {

    function rampA(address _pair, uint32 _futureA, uint40 _futureTime) external;
    function stopRampA(address _pair) external;
    
}