// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";




contract HIUSDToken is ERC20, ERC20Burnable {
    
    constructor() ERC20("HIUSD Token", "HIUSD") {
        _mint(
            0x50364669d49eA174dCb03514eB6937C965239722,
            100000000 * (10**uint256(decimals()))
        );
        
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    
}