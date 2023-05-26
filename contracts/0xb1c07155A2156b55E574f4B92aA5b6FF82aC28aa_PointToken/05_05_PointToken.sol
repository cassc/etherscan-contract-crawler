// contracts/PointToken.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// MAX SUPPLY = 1,405,389,530 POINT

// Note: this ERC20 token is a bridged token from the native POINT on Point Network chain

contract PointToken is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 1_405_389_530 * 10**18;
    uint8 public constant DECIMALS = 18;

    constructor() ERC20("Point", "POINT") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}