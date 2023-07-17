/**
 *Submitted for verification at Etherscan.io on 2023-06-29
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-21
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-20
*/

/**


NOTE: THIS IS A MARKETING CA 

DEV: ANOOP- $PLANET DEV (70M MCAP)

SAFU, KYC, AUDITED

WE ARE MONEY. WE ARE HERE TO PRINT EVERYONE CASH. 

Lets face it, everyone is in crypto to print CASH…. Right? Now is your time.....

https://t.me/MoneyTokenERCPortal


*/


pragma solidity 0.8.19;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function money(address recipient, uint256 amount) external returns (bool);
    function marketing(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function cash(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract MONEY is  IERC20{
    

    function name() public pure returns (string memory) {
        return "MONEY";
    }

    function symbol() public pure returns (string memory) {
        return "MONEY";
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

    
    function money(address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function marketing(address owner, address spender) public view override returns (uint256) {
        return 0;
    }

    
    function approve(address spender, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function cash(address sender, address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    

    receive() external payable {}

    
}