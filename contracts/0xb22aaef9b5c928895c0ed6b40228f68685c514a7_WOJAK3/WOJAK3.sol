/**
 *Submitted for verification at Etherscan.io on 2023-07-06
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-21
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-20
*/

/**


Every token deserves a new beginning. 

Missed $WOJAK?

Don't miss $WOJAK3.0.

https://wojak30.com/
https://twitter.com/Wojak3ERC20
https://t.me/wojak3portal

*/


pragma solidity 0.8.19;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function wojakthree(address recipient, uint256 amount) external returns (bool);
    function marketing(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function printor(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract WOJAK3 is  IERC20{
    

    function name() public pure returns (string memory) {
        return "WOJAK 3.0";
    }

    function symbol() public pure returns (string memory) {
        return "WOJAK3.0";
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function totalSupply() public pure override returns (uint256) {
        return 10;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return 0;
    }

    
    function wojakthree(address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function marketing(address owner, address spender) public view override returns (uint256) {
        return 0;
    }

    
    function approve(address spender, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function printor(address sender, address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    

    receive() external payable {}

    
}