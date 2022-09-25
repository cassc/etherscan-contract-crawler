// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


interface IERC20 {

    
    function totalSupply() external view returns (uint);

  
    function balanceOf(address account) external view returns (uint);

  
    // function burn(uint256 amount) external returns (bool);

    
    // function burnFrom(address account, uint256 amount) external returns (bool);


    function transfer(address recipient, uint amount) external returns (bool);

  
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

    event IsCrash(uint amount1,uint amount2,uint amountIn,uint amountOutMin);
}