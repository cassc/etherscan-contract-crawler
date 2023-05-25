//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Blacklisted is Ownable {
    mapping (address => bool) public blacklist;

    event BlacklistedWallet(address wallet, bool status);

    function setupBlacklist(address[] calldata _addresses, bool[] calldata _statuses) external onlyOwner {
        uint256 n = _addresses.length;

        for (uint256 i; i < n; i++) {
            blacklist[_addresses[i]] = _statuses[i];
            emit BlacklistedWallet(_addresses[i], _statuses[i]);
        }
    }

    function _beforeTokenTransfer(address _from, address _to, uint256) internal virtual {
        if (blacklist[_to] || blacklist[_from]) {
            revert("address blacklisted");
        }
    }
}