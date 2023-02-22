// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract VeeToken is ERC20, ERC20Burnable {

    uint256 private constant MULTISIG_AMOUNT = 97500000000 ether;
    uint256 private constant INITIAL_LIQUIDITY_AMOUNT = 2500000000 ether;

    constructor(address _multisigAddress, address _lpDeployerAddress) ERC20("Vee Token", "VEE") {
        _mint(_multisigAddress, MULTISIG_AMOUNT);
        _mint(_lpDeployerAddress, INITIAL_LIQUIDITY_AMOUNT);
    }
}