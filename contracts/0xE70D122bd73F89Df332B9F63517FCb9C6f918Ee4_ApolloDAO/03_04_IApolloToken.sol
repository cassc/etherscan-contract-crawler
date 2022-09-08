// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function factory() external view returns (address);
}

interface IApolloToken {
    function changeArtistAddress(address newAddress) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function burn(uint256 burnAmount) external;
    function reflect(uint256 tAmount) external;
    function artistDAO() external view returns (address);
    function uniswapRouter() external view returns (IUniswapV2Router02);
}