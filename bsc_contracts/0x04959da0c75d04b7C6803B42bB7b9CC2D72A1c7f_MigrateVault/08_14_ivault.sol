// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVault {
    function strategist() external view returns (address);

    function addrFactory() external view returns (address);

    function poolSize() external view returns (uint256);

    function depositQuote(uint256 amount) external;

    function depositBase(uint256 amount) external;

    function withdraw(uint256 shares) external;

    function quoteToken() external view returns (address);

    function baseToken() external view returns (address);

    function position() external view returns (uint256);

    function balanceOf() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}