// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract NoContractUpgradeable is OwnableUpgradeable {

    event ContractWhitelistChanged(address indexed addr, bool isWhitelisted);

    /// @notice Contracts that are allowed to interact with functions executing the {noContract} modifier.
    /// @dev See the {noContract} modifier for more info
    mapping(address => bool) public whitelistedContracts;

    /// @dev Modifier that ensures that non-whitelisted contracts can't interact with functions executing it.
    modifier noContract() {
        require(
            msg.sender == tx.origin || whitelistedContracts[msg.sender],
            "NO_CONTRACTS"
        );
        _;
    }

    function __noContract_init() internal onlyInitializing {
        __Ownable_init();
    }

    /// @notice Allows the owner to whitelist/blacklist contracts
    /// @param addr The contract address to whitelist/blacklist
    /// @param isWhitelisted Whereter to whitelist or blacklist `_contract`
    function setContractWhitelisted(address addr, bool isWhitelisted)
        external
        onlyOwner
    {
        whitelistedContracts[addr] = isWhitelisted;

        emit ContractWhitelistChanged(addr, isWhitelisted);
    }

    uint256[50] __gap;
}