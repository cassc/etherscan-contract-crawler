// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./Ownable.sol";

contract BlackList is Ownable {

    mapping(address => bool) _blacklist;

    function isBlacklisted(address _maker) public view returns (bool) {
        return _blacklist[_maker];
    }

    function blacklistAccount(address account, bool sign) external onlyOwner {
        _blacklist[account] = sign;
    }
}