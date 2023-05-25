// SPDX-License-Identifier: MIT
// 0.8.7+commit.e28d00a7
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MontePlatform is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant LOCK_TRANSFER_ROLE = keccak256("LOCK_TRANSFER_ROLE");

    mapping(address => bool) internal _fullLockList;

    event fullLockEvent(address indexed account, bool isLocked);

    constructor() ERC20("Monte Marketing Platform Coin", "MONTE") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        // After contract issuance, Minting is planned using TimeLock contract
        //uint256 _total = 1* 10 ** 8 * 10 ** decimals();
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(LOCK_TRANSFER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function fullLockAddress(address account) external onlyRole(LOCK_TRANSFER_ROLE) returns (bool) {
        _fullLockList[account] = true;
        emit fullLockEvent(account , true);
        return true;
    }

    function unFullLockAddress(address account) external onlyRole(LOCK_TRANSFER_ROLE) returns (bool) {
        delete _fullLockList[account];
        emit fullLockEvent(account , false);
        return true;
    }

    function fullLockedAddressList(address account) external view virtual returns (bool) {
        return _fullLockList[account];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        require(!_fullLockList[from], "Token transfer from LockedAddressList");
        super._beforeTokenTransfer(from, to, amount);
    }
}