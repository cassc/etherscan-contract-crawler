//SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract BackedToken is ERC20, ERC20Detailed, ERC20Burnable, Ownable {
    
    bool _unlocked;
    address private _ownerToken;
    mapping(address => bool) private _lockedList;

    constructor() public ERC20() ERC20Detailed("BACKED", "BAKT", 18) {
        _mint(msg.sender, 100000000 * 10**18);
        _ownerToken = msg.sender;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(_unlocked || from == _ownerToken, "token transfer while locked");
        require(!_lockedList[from], "token transfer locked");
        super._transfer(from, to, amount);
    }
    
    function lockAddress(address add) external onlyOwner {
        _lockedList[add] = true;
    }

    function unlockAddress(address add) external onlyOwner {
        _lockedList[add] = false;
    }

    function unlock() external onlyOwner {
        _unlocked = true;
    }
}