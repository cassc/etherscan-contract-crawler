// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IBotXToken.sol";

contract BotXToken is ERC20, IBotXToken, Ownable {
    mapping(address => bool) private minters;

    modifier onlyMinter() {
        require(minters[_msgSender()], "Caller is not the minter");
        _;
    }

    constructor() ERC20("$CLUB", "CLUB") {
    }

    function _mint(address to, uint256 amount) internal override(ERC20) {
        super._mint(to, amount);
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20) {
        super._burn(account, amount);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

    // Function to grant mint role
    function addMinterRole(address _address) external onlyOwner {
        minters[_address] = true;
    }

    // Function to revoke mint role
    function revokeMinterRole(address _address) external onlyOwner {
        minters[_address] = false;
    }
}