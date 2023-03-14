// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts/access/Ownable.sol";
import "../@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RealWorldAsset is ERC20, Ownable {

    uint256 private constant INITIAL_SUPPLY = 1_000_000_000;

    constructor(address owner) ERC20("Real World Asset", "RWA") {
        super.transferOwnership(owner);
        super._mint(owner, INITIAL_SUPPLY * 10 ** 18);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        super._mint(account, amount);
    }
}