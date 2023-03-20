// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Whitelist is Ownable, Pausable {
    mapping(address => bool) private whitelistedMap;

    event Whitelisted(address indexed account, bool isWhitelisted);

    function whitelisted(address _address) external view returns (bool) {
        if (paused()) {
            return false;
        }

        return whitelistedMap[_address];
    }

    function addAddress(address _address) external onlyOwner {
        require(whitelistedMap[_address] != true);
        whitelistedMap[_address] = true;
        emit Whitelisted(_address, true);
    }

    function addAddresses(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistedMap[_addresses[i]] = true;
            emit Whitelisted(_addresses[i], true);
        }
    }

    function removeAddress(address _address) external onlyOwner {
        require(whitelistedMap[_address] != false);
        whitelistedMap[_address] = false;
        emit Whitelisted(_address, false);
    }

    function removeAddresses(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistedMap[_addresses[i]] = false;
            emit Whitelisted(_addresses[i], false);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}