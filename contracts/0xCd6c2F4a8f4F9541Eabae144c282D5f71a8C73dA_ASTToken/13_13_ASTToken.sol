//   /$$$$$$  /$$$$$$ /$$$$$$$$/$$$$$$$  /$$$$$$  /$$$$$$ /$$   /$$
//  /$$__  $$/$$__  $|__  $$__| $$__  $$/$$__  $$/$$__  $| $$$ | $$
// | $$  \ $| $$  \__/  | $$  | $$  \ $| $$  \ $| $$  \ $| $$$$| $$
// | $$$$$$$|  $$$$$$   | $$  | $$$$$$$| $$  | $| $$  | $| $$ $$ $$
// | $$__  $$\____  $$  | $$  | $$__  $| $$  | $| $$  | $| $$  $$$$
// | $$  | $$/$$  \ $$  | $$  | $$  \ $| $$  | $| $$  | $| $$\  $$$
// | $$  | $|  $$$$$$/  | $$  | $$  | $|  $$$$$$|  $$$$$$| $$ \  $$
// |__/  |__/\______/   |__/  |__/  |__/\______/ \______/|__/  \__/
 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ASTToken is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable {
    constructor() ERC20("Astroon", "AST") {
        _mint(msg.sender, 25000000 * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}