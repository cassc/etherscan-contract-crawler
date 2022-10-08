// SPDX-License-Identifier: MIT
//.___________. __  .__   __. ____    ____      ___           _______..___________..______        ______
//|           ||  | |  \ |  | \   \  /   /     /   \         /       ||           ||   _  \      /  __  \
//`---|  |----`|  | |   \|  |  \   \/   /     /  ^  \       |   (----``---|  |----`|  |_)  |    |  |  |  |
//    |  |     |  | |  . `  |   \_    _/     /  /_\  \       \   \        |  |     |      /     |  |  |  |
//    |  |     |  | |  |\   |     |  |      /  _____  \  .----)   |       |  |     |  |\  \----.|  `--'  |
//    |__|     |__| |__| \__|     |__|     /__/     \__\ |_______/        |__|     | _| `._____| \______/

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AstroToken is AccessControl, ERC20Burnable {
  bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

  constructor() ERC20("AstroToken", "$ASTRO") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function mint(address account, uint256 amount) external onlyRole(MINT_ROLE) {
    _mint(account, amount);
  }
}