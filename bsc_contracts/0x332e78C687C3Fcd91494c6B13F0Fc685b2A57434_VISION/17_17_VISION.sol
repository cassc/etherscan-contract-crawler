// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @custom:security-contact [email protected]
contract VISION is ERC20, ERC20Burnable, ERC20Snapshot, AccessControl, Pausable {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor() ERC20(_getName(), _getSymbol()) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SNAPSHOT_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

        uint256 totalSupply = 1_000_000_000;
        _mint(msg.sender, totalSupply * 10 ** decimals());
    }

    function snapshot() external onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _getName() pure internal virtual returns(string memory) {
        return "VISION";
    }

    function _getSymbol() pure internal virtual returns(string memory) {
        return "VISION";
    }
}