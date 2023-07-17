pragma solidity ^0.6.0;

interface IStakeForVnfts {
    function stake(uint256 _amount) external;

    function redeem() external;

    function earned(address account) external view returns (uint256 _earned);

    function exit() external;
}