// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract PKT is ERC20, ERC20Burnable, ERC20Snapshot, AccessControl, Pausable, Ownable {
    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply,

        address _owner,
        address _pause
    )
    ERC20(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(SNAPSHOT_ROLE, _owner);
        _grantRole(PAUSER_ROLE, _pause);
        

        _mint(_owner, _supply);
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
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }


    // ** onlyOwner **
    function grantRoleSnapshot(address user) public onlyOwner {
        _grantRole(SNAPSHOT_ROLE, user);
    }
    function revokeRoleSnapshot(address user) public onlyOwner {
        _revokeRole(SNAPSHOT_ROLE, user);
    }
    function grantRolePauser(address user) public onlyOwner {
        _grantRole(PAUSER_ROLE, user);
    }
    function revokeRolePauser(address user) public onlyOwner {
        _revokeRole(PAUSER_ROLE, user);
    }
}