// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract NameAsSymbolERC20 is ERC20 {
    constructor(string memory name) ERC20(name,'') {
        require(bytes(name).length > 0, "Name length must be > 0");
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function symbol() public view virtual override returns (string memory)
    {    
            return ERC20.name();
    }
}