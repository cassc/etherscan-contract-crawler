/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract BSCSWAPBNBSwap {
    address public owner;
    address public bscswapTokenAddress = 0xBFd0eB7E332531A35235dc1bb66935f4a3Aa0670; // Replace with actual BSCSWAP token address
    uint256 public swapRate = 1000000;
    uint256 public swapLimit = 168;
    uint256 public swapFee = 0.0078 ether;
    
    event Swap(address indexed user, uint256 bscswapAmount, uint256 bnbAmount);
    event Fee(address indexed user, uint256 amount);

    mapping(address => uint256) public limit;
    
    constructor() {
        owner = msg.sender;
    }
    
    function sendBNBToContract() payable public {
        require(msg.value == 0.01 ether, "Please send exactly 0.01 BNB");
    }

    function swap(uint256 bscswapAmount, address addr) payable public {
        // require(msg.value == swapRate * bscswapAmount, "Insufficient BNB");
        require(msg.value == 0.01 ether, "Please send exactly 0.01 BNB");
        require(bscswapAmount > 0, "Invalid BSCSWAP amount");
        require(bscswapAmount <= swapLimit, "Exceeds swap limit");
        require(limit[msg.sender] <= swapLimit, "Exceeds swap limit");
        
        uint256 bnbamount = bscswapAmount/swapRate;
        
        IERC20(bscswapTokenAddress).transferFrom(msg.sender, address(this), bscswapAmount);
        address payable recipient = payable(address(addr));  // cast msg.sender to payable address
        recipient.transfer(bnbamount*10**18);

        // payable(owner).transfer(msg.value);
        emit Swap(msg.sender, bscswapAmount, bnbamount);
        limit[msg.sender] += bscswapAmount;
    }
    
    function withdrawFee(uint256 amount) public {
        require(msg.sender == owner, "Unauthorized");
        payable(owner).transfer(amount);
    }
    
    function clearEth(uint256 amount) public {
        require(msg.sender == owner, "Unauthorized");
        payable(owner).transfer(address(this).balance);
    }

    function setSwapLimit(uint256 limit) public {
        require(msg.sender == owner, "Unauthorized");
        swapLimit = limit;
    }
    
    function setSwapFee(uint256 fee) public {
        require(msg.sender == owner, "Unauthorized");
        swapFee = fee;
    }
}