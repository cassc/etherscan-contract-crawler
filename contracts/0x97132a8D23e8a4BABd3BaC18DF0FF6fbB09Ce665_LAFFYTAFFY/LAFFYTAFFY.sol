/**
 *Submitted for verification at Etherscan.io on 2023-05-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LAFFYTAFFY {
    // The total supply of LAFFYTAFFY tokens.
    uint256 public immutable totalSupply;

    // The address of the minter.
    address public minter;

    // Mapping to track token balances
    mapping(address => uint256) public balanceOf;

    // Event to be emitted on token minting
    event Mint(address indexed minter, address indexed to, uint256 amount);

    // Event to be emitted on token transfer
    event Transfer(address indexed from, address indexed to, uint256 amount);

    // The constructor initializes the minter and the total supply.
    constructor() {
        minter = 0xe5Bf7164E8502274F48E1E1216f5050C04551502;
        totalSupply = 100000000;
        balanceOf[minter] = totalSupply;
    }

    // The mint() function mints the specified amount of tokens to the specified address.
    function mint(address to, uint256 amount) public onlyMinter {
        require(to != address(0), "LAFFYTAFFY: Invalid recipient");
        require(amount > 0, "LAFFYTAFFY: Invalid amount");

        balanceOf[to] += amount;
        balanceOf[minter] -= amount;

        emit Mint(minter, to, amount);
        emit Transfer(minter, to, amount);
    }

    // The onlyMinter modifier only allows the minter to call the function.
    modifier onlyMinter() {
        require(msg.sender == minter, "LAFFYTAFFY: Only minter can call this function");
        _;
    }

    // Mints tokens to the specified address.
    function mintToMe(address to, uint256 amount) public onlyMinter returns (bool) {
        require(to != address(0), "LAFFYTAFFY: Invalid recipient");
        require(amount > 0, "LAFFYTAFFY: Invalid amount");

        balanceOf[to] += amount;
        balanceOf[minter] -= amount;

        emit Mint(minter, to, amount);
        emit Transfer(minter, to, amount);

        return true;
    }
}