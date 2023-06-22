// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Bone is ERC20, ERC20Burnable, Ownable {
    
    error NotAllowed();

    mapping(address => bool) public controllers;

    constructor() ERC20("Bone", "BONE") {
        controllers[msg.sender] = true;
    }

    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        if (controllers[msg.sender]) {
            _burn(account, amount);
        } else {
            super.burnFrom(account, amount);
        }
    }

    /* Staking Contract has to be added as a Controller in Order to award Tokens for Staking */

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        if (!controllers[msg.sender]) revert NotAllowed();
        super._beforeTokenTransfer(from, to, amount);
    }
}