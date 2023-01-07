//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ILock {
    event LiquidityLockAdded(
        address token,
        uint256 amount,
        address owner,
        string token0Name,
        string token1Name,
        string token0Symbol,
        string token1Symbol,
        uint256 endDateTime,
        uint256 startDateTime
    );
    event TokenLockAdded(
        address token,
        uint256 amount,
        address owner,
        string name,
        string symbol,
        uint8 decimals,
        uint256 endDateTime,
        uint256 startDateTime
    );
    event UnlockLiquidity(address token, uint256 amount, uint256 endDateTime, address owner);
    event UnlockToken(address token, uint256 amount, uint256 endDateTime, address owner);
    event LockExtended(
        address token,
        uint256 endDateTime,
        bool isLiquidity,
        uint256 updateEndDateTime,
        address owner
    );
    struct TokenList {
        uint256 amount;
        uint256 startDateTime;
        uint256 endDateTime;
        address owner;
        address creator;
    }

    function liquidities(uint256) external view returns (address);

    function tokens(uint256) external view returns (address);

    function add(
        address _token,
        uint256 _endDateTime,
        uint256 _amount,
        address _owner,
        bool _isLiquidity
    ) external;

    function unlockLiquidity(address _token) external returns (bool);

    function unlockToken(address _token) external returns (bool);

    function extendLock(
        address _token,
        uint256 _endDateTime,
        bool _isLiquidity,
        uint256 _updateEndDateTime
    ) external;
}