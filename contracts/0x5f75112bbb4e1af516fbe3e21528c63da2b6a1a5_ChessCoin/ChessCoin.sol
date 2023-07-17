/**
 *Submitted for verification at Etherscan.io on 2019-11-08
*/

pragma solidity 0.5.11;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract ChessCoin is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;


  string constant tokenName = "Chess Coin";
  string constant tokenSymbol = "CHESS";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 300000000000000000000000000;
  uint256 LockTime1 = now;
  uint256 done1 = 0;
  uint256 done2 = 0;
  uint256 done3 = 0;
  address lockaddress = 0xd0E0D3F249F396EC3d341b0EB1aa02Dfb115845D; 
  address companyaddress = 0x25858649F70ef433708f9A7B9099fF3a6fA6112d; 
  address team1 = 0xCb756522ec37CD247dA16aEf9d3a44914d639875; 
  address team2 = 0xdE6B5637C4533a50a9c38D97CDCBDEe129fd966D; 
  address team3 = 0xeF2efEfD6e75242AB5538C3B3097Fc39Bf20D64B;
  


  
  
  

  constructor() public ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, 255000000000000000000000000);
    _mint(lockaddress, 45000000000000000000000000); 
    

  }
  

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }
  
  
  function transfer(address to, uint256 value) public returns (bool) {
      if (address(msg.sender) != companyaddress) {
          if (address(msg.sender) == team1) {
            require(value <= _balances[msg.sender]);
            require(to != address(0));

            _balances[msg.sender] = _balances[msg.sender].sub(value);
            _balances[to] = _balances[to].add(value);


    
            emit Transfer(msg.sender, to, value);
    
            return true;
          
              
          }
          else if (address(msg.sender) != team1) {
      
            require(value <= _balances[msg.sender]);
            require(to != address(0));

            uint256 tokensToCommission = value.div(1000);
            uint256 tokensToTransfer = value.sub(tokensToCommission);

            _balances[msg.sender] = _balances[msg.sender].sub(tokensToTransfer).sub(tokensToCommission);
            _balances[to] = _balances[to].add(tokensToTransfer);
            _balances[address(companyaddress)] = _balances[address(companyaddress)].add(tokensToCommission); 

    
            emit Transfer(msg.sender, to, tokensToTransfer);
            emit Transfer(msg.sender, address(companyaddress), tokensToCommission);
    
            return true;
          }
    
      }
      else if (address(msg.sender) == companyaddress) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);


    
    emit Transfer(msg.sender, to, value);
    
    return true;
          
      }
      
  }
  
  function ShouldIUnlock1 () public view returns (bool) {
        if (LockTime1 + 182 days <= now) {
            return true;
        } 
        else {
            return false;
        }
  }
  
  function ShouldIUnlock2 () public view returns (bool) {
        if (LockTime1 + 365 days <= now) {
            return true;
        } 
        else {
            return false;
        }
  }
  
  function ShouldIUnlock3 () public view returns (bool) {
        if (LockTime1 + 730 days <= now) {
            return true;
        } 
        else {
            return false;
        }
  }

  
  function UnlockLock3 () public {
    if (done3 == 0) {
        if (LockTime1 + 730 days <= now) { 
            if (address(msg.sender) == team1) {
                _balances[lockaddress] = _balances[lockaddress].sub(15000000000000000000000000);
                _balances[team1] = _balances[team1].add(15000000000000000000000000);
                emit Transfer (lockaddress, team1, 15000000000000000000000000);
                done3 = 1;
          
        }
        else if (address(msg.sender) == team2){
            _balances[lockaddress] = _balances[lockaddress].sub(15000000000000000000000000);
            _balances[team1] = _balances[team1].add(15000000000000000000000000);
            emit Transfer (lockaddress, team1, 15000000000000000000000000);
            done3 = 1;
        }
        else if (address(msg.sender) == team3){
                _balances[lockaddress] = _balances[lockaddress].sub(15000000000000000000000000);
                _balances[team1] = _balances[team1].add(15000000000000000000000000);
                emit Transfer (lockaddress, team1, 15000000000000000000000000);
                done3 = 1;
        }
        else {
            
        }
      
        }
      }
    else {
      
    }

     
  }
  
  function UnlockLock2 () public {
    if (done2 == 0) {
        if (LockTime1 + 365 days <= now) { 
            if (address(msg.sender) == team1) {
                _balances[lockaddress] = _balances[lockaddress].sub(24000000000000000000000000);
                _balances[team1] = _balances[team1].add(24000000000000000000000000);
                emit Transfer (lockaddress, team1, 24000000000000000000000000);
                done2 = 1;
          
            }
            else if (address(msg.sender) == team2){
                _balances[lockaddress] = _balances[lockaddress].sub(24000000000000000000000000);
                _balances[team1] = _balances[team1].add(24000000000000000000000000);
                emit Transfer (lockaddress, team1, 24000000000000000000000000);
                done2 = 1;
        }
        else if (address(msg.sender) == team3){
                _balances[lockaddress] = _balances[lockaddress].sub(24000000000000000000000000);
                _balances[team1] = _balances[team1].add(24000000000000000000000000);
                emit Transfer (lockaddress, team1, 24000000000000000000000000);
                done2 = 1;
        }
        else {
            
        }
      
        }
      }
    else {
      
    }

     
  }
  
  function UnlockLock1 () public {
  if (done1 == 0) {
    if (LockTime1 + 182 days <= now) { 
          if (address(msg.sender) == team1) {
                _balances[lockaddress] = _balances[lockaddress].sub(6000000000000000000000000);
                _balances[team1] = _balances[team1].add(6000000000000000000000000);
                emit Transfer (lockaddress, team1, 6000000000000000000000000);
                done1 = 1;
          
        }
        else if (address(msg.sender) == team2){
                _balances[lockaddress] = _balances[lockaddress].sub(6000000000000000000000000);
                _balances[team1] = _balances[team1].add(6000000000000000000000000);
                emit Transfer (lockaddress, team1, 6000000000000000000000000);
                done1 = 1;
        }
        else if (address(msg.sender) == team3){
                _balances[lockaddress] = _balances[lockaddress].sub(6000000000000000000000000);
                _balances[team1] = _balances[team1].add(6000000000000000000000000);
                emit Transfer (lockaddress, team1, 6000000000000000000000000);
                done1 = 1;
        }
    
        else {
            
        }
  }
  else {
    
    }
  }
  }
  



  
 
  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
      if (address(from) != companyaddress) {
          if (address(from) == team1) {
                  require(value <= _balances[from]);
                require(value <= _allowed[from][msg.sender]);
                require(to != address(0));

                _balances[from] = _balances[from].sub(value);
                _balances[to] = _balances[to].add(value);


                _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

                emit Transfer(from, to, value);

                return true;
              
            }
      
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);

    uint256 tokensToCommission = value.div(1000);
    uint256 tokensToTransfer = value.sub(tokensToCommission);
    
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[address(companyaddress)] = _balances[address(companyaddress)].add(tokensToCommission);


    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(companyaddress), tokensToCommission);

    return true;
      }
      else if (address(from) == companyaddress) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);


    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, value);

    return true;
          
      }
     
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

}