// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         
 * App:             https://ApeSwap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * Discord:         https://discord.com/ApeSwap
 * Reddit:          https://reddit.com/r/ApeSwap
 * Instagram:       https://instagram.com/ApeSwap.finance
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IContractWhitelist.sol";

abstract contract ContractWhitelist is IContractWhitelist, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private contractWhitelistSet;
    /// @notice marks if a contract whitelist is enabled.
    bool public whitelistEnabled;

    event UpdateWhitelistStatus(bool whitelistEnabled);
    event UpdateContractWhitelist(address indexed whitelistAddress, bool whitelistEnabled);

    /// @dev checks if whitelist is enabled and if contract is whitelisted
    modifier checkEOAorWhitelist() {
        // If whitelist is enabled and sender is not EOA
        if (whitelistEnabled && msg.sender != tx.origin) {
            require(isWhitelisted(msg.sender), "checkWhitelist: not in whitelist");
        }
        _;
    }

    /// @notice Get the number of addresses on the whitelist
    function getWhitelistLength() external view virtual override returns (uint256) {
        return contractWhitelistSet.length();
    }

    /// @notice Find the address on the whitelist of the provided index
    /// @param _index Index to query
    function getWhitelistAtIndex(uint256 _index) external view virtual override returns (address) {
        return contractWhitelistSet.at(_index);
    }

    /// @notice Check if an address is whitelisted
    /// @param _address Address to query
    function isWhitelisted(address _address) public view virtual override returns (bool) {
        return contractWhitelistSet.contains(_address);
    }

    /// @notice enables smart contract whitelist
    function setWhitelistEnabled(bool _enabled) external virtual override onlyOwner {
        whitelistEnabled = _enabled;
        emit UpdateWhitelistStatus(whitelistEnabled);
    }

    /// @notice Enable or disable a contract address on the whitelist
    /// @param _address Address to update on whitelist
    /// @param _enabled Set if the whitelist is enabled or disabled
    function setContractWhitelist(address _address, bool _enabled) external override onlyOwner {
        _setContractWhitelist(_address, _enabled);
    }

    /// @notice Enable or disable contract addresses on the whitelist
    /// @param _addresses Addressed to update on whitelist
    /// @param _enabled Set if the whitelist is enabled or disabled for each address passed
    function setBatchContractWhitelist(address[] calldata _addresses, bool[] calldata _enabled) external override onlyOwner {
        require(_addresses.length == _enabled.length, "array mismatch");
        for (uint256 i = 0; i < _addresses.length; i++) {
            _setContractWhitelist(_addresses[i], _enabled[i]);
        }
    }

    /// @notice Enable or disable a contract address on the whitelist
    /// @param _address Address to update on whitelist
    /// @param _enabled Set if the whitelist is enabled or disabled
    function _setContractWhitelist(address _address, bool _enabled) internal virtual {
        if(_enabled) {
            require(contractWhitelistSet.add(_address), "address already enabled");
        } else {
            require(contractWhitelistSet.remove(_address), "address already disabled");
        }
        emit UpdateContractWhitelist(_address, _enabled);
    }
}