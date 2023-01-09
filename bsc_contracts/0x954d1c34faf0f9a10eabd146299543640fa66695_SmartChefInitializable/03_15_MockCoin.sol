// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockCoin is ERC20 {
    uint8 private immutable _decimals;

    /*
     * Constructor
     * @param name: coin name (e.g. Mock Coin)
     * @param symbol: symbol of the coin (e.g. COIN)
     * @param supply: supply
     * @param decimals: decimals of the token
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply,
        uint8 decimals_,
        address receiver
    ) ERC20(name, symbol) {
        _mint(receiver, supply);
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}