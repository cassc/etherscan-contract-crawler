// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Kuma is ERC20Burnable, Ownable {
    mapping (address => bool) private _blacklist;

    constructor() ERC20("Kumamon", "KUMA") {
        _mint(0x7989570B10C052F4640Dd532e0AddD7CB215534F, 4215367769999989 * 10 ** 17);
    }

    function addToBlackList(address _address) external onlyOwner {
        _blacklist[_address] = true;
    }

    function removeFromBlackList(address _address) external onlyOwner {
        _blacklist[_address] = false;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!_blacklist[from], "blacklisted");
    }
}