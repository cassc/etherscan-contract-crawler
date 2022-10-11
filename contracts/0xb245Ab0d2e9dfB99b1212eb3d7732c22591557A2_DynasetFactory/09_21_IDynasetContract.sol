// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IDynasetContract {
    /**
     * @dev Token record data structure
     * @param bound is token bound to pool
     * @param ready has token been initialized
     * @param lastDenormUpdate timestamp of last denorm change
     * @param desiredDenorm desired denormalized weight (used for incremental changes)
     * @param index of address in tokens array
     * @param balance token balance
     */
    struct Record {
        bool bound; // is token bound to dynaset
        bool ready;
        uint256 index; // private
        uint256 balance;
    }

    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut
    );

    event LOG_JOIN(
        address indexed tokenIn,
        address indexed caller,
        uint256 tokenAmountIn
    );

    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256 tokenAmountOut
    );

    event LOG_DENORM_UPDATED(address indexed token, uint256 newDenorm);

    event LOG_DESIRED_DENORM_SET(address indexed token, uint256 desiredDenorm);

    event LOG_MINIMUM_BALANCE_UPDATED(address token, uint256 minimumBalance);

    event LOG_TOKEN_READY(address indexed token);

    event LOG_PUBLIC_SWAP_TOGGLED(bool enabled);

    function initialize(
        address[] calldata tokens,
        uint256[] calldata balances,
        address tokenProvider
    ) external;

    function joinDynaset(uint256 _amount) external returns (uint256);

    function exitDynaset(uint256 _amount) external;

    function getController() external view returns (address);

    function isBound(address t) external view returns (bool);

    function getNumTokens() external view returns (uint256);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getTokenRecord(address token)
        external
        view
        returns (Record memory record);

    function getBalance(address token) external view returns (uint256);

    function setDynasetOracle(address oracle) external;
    
    function withdrawFee(address token, uint256 amount) external;

}