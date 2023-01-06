// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-contracts/token/ERC20/ERC20.sol";

// This contract is just for fun. 
// Do not invest unless you really want to.
contract NeoCoin is ERC20 {
    IERC20 public immutable usdcToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    mapping(address => uint256) public balances;

    constructor() ERC20("NeoCoin", "NEO0O0o0Oo0o00") {}

    function mintNeo(uint256 _amount) public {
       require (_amount > 0, "Amount must be greater than 0");
        
        balances[msg.sender] += _amount;

        usdcToken.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }

    function burnNeo(uint256 _amount) public {
        uint256 withdrawBalance = balances[msg.sender];

        require(_amount > 0 && _amount <= withdrawBalance, "Amount must be > 0 and <= to current balance");
        
        balances[msg.sender] = withdrawBalance - _amount;

        _burn(msg.sender,  _amount);
        usdcToken.transfer(msg.sender, _amount);
    }

    function neoBalance(address _account) public view returns (uint256) {
        return balances[_account];
    }
}