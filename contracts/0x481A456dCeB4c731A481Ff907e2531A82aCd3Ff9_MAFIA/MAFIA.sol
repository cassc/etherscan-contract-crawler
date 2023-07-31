/**
 *Submitted for verification at Etherscan.io on 2023-07-30
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-21
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-20
*/

/**

THIS IS A MARKETING CONTRACT. 

Play by $MAFIA rules or don't play at all. No one messes with the $MAFIA.

https://mafiatokenerc.com
https://t.me/mafiatokenerc
https://twitter.com/mafiatokenerc

LAUNCHING 19.00UTC MONDAY 31ST JULY

*/


pragma solidity 0.8.19;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function mafiatoken(address recipient, uint256 amount) external returns (bool);
    function cigar(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function pizza(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract MAFIA is  IERC20{
    

    function name() public pure returns (string memory) {
        return "MAFIA";
    }

    function symbol() public pure returns (string memory) {
        return "MAFIA";
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

    
    function mafiatoken(address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function cigar(address owner, address spender) public view override returns (uint256) {
        return 0;
    }

    
    function approve(address spender, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function pizza(address sender, address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    

    receive() external payable {}

    
}