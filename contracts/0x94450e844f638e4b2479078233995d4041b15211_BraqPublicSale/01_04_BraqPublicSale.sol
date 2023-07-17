// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BraqPublicSale is Ownable {
    bool publicSaleStarted = false;
    mapping(address => bool) private whitelist;
    
    uint256 public allowListSupply = 2 * 10 ** 6;
    uint256 public publicSaleSupply = 1750000;
    address private BraqTokenContractAddress;
    IERC20 private BraqTokenInstance;

    constructor(address _tokenContract){
        BraqTokenContractAddress = _tokenContract;
        BraqTokenInstance = IERC20(BraqTokenContractAddress);
    }

    function setTokenContract(address tokenAddress) external onlyOwner{
        BraqTokenContractAddress = tokenAddress;
        BraqTokenInstance = IERC20(BraqTokenContractAddress);
    }

    function addToWhitelist(address[] calldata toAddAddresses) 
    external onlyOwner
    {
        for (uint i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
        }
    }

    function startPublicSale() external onlyOwner{
        publicSaleStarted = true;
    }

    function stopPublicSale() external onlyOwner{
        publicSaleStarted = false;
    }
    
    function justSell(uint256 value, address buyer) private {
        uint256 BraqAmount = uint256(value / (6 * 10 ** 13));
        require(BraqAmount<publicSaleSupply, "Error: Too big amount for purchase");
        BraqTokenInstance.transfer(buyer, BraqAmount * 10 ** 18);
        publicSaleSupply -= BraqAmount;
    }
    
    function publicSale() public payable {
        require(publicSaleStarted, "Public Sale stoped!");
        require(msg.value >= 0.025 * 10 ** 18, "Error: Too small amount for purchase");
        if(whitelist[msg.sender]){
            uint256 BraqAmount = msg.value / (5 * 10 ** 13);
            if(BraqAmount<allowListSupply){
                BraqTokenInstance.transfer(msg.sender, BraqAmount * 10 ** 18);
                allowListSupply -= BraqAmount;
            }
            else{justSell(msg.value, msg.sender);}
        }
        else{justSell(msg.value, msg.sender);}
    }

    function getAllowListSupply() external view onlyOwner returns(uint256){
        return allowListSupply;
    }

    function getTokenAddress() external view returns(address){
        return BraqTokenContractAddress;
    }

    function withdraw(uint256 amount) external onlyOwner { // Amount in wei
        require(address(this).balance > amount , "Insufficient contract balance");
        // Transfer ETH to the caller
        payable(msg.sender).transfer(amount);
    }

}