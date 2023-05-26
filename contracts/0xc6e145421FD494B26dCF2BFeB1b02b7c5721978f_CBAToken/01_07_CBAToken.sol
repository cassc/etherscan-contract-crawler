// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract CBAToken is ERC20Burnable,Ownable {
    uint256 public constant INITIAL_SUPPLY = 3_000_000_000 * 10**18;
    constructor(address wallet,address owner) ERC20("Crypto Perx", "CPRX") {
        require(owner != address(0), 'CPRX: incorrect owner address');
        require(wallet != address(0), 'CPRX: incorrect wallet address');
        if (_msgSender() != owner) {
            transferOwnership(owner);
        }
        _mint(wallet, INITIAL_SUPPLY);
    }
}