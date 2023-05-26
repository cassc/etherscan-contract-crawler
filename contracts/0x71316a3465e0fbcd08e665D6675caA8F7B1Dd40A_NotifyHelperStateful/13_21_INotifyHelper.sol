pragma solidity 0.5.16;

interface INotifyHelper {
    function notifyProfitSharing() external;
    function lastProfitShareTimestamp() external view returns (uint256);
}