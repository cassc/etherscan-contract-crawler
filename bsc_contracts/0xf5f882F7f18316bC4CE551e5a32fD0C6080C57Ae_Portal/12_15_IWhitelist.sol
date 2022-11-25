// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IWhitelist {
    
    function tokenList(address token) external returns (bool);

    function poolTokensList(address pool) external returns (address[] calldata);

    function checkDestinationToken(address pool, int128 index) external view returns(bool);

    function nativeReturnAmount() external returns(uint256);

    function stableFee() external returns(uint256);

}