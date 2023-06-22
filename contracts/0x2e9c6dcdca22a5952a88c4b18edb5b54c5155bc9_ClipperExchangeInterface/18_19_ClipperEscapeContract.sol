// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "./libraries/UniERC20.sol";

import "./ClipperPool.sol";

// Simple escape contract. Only the owner of Clipper can transmit out.
contract ClipperEscapeContract {
    using UniERC20 for ERC20;

    ClipperPool theExchange;

    constructor() {
        theExchange = ClipperPool(payable(msg.sender));
    }

    // Need to be able to receive escaped ETH
    receive() external payable {
    }

    function transfer(ERC20 token, address to, uint256 amount) external {
        require(msg.sender == theExchange.owner(), "Only Clipper Owner");
        token.uniTransfer(to, amount);
    }
}