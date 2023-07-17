// SPDX-License-Identifier: MIT

//  $$\      $$\  $$$$$$\  $$\      $$\ $$$$$$\ 
//  $$ | $\  $$ |$$  __$$\ $$$\    $$$ |\_$$  _|
//  $$ |$$$\ $$ |$$ /  \__|$$$$\  $$$$ |  $$ |  
//  $$ $$ $$\$$ |$$ |$$$$\ $$\$$\$$ $$ |  $$ |  
//  $$$$  _$$$$ |$$ |\_$$ |$$ \$$$  $$ |  $$ |  
//  $$$  / \$$$ |$$ |  $$ |$$ |\$  /$$ |  $$ |  
//  $$  /   \$$ |\$$$$$$  |$$ | \_/ $$ |$$$$$$\ 
//  \__/     \__| \______/ \__|     \__|\______|

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Wagmi is ERC20 {
    constructor() ERC20("WAGMI", "WGMI") {
        _mint(msg.sender, 69000000000 * 10 ** decimals());
    }
}