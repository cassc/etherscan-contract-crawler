pragma solidity ^0.8.0;

interface ISpynLeaderboard {
    function recordStaking(
        address _user,
        address _token,
        uint256 _amount
    ) external;

    function recordUnstaking(
        address _user,
        address _token,
        uint256 _amount
    ) external;

    function hasStaking(address _user) external view returns(bool);
}