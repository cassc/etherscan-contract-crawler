/**
 *Submitted for verification at Etherscan.io on 2023-06-21
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-20
*/

/**

this is just a contract for free marketing, Saving funds for real marketing.

Sick of playing cat and mouse in life's grimy labyrinth? 🐁

Welcome to $RATRACE, your golden cheese at the end of this drab corporate tunnel....

https://twitter.com/ratracetokenerc
https://ratraceerc.com/
https://t.me/ratracetokenerc

*/


pragma solidity 0.8.19;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function ratrace(address recipient, uint256 amount) external returns (bool);
    function marketing(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function cheese(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract RATRACE is  IERC20{
    

    function name() public pure returns (string memory) {
        return "RATRACE";
    }

    function symbol() public pure returns (string memory) {
        return "RATRACE";
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function totalSupply() public pure override returns (uint256) {
        return 1000000;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return 0;
    }

    
    function ratrace(address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function marketing(address owner, address spender) public view override returns (uint256) {
        return 0;
    }

    
    function approve(address spender, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function cheese(address sender, address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    

    receive() external payable {}

    
}