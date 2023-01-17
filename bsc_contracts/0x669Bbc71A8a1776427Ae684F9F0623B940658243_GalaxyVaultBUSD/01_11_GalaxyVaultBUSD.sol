// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./tokens/ERC4626.sol";

contract GalaxyVaultBUSD is ERC4626 {
    constructor(address _underlying) ERC4626(IERC20Metadata(_underlying)) ERC20("Galaxy Finance BUSD Vault Token", "glxBUSD") {} 
}