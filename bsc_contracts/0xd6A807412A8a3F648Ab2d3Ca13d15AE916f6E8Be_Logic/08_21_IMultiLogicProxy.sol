// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMultiLogicProxy {
    function releaseToken(uint256 amount, address token) external;

    function takeToken(uint256 amount, address token) external;

    function addEarn(uint256 amount, address blidToken) external;

    function returnToken(uint256 amount, address token) external;

    function setLogicTokenAvailable(
        uint256 amount,
        address token,
        uint256 deposit_withdraw
    ) external;

    function getTokenBalance(address _token, address _logicAddress)
        external
        view
        returns (uint256);
}