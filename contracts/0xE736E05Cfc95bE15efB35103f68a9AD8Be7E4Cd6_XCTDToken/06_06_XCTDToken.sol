// SPDX-License-Identifier: MIT

pragma solidity 0.8;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract XCTDToken is ERC20Burnable {
    constructor() ERC20("Excited DAO", "XCTD") {
        _mint(_msgSender(), 400_000_000e18);
    }
}