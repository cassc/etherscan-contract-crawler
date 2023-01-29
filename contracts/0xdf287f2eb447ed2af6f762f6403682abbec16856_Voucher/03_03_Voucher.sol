// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract Voucher is ERC20("VOL", "VOL", 18), Owned {
    mapping(address => bool) public isBlacklisted;

    event SetBlacklisted(address indexed user, bool blacklisted);

    error Blacklisted();
    error NoMinting();

    bool mintable = true;

    modifier notBlacklisted(address user) {
        if (isBlacklisted[user]) revert Blacklisted();
        _;
    }

    constructor(address owner, uint256 totalSupply) Owned(owner) {
        _mint(msg.sender, totalSupply);
    }

    function transfer(address to, uint256 amount)
        public
        override
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        returns (bool)
    {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        override
        notBlacklisted(from)
        notBlacklisted(to)
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }

    function endMintingPhase() onlyOwner external {
        mintable = false;
    }

    function mint(address to, uint256 amount) onlyOwner notBlacklisted(to) external {
        if (!mintable) revert NoMinting();
        _mint(to, amount);
    }

    function burn(uint256 amount) external notBlacklisted(msg.sender) {
        _burn(msg.sender, amount);
    }

    function addToBlacklist(address[] memory users) external onlyOwner {
        _setBlacklist(users, true);
    }

    function removeFromBlacklist(address[] memory users) external onlyOwner {
        _setBlacklist(users, false);
    }

    function _setBlacklist(address[] memory users, bool value) internal {
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            isBlacklisted[user] = value;
            emit SetBlacklisted(user, value);
        }
    }
}