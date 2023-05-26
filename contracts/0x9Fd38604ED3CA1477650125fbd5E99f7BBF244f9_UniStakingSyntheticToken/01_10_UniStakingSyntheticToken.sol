// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "./UniStaking.sol";

contract UniStakingSyntheticToken is UniStaking {
    uint256 public decimals;
    string public name;
    string public symbol;
    mapping(address => mapping(address => uint256)) internal _allowances;

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 decimals_,
        IERC20 rewardsToken_,
        IERC20 stakingToken_,
        address owner_
    ) public UniStaking(rewardsToken_, stakingToken_, owner_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    function _onMint(address account, uint256 amount) internal override {
        emit Transfer(address(0), account, amount);
    }

    function _onBurn(address account, uint256 amount) internal override {
        emit Transfer(account, address(0), amount);
    }

    function transfer(address recipient, uint256 amount) external onlyPositiveAmount(amount) returns (bool) {
        require(balanceOf(msg.sender) >= amount, "Transfer amount exceeds balance");
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external onlyPositiveAmount(amount) returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "Transfer amount exceeds allowance");
        require(balanceOf(sender) >= amount, "Transfer amount exceeds balance");
        _transfer(sender, recipient, amount);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _moveStake(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
    }
}