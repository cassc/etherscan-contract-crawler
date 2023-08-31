// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './SafeMath.sol';
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

contract BallIsLife is IERC20Metadata {
    using SafeMath for uint256;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    string public constant name = "Ball Is Life";
    string public constant symbol = "BIL";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply = 1000000000000 * (10 ** 18); // 1 trillion supply

    // Added owner variable to replicate point #5 in RFD
    address public owner;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        // Assigning the contract deployer as the owner
        owner = msg.sender;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address player) public view override returns (uint256) {
        return balances[player];
    }

    function allowance(address player, address spender) public view override returns (uint256) {
        return allowed[player][spender];
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require(value <= balances[msg.sender]);
        require(to != address(0));

        balances[msg.sender] = SafeMath.sub(balances[msg.sender], value);
        balances[to] = SafeMath.add(balances[to], value);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // Changed visibility of approveAndCall to external as per good practices
    function approveAndCall(address spender, uint256 tokens, bytes calldata data) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        require(to != address(0));

        balances[from] = SafeMath.sub(balances[from], value);
        balances[to] = SafeMath.add(balances[to], value);
        
        allowed[from][msg.sender] = SafeMath.sub(allowed[from][msg.sender], value);
        
        emit Transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = SafeMath.add(allowed[msg.sender][spender], addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = SafeMath.sub(allowed[msg.sender][spender], subtractedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    // Changed visibility of burn to external as per good practices
    function burn(uint256 amount) external {
        require(amount != 0);
        require(amount <= balances[msg.sender]);
        _totalSupply = SafeMath.sub(_totalSupply, amount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], amount);
        emit Transfer(msg.sender, address(0), amount);
    }
}