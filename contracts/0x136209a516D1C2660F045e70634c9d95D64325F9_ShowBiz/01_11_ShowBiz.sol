// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ShowBiz is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    uint _maxSupply = 0;

    constructor() ERC20("Show Biz", "SHOW") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(_maxSupply == 0 || totalSupply() + amount <= _maxSupply, "max supply exceeded");
        _mint(to, amount);
    }
    
    function maxSupply() public view returns(uint) {
        return _maxSupply;
    }
    
    function setMaxSupply(uint maxSupply_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _maxSupply = maxSupply_;
    }
}