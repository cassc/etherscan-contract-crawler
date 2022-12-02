pragma solidity 0.8.6;

import "./IFlashloanWrapper.sol";

interface IAutoHedgeLeveragedPositionFactory {
    event LeveragedPositionCreated(address indexed creator, address lvgPos);

    function flw() external view returns (IFlashloanWrapper);

    function createLeveragedPosition() external returns (address lvgPos);
}