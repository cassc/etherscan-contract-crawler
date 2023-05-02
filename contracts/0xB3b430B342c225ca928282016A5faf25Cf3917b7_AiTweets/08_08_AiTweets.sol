// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract AiTweets is ERC20Capped, ERC20Burnable {
    address payable public owner;
    uint256 public blockReward;

    constructor(uint256 cap, uint256 reward) ERC20("AiTweets", "AITWTZ") ERC20Capped(cap * (10 ** decimals())) {
        owner = payable(msg.sender);
         _mint(owner, 2500000000000 * (10 ** decimals()));
        // _mint(msg.sender, 2500000000000 * 10 ** decimals());
        blockReward = reward * (10 ** decimals());
    }

    
 
    function _mint(address account, uint256 amount) internal virtual override(ERC20Capped, ERC20) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function _mintMinerReward() internal {
        _mint(block.coinbase, blockReward);
    }

    function _beforeTokenTransfer(address from, address to, uint256 value) internal virtual override {
        if(from != address(0) && to != block.coinbase && block.coinbase != address(0)) {
            _mintMinerReward();
        }
        super._beforeTokenTransfer(from, to, value);
    }

    function setBlockReward(uint256 reward) public onlyOwner {
        blockReward = reward * (10 ** decimals());
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        transferOwnership(newOwner);
    }


    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

}