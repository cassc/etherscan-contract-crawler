// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin-contracts/access/Ownable.sol";
import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

contract HottersToken is Ownable, ERC20 {

    /**
     * @notice Initializes the contract
     * @param vault_ Address of vault to receive tokens
     * @param initialSupply_ Total supply of the token
     */
    constructor(address vault_, uint256 initialSupply_) ERC20("Hotters", "HOTS") {
        _mint(vault_, initialSupply_);
    }
}