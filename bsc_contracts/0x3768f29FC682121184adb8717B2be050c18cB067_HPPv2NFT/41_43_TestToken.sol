//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract AToken is ERC20Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint b = 0;

    constructor() ERC20("A TOKEN", "AToken") {
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
        _grantRole(PAUSER_ROLE,msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function e() public {
        require(1<0,"????");
        pause();
    }

    function r() public returns (uint) {
        require(1>0,"!!!");
        uint a = 1;
        b = b + a;
        return b;
    }
}