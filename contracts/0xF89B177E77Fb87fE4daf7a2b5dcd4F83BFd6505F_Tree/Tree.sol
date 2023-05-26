/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

pragma solidity 0.5.8;

/*
 *
 * We build the roots before we grow, Just like the Merkle Tree, My favourite *
 *
 * Tree (3) is Uniswap V3 Token *
 * Tree (3) has an unique liquidity injection system *
 * Tree (3) has 0% tax * 
 * Tree (3) done a small presale to bootstrap the liquidity injection system *
 * Tree (3) liquifystation Tree 🌳 increases by the 3 🌳 hours into the LP pool *
 * 
 * Launching Trading in 3 Hours from Deployment *
 * Launching Twitter in 3 Hours from Trading Launch *
 * Launching Telegram in 3 Hours from Twitter Launch *
 * Launching Website in 3 Hours from Telegram Launch *
 * Launching Roadmap in 3 Hours from Website Launch *
 * Launching Whitepaper 3 Hours from Roadmap Launch *
 * Launching dApp 3 Hours from Whitepaper Launch *
 * Launching liquifystation 3 Hours from dApp Launch *

 * A day has past *

 * Yesterday is history, tomorrow is a mystery, today is a gift of God *

 * We communicate by the chain *

 */


interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Tree is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    string public constant name  = "Tree";
    string public constant symbol = "3";
    uint8 public constant decimals = 3;
    uint256 constant MAX_SUPPLY = 3333333333333;

    constructor() public {
        balances[msg.sender] = MAX_SUPPLY;
        emit Transfer(address(0), msg.sender, MAX_SUPPLY);
    }

    function totalSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    function balanceOf(address player) public view returns (uint256) {
        return balances[player];
    }

    function allowance(address player, address spender) public view returns (uint256) {
        return allowed[player][spender];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0));
        transferInternal(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(to != address(0));
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        transferInternal(from, to, amount);
        return true;
    }

    function transferInternal(address from, address to, uint256 amount) internal {
        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }


}


library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}