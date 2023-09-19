// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IDABotWhitelist.sol";

struct BotWhitelistData {
    uint scope;    // an integer flag to determine the scope where whitelist is apply
    mapping(address => uint) whitelist;
}

library DABotWhitelistLib {

    bytes32 constant WHITELIST_STORAGE_POSITION = keccak256("whitelist.dabot.storage");

    function whitelist() internal pure returns(BotWhitelistData storage ds) {
        bytes32 position = WHITELIST_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function isWhitelist(address account, uint scope) internal view returns(bool) {
        BotWhitelistData storage data = whitelist();
        if (data.scope & scope == 0)
            return true;
        return (data.whitelist[account] & scope) > 0;
    }
}