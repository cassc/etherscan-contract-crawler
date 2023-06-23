// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

contract AntfarmToken is ERC20 {
    constructor() ERC20("Antfarm Token", "ATF", 18) {
        _mint(msg.sender, 10000000 ether);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}