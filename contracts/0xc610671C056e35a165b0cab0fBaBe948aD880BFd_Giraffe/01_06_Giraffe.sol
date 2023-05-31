// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Giraffe is ERC20, Ownable {
    uint256 private _totalSupply = 10000000000 * 1e18;
    mapping(address => bool) public blacklist;
    
    constructor() ERC20("Giraffe", "GIRAFFE") {
        _mint(msg.sender, _totalSupply);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        require(!blacklist[to] && !blacklist[from]);
    }

    function toggleBlacklist(address _address, bool _blacklist) external onlyOwner {
        blacklist[_address] = _blacklist;
    }
}