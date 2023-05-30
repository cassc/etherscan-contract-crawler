// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract GRENDIZER is ERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 private constant MAX_WALLET_SIZE = 50;
    uint256 private constant MAX_WALLET_PERCENTAGE = 1;
    uint256 private _maxWalletAmount = 0;
    mapping(address => bool) private _isExcludedFromMaxWallet;
    
    constructor() ERC20("FARCRY", "FAR") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
        _maxWalletAmount = totalSupply().mul(MAX_WALLET_PERCENTAGE).div(100);
    }
    
    function setMaxWalletPercentage(uint256 maxWalletPercentage) external onlyOwner {
        require(maxWalletPercentage > 0 && maxWalletPercentage <= 100, "Invalid percentage");
        _maxWalletAmount = totalSupply().mul(maxWalletPercentage).div(100);
    }
    
    function excludeFromMaxWallet(address account) external onlyOwner {
        _isExcludedFromMaxWallet[account] = true;
    }
    
    function includeInMaxWallet(address account) external onlyOwner {
        _isExcludedFromMaxWallet[account] = false;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (_isExcludedFromMaxWallet[msg.sender] == false && _isExcludedFromMaxWallet[recipient] == false) {
            uint256 recipientBalance = balanceOf(recipient);
            require(recipientBalance.add(amount) <= _maxWalletAmount, "Max wallet size exceeded");
        }
        return super.transfer(recipient, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (_isExcludedFromMaxWallet[sender] == false && _isExcludedFromMaxWallet[recipient] == false) {
            uint256 recipientBalance = balanceOf(recipient);
            require(recipientBalance.add(amount) <= _maxWalletAmount, "Max wallet size exceeded");
        }
        return super.transferFrom(sender, recipient, amount);
    }
    
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
    
    function burnFrom(address account, uint256 amount) public {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, msg.sender, currentAllowance.sub(amount));
        _burn(account, amount);
    }
    
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
    
    // Multicall function from MakerDAO
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success, "Multicall failed");
            results[i] = result;
        }
        return results;
    }
}