pragma solidity >=0.5.0;

interface ISolidlyVoter {
    function gauges(address token) external view returns (address);
}