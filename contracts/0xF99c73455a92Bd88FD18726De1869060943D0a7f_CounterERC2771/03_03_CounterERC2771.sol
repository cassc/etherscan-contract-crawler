// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {
    ERC2771Context
} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract CounterERC2771 is ERC2771Context {
    mapping(address => uint256) public contextCounter;

    event IncrementContextCounter(address _msgSender);

    modifier onlyTrustedForwarder() {
        require(
            isTrustedForwarder(msg.sender),
            "Only callable by Trusted Forwarder"
        );
        _;
    }

    //solhint-disable-next-line no-empty-blocks
    constructor(address trustedForwarder) ERC2771Context(trustedForwarder) {}

    function incrementContext() external onlyTrustedForwarder {
        address _msgSender = _msgSender();

        contextCounter[_msgSender]++;
        emit IncrementContextCounter(_msgSender);
    }

    function currentContextCounter(address _msgSender)
        external
        view
        returns (uint256)
    {
        return contextCounter[_msgSender];
    }
}