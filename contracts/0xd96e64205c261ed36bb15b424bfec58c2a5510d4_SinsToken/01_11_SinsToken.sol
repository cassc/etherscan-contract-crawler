// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/*

  _________                           __  .__              _____                __  .__             ________              .__.__          
 /   _____/__.__. _____ ___________ _/  |_|  |__ ___.__. _/ ____\___________  _/  |_|  |__   ____   \______ \   _______  _|__|  |   ______
 \_____  <   |  |/     \\____ \__  \\   __\  |  <   |  | \   __\/  _ \_  __ \ \   __\  |  \_/ __ \   |    |  \_/ __ \  \/ /  |  |  /  ___/
 /        \___  |  Y Y  \  |_> > __ \|  | |   Y  \___  |  |  | (  <_> )  | \/  |  | |   Y  \  ___/   |    `   \  ___/\   /|  |  |__\___ \ 
/_______  / ____|__|_|  /   __(____  /__| |___|  / ____|  |__|  \____/|__|     |__| |___|  /\___  > /_______  /\___  >\_/ |__|____/____  >
        \/\/          \/|__|       \/          \/\/                                      \/     \/          \/     \/                  \/ 

I see you nerd! ⌐⊙_⊙
*/

contract SinsToken is ERC20, ERC20Capped, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC20Capped(360000000000000000000000000) {
        _mint(msg.sender, 360000000 * 10 ** decimals());
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Capped) {
        super._mint(to, amount);
    }
}