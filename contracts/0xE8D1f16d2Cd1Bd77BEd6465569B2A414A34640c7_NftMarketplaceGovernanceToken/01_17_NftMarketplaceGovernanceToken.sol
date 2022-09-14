// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

contract NftMarketplaceGovernanceToken is ERC20VotesUpgradeable {
    /// @notice ensures that initialize can only be called through proxy
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        uint256 maxSupply
    ) public initializer {
        _mint(msg.sender, maxSupply);
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20VotesUpgradeable) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }
}