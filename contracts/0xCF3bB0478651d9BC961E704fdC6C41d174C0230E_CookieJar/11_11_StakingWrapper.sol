// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingWrapper {
    using SafeMath for uint256;
    IERC20 public token;

    uint256 private _totalStaked;
    mapping(address => uint256) private _balances;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function totalSupply() public view returns (uint256) {
        return token.totalSupply();
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalStaked = _totalStaked.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        token.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalStaked = _totalStaked.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        token.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
}