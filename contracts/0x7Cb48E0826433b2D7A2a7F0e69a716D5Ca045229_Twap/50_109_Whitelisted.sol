// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/GSN/Context.sol';

import './interfaces/IWhitelist.sol';

abstract contract Whitelisted is Context {
    IWhitelist public whitelist;

    modifier onlyWhitelisted(bytes32[] calldata proof) {
        require(
            whitelist.whitelisted(_msgSender(), proof),
            "Whitelisted::onlyWhitelisted: Caller is not whitelisted / proof invalid"
        );
        _;
    }
}