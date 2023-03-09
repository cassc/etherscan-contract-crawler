// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
    bool public isWhitelistEnabled;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public amount;

    event WhitelistedAddressAdded(address addr, uint256 amount);
    event WhitelistedAddressRemoved(address addr);
    event WhitelistEnabled(address who);
    event WhitelistDisabled(address who);

    modifier onlyWhitelisted() {
        if (isWhitelistEnabled) {
            require(whitelist[msg.sender], "FXD: Not on the whitelist");
        }
        _;
    }

    function addAddressToWhitelist(address addr, uint256 _amount)
        public
        onlyOwner
        returns (bool success)
    {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            amount[addr] = _amount;
            emit WhitelistedAddressAdded(addr, _amount);
            success = true;
        }
    }

    function addAddressesToWhitelist(
        address[] calldata addrs,
        uint256[] calldata _amount
    ) public onlyOwner returns (bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i], _amount[i])) {
                success = true;
            }
        }
    }

    function removeAddressFromWhitelist(address addr)
        public
        onlyOwner
        returns (bool success)
    {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            amount[addr] = 0;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    function removeAddressesFromWhitelist(address[] calldata addrs)
        public
        onlyOwner
        returns (bool success)
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    function disableWhitelist() external onlyOwner {
        isWhitelistEnabled = false;
        emit WhitelistDisabled(msg.sender);
    }

    function enableWhitelist() external onlyOwner {
        isWhitelistEnabled = true;
        emit WhitelistEnabled(msg.sender);
    }

}