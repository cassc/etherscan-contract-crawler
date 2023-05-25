pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TempleERC20Token is ERC20, ERC20Burnable, Ownable, AccessControl {
    bytes32 public constant CAN_MINT = keccak256("CAN_MINT");

    constructor() ERC20("Temple", "TEMPLE") {
        _setupRole(DEFAULT_ADMIN_ROLE, owner());
    }

    function mint(address to, uint256 amount) external {
      require(hasRole(CAN_MINT, msg.sender), "Caller cannot mint");
      _mint(to, amount);
    }

    function addMinter(address account) external onlyOwner {
        grantRole(CAN_MINT, account);
    }

    function removeMinter(address account) external onlyOwner {
        revokeRole(CAN_MINT, account);
    }
}