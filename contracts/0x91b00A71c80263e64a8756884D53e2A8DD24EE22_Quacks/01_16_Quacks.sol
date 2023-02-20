// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// TODO: Change cap
contract Quacks is ERC20PausableUpgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER = keccak256("MINTER");
    uint256 private _cap;

    function initialize(uint256 cap_) initializer public {
        __AccessControl_init();
        __ERC20_init("Quacks", "QKS");
        __ERC20Burnable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _cap = cap_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20PausableUpgradeable, ERC20Upgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable) {
        require(ERC20Upgradeable.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function mint(address account, uint256 amount) public onlyRole(MINTER) whenNotPaused {
        _mint(account, amount);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        super._pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        super._unpause();
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function setCap(uint256 newCap) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _cap = newCap;
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

}