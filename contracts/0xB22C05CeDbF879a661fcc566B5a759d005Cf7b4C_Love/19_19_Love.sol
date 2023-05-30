// SPDX-License-Identifier: UNLICENSED

/*
██╗░░░░░░█████╗░██╗░░░██╗███████╗
██║░░░░░██╔══██╗██║░░░██║██╔════╝
██║░░░░░██║░░██║╚██╗░██╔╝█████╗░░
██║░░░░░██║░░██║░╚████╔╝░██╔══╝░░
███████╗╚█████╔╝░░╚██╔╝░░███████╗
╚══════╝░╚════╝░░░░╚═╝░░░╚══════╝
*/

/// @title Love Token
/// @author M1LL1P3D3

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Love is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    
    bool public mintingActive;
    bool public originBalanceRequired = true;

    mapping(address => bool) public minters;
    mapping(address => bool) public blacklist;
    
    constructor() ERC20("Love", "LOVE") ERC20Permit("Love") {}

    function flipMinter(address _minter) external onlyOwner {
        minters[_minter] = !minters[_minter];
    }

    function flipBlacklist(address _blacklist) external onlyOwner {
        blacklist[_blacklist] = !blacklist[_blacklist];
    }

    function flipMintingActive() external onlyOwner {
        mintingActive = !mintingActive;
    }

    function flipOriginBalanceRequired() external onlyOwner {
        originBalanceRequired = !originBalanceRequired;
    }

    function mint(address to, uint256 amount) external {
        require(mintingActive, "Minting is not active.");
        require(minters[msg.sender], "Only permissioned addresses can mint.");
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal override(ERC20) {
        require(!blacklist[from] && !blacklist[to], "Blacklisted!");
        if(from != address(0) && originBalanceRequired){
            require(balanceOf(tx.origin) > 0, "Transaction origin must have a balance.");
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}