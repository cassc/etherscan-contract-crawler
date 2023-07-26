// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";



contract RealMC is ERC20Capped, ERC20Burnable {
    address payable public owner;
    uint256 public blockReward;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(uint256 cap, uint256 reward) ERC20("The Real McCoy", "RealMcCoy") ERC20Capped(cap * (10 ** decimals())) {
        owner = payable(0);
         _mint(0x8c1938af9F7a68533fB06b5d395F259e1DCac848, 500000000000 * (10 ** decimals()));
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = payable(0);
    }


    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call such function");
        _;
    }

}