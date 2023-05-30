// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external;
}

/// @custom:security-contact [email protected]
contract Go_Buzz is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20SnapshotUpgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    UUPSUpgradeable
{
    IAntisnipe public antisnipe;
    bool public antisnipeDisable;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init('Go_Buzz', 'BUZZ');
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __Ownable_init();
        __ERC20Permit_init('Go_Buzz');
        __ERC20Votes_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 1_000_000_000_000 * 10**decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20SnapshotUpgradeable) {
        if (from == address(0) || to == address(0)) return;
        if (!antisnipeDisable && address(antisnipe) != address(0))
            antisnipe.assureCanTransfer(msg.sender, from, to, amount);
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
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

    function setAntisnipeDisable() external onlyOwner {
        require(!antisnipeDisable);
        antisnipeDisable = true;
    }

    function setAntisnipeAddress(address addr) external onlyOwner {
        antisnipe = IAntisnipe(addr);
    }
}