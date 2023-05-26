// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./token/ERC20.sol";
import "./extensions/ERC20Burnable.sol";
import "./extensions/ERC20Pausable.sol";
import "./access/AccessControlEnumerable.sol";
import "./utils/Context.sol";


contract Nexums is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TREASURY = keccak256("TREASURY");
    uint8 private _decimals = 8;
    uint256 private immutable _cap = 500000000000000000;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= _cap, "Nexums: cap exceeded");
        super._mint(account, amount);
    }

    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Nexums: must have minter role to mint");
        require(hasRole(TREASURY, to), "Nexums: must have treasury address to mint");
        _mint(to, amount);
    }

    function mint2cap(address to) public virtual {
       uint256 amount = _cap - 	totalSupply();
       require((amount > 0), "Nexums: nothing to mint");
       mint(to, amount);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Nexums: must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Nexums: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}