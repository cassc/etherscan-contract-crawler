pragma solidity ^0.8.0;

interface IExchange {
    //
    function shareExchangeFeeRewardToken() external;

    function getNewShareExchangeFeeRewardToken(address token)
        external
        view
        returns (uint256);

    function addRewardToken(address _addr) external;
}