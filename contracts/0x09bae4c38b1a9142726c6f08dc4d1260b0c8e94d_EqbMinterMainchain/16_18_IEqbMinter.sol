// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IEqbMinter {
    function mint(address _to, uint256 _amount) external returns (uint256);

    event Minted(address indexed _to, uint256 _amount);
    event MintedAmountUpdated(uint256 _amount);
    event AccessUpdated(address _operator, bool _access);
}