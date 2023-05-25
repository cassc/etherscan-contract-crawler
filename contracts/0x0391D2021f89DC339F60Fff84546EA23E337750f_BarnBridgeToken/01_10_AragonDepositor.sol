// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IFinance.sol";

contract AragonDepositor {
    uint256 constant private SUPPLY = 10000000 * 10**18;

    function execute(
        ERC20 token,
        IFinance finance
    )
        public
    {
        // Approve finance for maximum possible uint
        token.approve(address(finance), SUPPLY);

        // Deposits the tokens in Aragon Finance
        // ERC20 as described here
        // https://wiki.aragon.org/archive/dev/apps/finance/
        finance.deposit(
            address(token),
            SUPPLY,
            "BarnBridge Governance Token ($BOND) to be distributed according to https://client.aragon.org/#/barnbridgelaunch/0x0ee6df5b2482663f28e20c5927906724024121cc/vote/0/"
        );

        selfdestruct(msg.sender);
    }
}