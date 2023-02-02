// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RUDAtradeGold is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => bool) public isBlackListed;

    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);

    constructor() ERC20("RUDAtrade Gold", "RTGLD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        require(isBlackListed[from] == false, "Address is blacklisted");
        super._beforeTokenTransfer(from, to, amount);
    }

    function getBlackListStatus(address _user) public view returns (bool) {
        return isBlackListed[_user];
    }
    
    function addBlackList(address _evilUser) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }
}