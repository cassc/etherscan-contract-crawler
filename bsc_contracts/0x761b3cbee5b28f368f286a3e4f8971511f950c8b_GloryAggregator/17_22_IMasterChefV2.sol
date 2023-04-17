pragma solidity ^0.8.6;

import "./IBEP20.sol";

interface IMasterChefV2 {
    struct PoolInfo {
        uint256 accCakePerShare;
        uint256 lastRewardBlock;
        uint256 allocPoint;
        uint256 totalBoostedShare;
        bool isRegular;
    }

    function poolInfo(uint256 index) external view returns (PoolInfo memory);

    function lpToken(uint256 index) external view returns (IBEP20);

    function poolLength() external view returns (uint256 pools);

    function pendingCake(
        uint256 _pid,
        address _user
    ) external view returns (uint256);

    function cakePerBlock(bool _isRegular) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;
}