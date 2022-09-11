// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IAuthenticatedProxy {
    function initialize(
        address _owner,
        address _authorizationManager,
        address _WETH
    ) external;

    function setRevoke(bool revoke) external;

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function withdrawETH() external;

    function withdrawToken(address token) external;

    function delegatecall(address dest, bytes memory data) external returns (bool, bytes memory);
}