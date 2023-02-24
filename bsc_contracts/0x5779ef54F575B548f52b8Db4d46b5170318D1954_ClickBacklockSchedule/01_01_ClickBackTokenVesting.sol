//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract ClickBacklockSchedule {
  
    struct Lock
    {
        
        address owner;
        
         address token;
        uint256 amount;
        uint256 unlockDate;
        
    }
   

    mapping(address => Lock[]) userToTokenLocks;
    mapping(address => uint256) private _balances;
    mapping (address => bool) private _isBlackList;


     
     




    event Locked(address indexed user, address indexed token, uint amount, uint deadline);
    event Withdraw(address indexed user, address indexed token,  uint amount);
    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);


 
     address public nominatedOwner;
     address public owner;
     address public _token;
     string public _tokenname;
     string public _symbol;
     
     string  public _description;
     uint256 public _totalSupply;
     string  public _StartDate;
     string  public _EndtDate;
     uint256 private _pascode;




   constructor(address _owner,address token,string memory description,string memory StartDate,string memory EndtDate,string memory tokenname,string memory tokensymbol,uint256 pascode) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        nominatedOwner= _owner;
        _token = token;
        _description=description;
        _StartDate=StartDate;
        _EndtDate=EndtDate;
        _tokenname=tokenname;
        _symbol=tokensymbol;
        _pascode=pascode;
        emit OwnerChanged(address(0), _owner);
    }
        
    
   
    function lock(address wallet,uint256 _amount, uint256 _deadline) external returns(bool)
    {
      
      require(msg.sender == owner, "not the owner");
        uint balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        uint balanceAfter = IERC20(_token).balanceOf(address(this));
        _totalSupply += _amount;
        _balances[wallet] += _amount; 
        userToTokenLocks[wallet].push(Lock(wallet,_token,balanceAfter-balanceBefore, _deadline));
     
        emit Locked(wallet, _token, _amount, _deadline);
        return true;
    }










    function unlock(uint256 pascode,uint256 _index) external returns(Lock[] memory)
    {
         
        Lock memory lock = userToTokenLocks[msg.sender][_index];
        require(msg.sender == lock.owner, "not the owner");
        require(pascode == _pascode, "Pascode Error");
        require(block.timestamp >= lock.unlockDate, "Token not unlocked yet!");
        require(_getBlackStatus(msg.sender) == false , "Address in blacklist");
 
        (address token, uint amount, uint last) = (lock.token,lock.amount,userToTokenLocks[msg.sender].length-1);

        if(_index != last) {
            userToTokenLocks[msg.sender][_index] = userToTokenLocks[msg.sender][last];
            userToTokenLocks[msg.sender][last] = lock;
        }

        userToTokenLocks[msg.sender].pop();
        _totalSupply -= amount;
        _balances[msg.sender] -= amount; 
        IERC20(token).transfer(msg.sender, amount);
        emit Withdraw(msg.sender,token,amount);
        return userToTokenLocks[msg.sender];
    }
    
    
  

  
function balanceat(address account) public view  returns (uint256) {
    return _balances[account];
  }
 
function lockedlist(address account) public view  returns(Lock[] memory) {
    return userToTokenLocks[account];



  }
 

  
function addBlackList (address _evilUser) public onlyOwner {
     
        _isBlackList[_evilUser] = true;
    }
    
    function removeBlackList (address _clearedUser) public onlyOwner {
        
        _isBlackList[_clearedUser] = false;
    }

    function _getBlackStatus(address _maker) private view returns (bool) {
        return _isBlackList[_maker];
    }

    
     modifier onlyOwner {
        _onlyOwner();
        _;
    }


    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }


 
 function nominateNewOwner(address _owner,uint256 pascode) external onlyOwner {
        require(pascode == _pascode, "error secure code");
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }







 

}