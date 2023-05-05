// Website:
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract OnlyFans is ERC20 {
    constructor() ERC20("onlyfanseth.xyz", "ONLYFANS") {
        _mint(msg.sender, 69_000_000_000 ether);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function onlyfans() public pure returns (string memory) {
        return unicode"💋";
    }
}