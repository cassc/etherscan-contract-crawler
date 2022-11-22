// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DEV is ERC20 {
    constructor() ERC20("DeviantsFactions", "DEV") {
        _mint(_msgSender(), 1_000_000_000 * (10 ** uint256(decimals())));
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}