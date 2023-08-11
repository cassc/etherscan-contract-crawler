// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./access/AccessProtected.sol";

contract FitCoin is ERC20, ERC20Burnable, AccessProtected {

    uint256 public MAX_SUPPLY;

    constructor(uint256 maxSupply) ERC20("Fitcoin","FITCO") {
        MAX_SUPPLY = maxSupply;
    }

    function mint(address to, uint256 amount) public onlyAdmin {
        require(amount + totalSupply() <= MAX_SUPPLY, "Can not mint more than max supply");
        _mint(to, amount);
    }

    function withDrawErc20(uint256 amount_, address tokenAddress) external onlyOwner{
        IERC20(tokenAddress).transfer(msg.sender, amount_);
    }

    function withdrawEth(uint256 amount_)external onlyOwner{
        (bool sent,) = msg.sender.call{value: amount_}("");
        require(sent, "Failed to send Ether");
    }
    
}