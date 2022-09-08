// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/[email protected]/access/OwnableUpgradeable.sol";
import "@openzeppelin/[email protected]/security/PausableUpgradeable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20FlashMintUpgradeable.sol";
import "@openzeppelin/[email protected]/proxy/utils/Initializable.sol";
import "@openzeppelin/[email protected]/proxy/utils/UUPSUpgradeable.sol";

contract KishibeTally is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20SnapshotUpgradeable, OwnableUpgradeable, PausableUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable, ERC20FlashMintUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("KishibeTally", "KST");
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __Ownable_init();
        __Pausable_init();
        __ERC20Permit_init("KishibeTally");
        __ERC20Votes_init();
        __ERC20FlashMint_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 100 * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }
}