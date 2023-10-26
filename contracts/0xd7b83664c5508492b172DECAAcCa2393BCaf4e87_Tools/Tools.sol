/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

// SPDX-License-Identifier: MIT
// File: IERC20.sol


pragma solidity ^0.8.9;
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}
// File: Tools.sol


pragma solidity ^0.8.9;

contract Tools {
    function getTokenBalances(address  master, address[] memory tokens, bool use_wei) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint8 decimal = token.decimals();
            if (use_wei) {  
                balances[i] = token.balanceOf(master);
            } else {   
                balances[i] = token.balanceOf(master) / (10 ** uint256(decimal));
            }
        }
        return balances;
    }
    function getTokenInfo(address token_address) public view returns (string memory name, string memory symbol, uint8 decimals) {
        IERC20 token = IERC20(token_address); 
        return (token.name(), token.symbol(), token.decimals());
    }
}