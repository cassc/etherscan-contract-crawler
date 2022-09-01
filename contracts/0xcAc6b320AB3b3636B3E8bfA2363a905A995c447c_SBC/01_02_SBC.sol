// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "solmate/src/tokens/ERC20.sol";

contract SBC is ERC20 {
    mapping(address => bool) public owners;

    modifier onlyOwner() {
        require(owners[msg.sender], "try OWNING it's FREE");
        _;
    }

    constructor() ERC20("SBC", "SBC", 18) {
        owners[msg.sender] = true;
    }

    function setOwner(address _owner, bool _isOwner) external onlyOwner {
        owners[_owner] = _isOwner;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}