// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "./IFinance.sol";

contract BarnBridgeToken is ERC20Burnable {
    uint256 constant private SUPPLY = 10000000 * 10**18;

    constructor(
        address aragonDepositor
    )
        public
        ERC20(
            "BarnBridge Governance Token",
            "BOND"
        )
    {
        _mint(aragonDepositor, SUPPLY);
    }
}