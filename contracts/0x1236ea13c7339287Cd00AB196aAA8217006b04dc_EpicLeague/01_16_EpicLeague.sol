// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/*
* @author Syous
* @title EpicLeague Token
*/
contract EpicLeague is
    ERC20,
    ERC20Burnable,
    ERC20Snapshot,
    AccessControl,
    Pausable
{
    uint256 public constant MAXIMUM_SUPPLY = 1000000000 * 10**18;

    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address owner) ERC20("Epic League", "EPL") {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(SNAPSHOT_ROLE, owner);
        _grantRole(PAUSER_ROLE, owner);
        _grantRole(MINTER_ROLE, owner);
        _mint(owner, MAXIMUM_SUPPLY);
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(
            totalSupply() <= MAXIMUM_SUPPLY,
            "Total Supply should be less than 1 billion"
        );
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}