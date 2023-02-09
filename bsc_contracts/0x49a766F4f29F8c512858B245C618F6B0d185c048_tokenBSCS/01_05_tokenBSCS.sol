// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract tokenBSCS is ERC20 {
    constructor() public ERC20("bscs", "BSCS") {
    }

    function mintToken(uint _amount, address _to) public {
        _mint(_to, _amount);
    }
}