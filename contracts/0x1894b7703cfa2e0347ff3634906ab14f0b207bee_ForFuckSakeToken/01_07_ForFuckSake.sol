/*
Just because we can. fksec.vip 
Buy it, sell it, hold it, burn it, trade it, get rich or get rekt - 4FKSEC we don't care.
*/ 

// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract ForFuckSakeToken is ERC20, Pausable, Ownable {

    uint256 private constant ONE_ETHER = 1e18;
    uint256 private constant INITIAL_SUPPLY = 445e9; // FFS billions

    mapping(address => bool) public blacklist;

     bool public limited;
     uint256 public maxHoldingAmount;
     uint256 public minHoldingAmount;
     address public uniswapV3Pair;

    constructor(address creator, address backup) ERC20("ForFuckSake", "4FKSEC") {
        uint256 totalSupply = INITIAL_SUPPLY * ONE_ETHER;  // Mint fkn FFS billion 4FKSEC tokens
        uint256 creatorAllocation = totalSupply / 10; // fkn thx 4 creating the 4FKSEC token
        uint256 backupAllocation = (totalSupply * 2) / 10; // 20% for backup whatever comes up

        _mint(creator, creatorAllocation);
        _mint(backup, backupAllocation);
        _mint(msg.sender, totalSupply - creatorAllocation - backupAllocation); // Remaining tokens to the deployer        

        pause();
    }

    function addToBlacklist(address user) public onlyOwner {
        blacklist[user] = true;
    }

    function removeFromBlacklist(address user) public onlyOwner {
        blacklist[user] = false;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setRule(bool _limited, address _uniswapV3Pair, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        uniswapV3Pair = _uniswapV3Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override virtual whenNotPaused {
        require(!blacklist[from], "4FKSEC: sender is blacklisted");
        require(!blacklist[to], "4FKSEC: recipient is blacklisted");

        if (limited && from == uniswapV3Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount && super.balanceOf(to) + amount >= minHoldingAmount, "Forbidden");
        }
    }
    
    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}