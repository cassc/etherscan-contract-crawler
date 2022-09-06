/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

pragma solidity ^0.4.16;

/**
 * token contract functions
*/
contract Token {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal constant returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract owned {
        address public owner;

        function owned() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
}

contract lockContract is owned{
    using SafeMath for uint256;
    
    /*
     * deposit vars
    */
    struct Items {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }
    
    uint256 public depositId;
    uint256[] public allDepositIds;
    mapping (address => uint256[]) public depositsByWithdrawalAddress;
    mapping (uint256 => Items) public lockedToken;
    mapping (address => mapping(address => uint256)) public walletTokenBalance;
    
    event LogWithdrawal(address SentToAddress, uint256 AmountTransferred);
    
    /**
     * Constrctor function
    */
    function lockContract() public {
        
    }
    
    /**
     *lock tokens
    */
    function lockTokens(address _tokenAddress, uint256 _amount, uint256 _unlockTime) public returns (uint256 _id) {
        require(_amount > 0);
        require(_unlockTime < 10000000000);
        require(Token(_tokenAddress).transferFrom(msg.sender, this, _amount));
        
        //update balance in address
        walletTokenBalance[_tokenAddress][msg.sender] = walletTokenBalance[_tokenAddress][msg.sender].add(_amount);
        
        address _withdrawalAddress = msg.sender;
        _id = ++depositId;
        lockedToken[_id].tokenAddress = _tokenAddress;
        lockedToken[_id].withdrawalAddress = _withdrawalAddress;
        lockedToken[_id].tokenAmount = _amount;
        lockedToken[_id].unlockTime = _unlockTime;
        lockedToken[_id].withdrawn = false;
        
        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
    }
    
    /**
     *transfer locked tokens
    */
    function transferLocks(uint256 _id, address _receiverAddress) public {
        require(block.timestamp < lockedToken[_id].unlockTime);
        require(msg.sender == lockedToken[_id].withdrawalAddress);
        lockedToken[_id].withdrawalAddress = _receiverAddress;
        
        //decrease sender's token balance
        walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender] = walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender].sub(lockedToken[_id].tokenAmount);
        
        //increase receiver's token balance
        walletTokenBalance[lockedToken[_id].tokenAddress][_receiverAddress] = walletTokenBalance[lockedToken[_id].tokenAddress][_receiverAddress].add(lockedToken[_id].tokenAmount);
        
    }
    
    /**
     *withdraw tokens
    */
    function withdrawTokens(uint256 _id) public {
        require(block.timestamp >= lockedToken[_id].unlockTime);
        require(msg.sender == lockedToken[_id].withdrawalAddress);
        require(!lockedToken[_id].withdrawn);
        require(Token(lockedToken[_id].tokenAddress).transfer(msg.sender, lockedToken[_id].tokenAmount));
        
        lockedToken[_id].withdrawn = true;
        
        //update balance in address
        walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender] = walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender].sub(lockedToken[_id].tokenAmount);
        
        LogWithdrawal(msg.sender, lockedToken[_id].tokenAmount);
    }

     /*get total token balance in contract*/
    function getTotalTokenBalance(address _tokenAddress) view public returns (uint256)
    {
       return Token(_tokenAddress).balanceOf(this);
    }
    
    /*get total token balance by address*/
    function getTokenBalanceByAddress(address _tokenAddress, address _walletAddress) view public returns (uint256)
    {
       return walletTokenBalance[_tokenAddress][_walletAddress];
    }
    
    /*get allDepositIds*/
    function getAllDepositIds() view public returns (uint256[])
    {
        return allDepositIds;
    }
    
    /*get getDepositDetails*/
    function getDepositDetails(uint256 _id) view public returns (address tokenAddress, address withdrawalAddress, uint256 tokenAmount, uint256 unlockTime, bool withdrawn)
    {
        return(lockedToken[_id].tokenAddress,lockedToken[_id].withdrawalAddress,lockedToken[_id].tokenAmount,
        lockedToken[_id].unlockTime,lockedToken[_id].withdrawn);
    }
    
    /*get number of active deposits of an address*/
    function numOfActiveDeposits(address _withdrawalAddress) public view returns (uint256) {
        uint256 staked = 0;
        for (uint i = 0; i < depositsByWithdrawalAddress[_withdrawalAddress].length; i++) {
            if (!lockedToken[depositsByWithdrawalAddress[_withdrawalAddress][i]].withdrawn) {
                staked++;
            }
        }
        return staked;
    }
    
    /*get getWithdrawableDepositsByAddress*/
    function getWithdrawableDepositsByAddress(address _withdrawalAddress) view public returns (uint256[])
    {
        uint256[] memory deposits = new uint256[](numOfActiveDeposits(_withdrawalAddress));
        uint256 tempIdx = 0;
        for(uint256 i = 0; i < depositsByWithdrawalAddress[_withdrawalAddress].length; i++) {
            if(!lockedToken[depositsByWithdrawalAddress[_withdrawalAddress][i]].withdrawn) {
                deposits[tempIdx] =  depositsByWithdrawalAddress[_withdrawalAddress][i];
                tempIdx ++;
            }
        }
        return deposits;
    }
    
    /*get getAllDepositsByAddress*/
    function getAllDepositsByAddress(address _withdrawalAddress) view public returns (uint256[])
    {
        return depositsByWithdrawalAddress[_withdrawalAddress];
    }
    
}