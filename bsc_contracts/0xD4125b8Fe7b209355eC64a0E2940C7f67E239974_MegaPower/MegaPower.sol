/**
 *Submitted for verification at BscScan.com on 2023-02-25
*/

/**
 *Submitted for verification at BscScan.com on 2023-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface BEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MegaPower{
    BEP20 public busd = BEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address signer;
    
    event Stake(address depositor, uint256 amount);
    event StakeDistribution(address receiver, uint256 amount);
   
    modifier signature(){
        require(msg.sender == signer,"Invalid Signer!");
        _;
    }
    
    modifier security {
        uint size;
        address sandbox = msg.sender;
        assembly { size := extcodesize(sandbox) }
        require(size == 0, "Smart contract detected!");
        _;
    }

    function getContractInfo() view public returns(uint256 contractBalance){
        return contractBalance = busd.balanceOf(address(this));
    }

    constructor() public {
        signer = msg.sender;
    }

    function deposit(uint256 amount) public security{
        busd.transferFrom(msg.sender,address(this),amount);
        emit Stake(msg.sender, amount);
    }

    function multisend(address [] memory contributors, uint256 [] memory amount) public security{
        for(uint256 i = 0; i < contributors.length; i++){
            busd.transferFrom(msg.sender,contributors[i],amount[i]);
        }
    }

    function stakeDistribution(address _address, uint _amount) external signature security{
        busd.transfer(_address,_amount);
        emit StakeDistribution(_address,_amount);
    }

}