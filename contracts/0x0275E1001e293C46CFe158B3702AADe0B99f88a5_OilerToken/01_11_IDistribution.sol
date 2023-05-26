pragma solidity 0.5.12;

interface IDistribution {
    function isInitialized() external view returns (bool);
    function distributionStartTimestamp() external view returns (uint256);
    function supply() external view returns(uint256);
    function poolAddress(uint8) external view returns(address);
}