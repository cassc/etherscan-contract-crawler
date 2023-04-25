/**
 *Submitted for verification at Etherscan.io on 2023-04-24
*/

// SPDX-License-Identifier: MIT
// Portal..: https://t.me/kekwerc20
// Website..: https://kekw-erc.com
// Twitter..: https://twitter.com/kekwcoinerc 

pragma solidity 0.8.19;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function kekwlol(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function kekwnation(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract KEKW is  IERC20{
    

    function name() public pure returns (string memory) {
        return "KEKW";
    }

    function symbol() public pure returns (string memory) {
        return "KEKW";
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

    
    function kekwlol(address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return 0;
    }

    
    function approve(address spender, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function kekwnation(address sender, address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    

    receive() external payable {}

    
}