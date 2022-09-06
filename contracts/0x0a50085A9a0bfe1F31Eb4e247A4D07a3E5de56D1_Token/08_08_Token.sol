// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Token is ERC20Upgradeable, OwnableUpgradeable {
    mapping (address => bool) public freezer;

    event Frozen(address account);
    event Unfrozen(address account);

    modifier onlyUnfrozen(address account) {
        require(freezer[account] == false, "Account is frozen");

        _;
    }

    function initialize(
        address _owner
    ) external initializer {
        __ERC20_init("AEDV DEMO", "AEDVDEMO");
        _transferOwnership(_owner);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function mint(address account, uint amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint amount) external onlyOwner {
        _burn(account, amount);
    }

    function freeze(address account) external onlyOwner {
        freezer[account] = true;

        emit Frozen(account);
    }

    function unfreeze(address account) external onlyOwner {
        freezer[account] = false;

        emit Unfrozen(account);
    }

    // override transferring with freezing check
    function transfer(
        address to,
        uint256 amount
    ) public virtual override onlyUnfrozen(msg.sender) onlyUnfrozen(to) returns (bool) {
        address owner = _msgSender();

        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override onlyUnfrozen(msg.sender) onlyUnfrozen(from) onlyUnfrozen(to) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
}