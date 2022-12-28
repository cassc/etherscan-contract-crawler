//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract GOLD is ERC20Pausable, AccessControl {
    bytes32 public constant GAMER_ROLE = keccak256("GAMER_ROLE");
    bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor() ERC20("GOLD TOKEN", "GOLD") {
        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
        _grantRole(PAUSER_ROLE,msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function rewardMint(address account, uint256 amount) public onlyRole(REWARDER_ROLE) returns (bool){
        _mint(account, amount);
        return true;
    }

    function gameMint(address account, uint256 amount) public onlyRole(GAMER_ROLE) returns (bool){
        _mint(account, amount);
        return true;
    }

    function gameBurn(address account, uint256 amount) public onlyRole(GAMER_ROLE) returns (bool){
        _burn(account, amount);
        return true;
    }

    function gameTransfer(address from, address to, uint256 amount) public onlyRole(GAMER_ROLE) returns (bool){
        _transfer(from, to, amount);
        return true;
    }

    function gameApprove(address owner, address spender, uint256 amount) public onlyRole(GAMER_ROLE) returns (bool) {
        _approve(owner, spender, amount);
        return true;
    }
}