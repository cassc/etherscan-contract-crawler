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
import "../interfaces/IContractWhitelist.sol";

abstract contract ContractWhitelist is IContractWhitelist, Ownable {
    /// @notice marks if a contract whitelist is enabled.
    bool public whitelistEnabled;
    /// @notice mapping of whitelisted contracts.
    mapping(address => bool) public whitelist;

    event UpdateWhitelistStatus(bool whitelistEnabled);
    event UpdateContractWhitelist(address indexed whitelistAddress, bool whitelistEnabled);

    /// @dev checks if whitelist is enabled and if contract is whitelisted
    modifier checkEOAorWhitelist() {
        // If whitelist is enabled and sender is not EOA
        if (whitelistEnabled && msg.sender != tx.origin) {
            require(whitelist[msg.sender], "checkWhitelist: not in whitelist");
        }
        _;
    }

    /// @notice enables smart contract whitelist
    function toggleWhitelist() external virtual onlyOwner {
        whitelistEnabled = !whitelistEnabled;
        emit UpdateWhitelistStatus(whitelistEnabled);
    }

    /// @notice Enable or disable a contract address on the whitelist
    /// @param _address Address to update on whitelist
    /// @param _enabled Set if the whitelist is enabled or disabled
    function setContractWhitelist(address _address, bool _enabled) external onlyOwner {
        _setContractWhitelist(_address, _enabled);
    }

    /// @notice Enable or disable contract addresses on the whitelist
    /// @param _addresses Addressed to update on whitelist
    /// @param _enabled Set if the whitelist is enabled or disabled for each address passed
    function setBatchContractWhitelist(address[] memory _addresses, bool[] memory _enabled) external onlyOwner {
        require(_addresses.length == _enabled.length, "array mismatch");
        for (uint256 i = 0; i < _addresses.length; i++) {
            _setContractWhitelist(_addresses[i], _enabled[i]);
        }
    }

    /// @notice Enable or disable a contract address on the whitelist
    /// @param _address Address to update on whitelist
    /// @param _enabled Set if the whitelist is enabled or disabled
    function _setContractWhitelist(address _address, bool _enabled) internal virtual {
        whitelist[_address] = _enabled;
        emit UpdateContractWhitelist(_address, _enabled);
    }
}