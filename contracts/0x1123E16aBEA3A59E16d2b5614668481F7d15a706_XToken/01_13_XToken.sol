// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract XToken is ERC20, Pausable, AccessControl {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to admin.");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function addAdmin(address account) public onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function delAdmin() public {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address _to, uint256 _amount) public onlyAdmin {
        _mint(_to, _amount);
    }

    function burn(address _account, uint256 _amount) public onlyAdmin {
        _burn(_account, _amount);
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }
}