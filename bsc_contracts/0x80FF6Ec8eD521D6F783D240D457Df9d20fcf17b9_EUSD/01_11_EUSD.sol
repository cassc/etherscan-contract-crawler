// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC20Burnable.sol";
import "AccessControl.sol";


contract EUSD is ERC20Burnable, AccessControl {

    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bool public isInitialised;


    modifier checkRole(address account, bytes32 role)
    {
      require(hasRole(role, account), "Role Does Not Exist");
      _;
    }


    constructor() ERC20("EUSD", "EUSD") {
    }


    function initialize() external {
        require(!isInitialised, "Already Initialised");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        isInitialised = true;
    }

    function mint(address to, uint amount) external checkRole(msg.sender, MINT_ROLE) {
        _mint(to, amount);
    }

    function giveRoleMinter(address wallet) external checkRole(msg.sender, DEFAULT_ADMIN_ROLE) {
        grantRole(MINT_ROLE, wallet);
    }

    function revokeRoleMinter(address wallet) external checkRole(msg.sender, DEFAULT_ADMIN_ROLE) {
        revokeRole(MINT_ROLE, wallet);
    }

    function transferRoleOwner(address wallet) external checkRole(msg.sender, DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, wallet);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function renounceOwnership() external checkRole(msg.sender, DEFAULT_ADMIN_ROLE){
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function checkRoleAdmin(address wallet) external view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, wallet);
    }

    function checkRoleMinter(address wallet) external view returns(bool) {
        return hasRole(MINT_ROLE, wallet);
    }

}