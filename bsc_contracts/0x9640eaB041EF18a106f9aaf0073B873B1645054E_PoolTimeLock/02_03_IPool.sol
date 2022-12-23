// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPool {
    function deposit() external payable;

    function totalStaked() external view returns (uint256);

    function getInvalidTokens(address to_, address token_) external;

    function togglePause() external;

    function transferOwnership(address newOwner) external;

    function renounceOwnership() external;
}