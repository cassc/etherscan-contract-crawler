// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

contract Token is ERC20, ERC20Burnable, ERC20Snapshot, ERC20Pausable, Ownable {
    
    uint8 private constant _decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 21e6 * (10**uint256(_decimals));

    mapping(address => bool) public isBlacklisted;

    event Blacklisted(address indexed account, bool value);

    constructor() ERC20("Solidus Coin", "SUL") 
    {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);

        require(!isBlacklisted[from] && !isBlacklisted[to], "Account blacklisted");
    }

    function blacklistMalicious(address account, bool value) external onlyOwner {
        isBlacklisted[account] = value;

        emit Blacklisted(account, value);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function snapshot() external onlyOwner {
        _snapshot();
    }
}