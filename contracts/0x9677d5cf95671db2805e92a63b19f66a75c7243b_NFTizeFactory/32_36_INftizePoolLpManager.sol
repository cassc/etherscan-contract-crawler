pragma solidity ^0.8.10;

import "./LPData.sol";

interface INftizePoolLpManager {
    function claimTheosLiquidity(address poolToken, LPData memory lpTokenAddress) external;
}