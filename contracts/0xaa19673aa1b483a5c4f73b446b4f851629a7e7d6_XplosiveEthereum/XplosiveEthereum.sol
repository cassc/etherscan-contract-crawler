/**
 *Submitted for verification at Etherscan.io on 2020-09-08
*/

/**
 *
 * ██╗  ██╗███████╗████████╗██╗  ██╗
 * ╚██╗██╔╝██╔════╝╚══██╔══╝██║  ██║
 *  ╚███╔╝ █████╗     ██║   ███████║
 *  ██╔██╗ ██╔══╝     ██║   ██╔══██║
 * ██╔╝ ██╗███████╗   ██║   ██║  ██║
 * ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝
 * 
 *    An Ethereum pegged 
 * base-down, burn-up currency. 
 *                    
 *  https://xEth.finance
 *                              
 * 
**/


pragma solidity ^0.6.6;


contract Ownable {
    address public owner;

    event TransferOwnership(address _from, address _to);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }
}

contract XplosiveEthereum is Ownable {
    
    using SafeMath for uint256;
    
    event Rebase(uint256 indexed epoch, uint256 scalingFactor);
    event NewRebaser(address oldRebaser, address newRebaser);
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    string public name     = "Xplosive Ethereum";
    string public symbol   = "xETH";
    uint8  public decimals = 18;
    
    address public rebaser;
    
    address public rewardAddress;

    /**
     * @notice Internal decimals used to handle scaling factor
     */
    uint256 public constant internalDecimals = 10**24;

    /**
     * @notice Used for percentage maths
     */
    uint256 public constant BASE = 10**18;

    /**
     * @notice Scaling factor that adjusts everyone's balances
     */
    uint256 public xETHScalingFactor  = BASE;

    mapping (address => uint256) internal _xETHBalances;
    mapping (address => mapping (address => uint256)) internal _allowedFragments;
    
    
    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;
    mapping(address => bool) public whitelistRebase;
    
    
    address public noRebaseAddress;
    
    uint256 initSupply = 0;
    uint256 _totalSupply = 0;
    uint16 public SELL_FEE = 33;
    uint16 public TX_FEE = 50;
    
    event WhitelistFrom(address _addr, bool _whitelisted);
    event WhitelistTo(address _addr, bool _whitelisted);
    event WhitelistRebase(address _addr, bool _whitelisted);
    
     constructor(
        uint256 initialSupply,
        address initialSupplyAddr
        
        ) public {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
        _mint(initialSupplyAddr,initialSupply);
        
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function getSellBurn(uint256 value) public view returns (uint256)  {
        uint256 nPercent = value.divRound(SELL_FEE);
        return nPercent;
    }
    function getTxBurn(uint256 value) public view returns (uint256)  {
        uint256 nPercent = value.divRound(TX_FEE);
        return nPercent;
    }
    
    function _isWhitelisted(address _from, address _to) internal view returns (bool) {
        return whitelistFrom[_from]||whitelistTo[_to];
    }
    function _isRebaseWhitelisted(address _addr) internal view returns (bool) {
        return whitelistRebase[_addr];
    }

    function setWhitelistedTo(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistTo(_addr, _whitelisted);
        whitelistTo[_addr] = _whitelisted;
    }
    
    function setTxFee(uint16 fee) external onlyRebaser {
        TX_FEE = fee;
    }
    
    function setSellFee(uint16 fee) external onlyRebaser {
        SELL_FEE = fee;
    }
    
    function setWhitelistedFrom(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistFrom(_addr, _whitelisted);
        whitelistFrom[_addr] = _whitelisted;
    }
      
    function setWhitelistedRebase(address _addr, bool _whitelisted) external onlyOwner {
        emit WhitelistRebase(_addr, _whitelisted);
        whitelistRebase[_addr] = _whitelisted;
    }
    
    function setNoRebaseAddress(address _addr) external onlyOwner {
        noRebaseAddress = _addr;
    }
    
    
   

    modifier onlyRebaser() {
        require(msg.sender == rebaser);
        _;
    }



    
    /**
    * @notice Computes the current max scaling factor
    */
    function maxScalingFactor()
        external
        view
        returns (uint256)
    {
        return _maxScalingFactor();
    }

    function _maxScalingFactor()
        internal
        view
        returns (uint256)
    {
        // scaling factor can only go up to 2**256-1 = initSupply * xETHScalingFactor
        // this is used to check if xETHScalingFactor will be too high to compute balances when rebasing.
        return uint256(-1) / initSupply;
    }

   
    function _mint(address to, uint256 amount)
        internal
    {
      // increase totalSupply
      _totalSupply = _totalSupply.add(amount);

      // get underlying value
      uint256 xETHValue = amount.mul(internalDecimals).div(xETHScalingFactor);

      // increase initSupply
      initSupply = initSupply.add(xETHValue);

      // make sure the mint didnt push maxScalingFactor too low
      require(xETHScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

      // add balance
      _xETHBalances[to] = _xETHBalances[to].add(xETHValue);
      
      emit Transfer(address(0),to,amount);

     
    }
    
   

    /* - ERC20 functionality - */

    /**
    * @dev Transfer tokens to a specified address.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @return True on success, false otherwise.
    */
    function transfer(address to, uint256 value)
        external
        returns (bool)
    {
        // underlying balance is stored in xETH, so divide by current scaling factor

        // note, this means as scaling factor grows, dust will be untransferrable.
        // minimum transfer value == xETHScalingFactor / 1e24;
        
        // get amount in underlying
        //from noRebaseWallet
        if(_isRebaseWhitelisted(msg.sender)){
            uint256 noReValue = value.mul(internalDecimals).div(BASE);
            uint256 noReNextValue = noReValue.mul(BASE).div(xETHScalingFactor);
            _xETHBalances[msg.sender] = _xETHBalances[msg.sender].sub(noReValue); //value==underlying
            _xETHBalances[to] = _xETHBalances[to].add(noReNextValue);
            emit Transfer(msg.sender, to, value);
        }
        else if(_isRebaseWhitelisted(to)){
            uint256 fee = getSellBurn(value);
            uint256 tokensToBurn = fee/2;
            uint256 tokensForRewards = fee-tokensToBurn;
            uint256 tokensToTransfer = value-fee;
                
            uint256 xETHValue = value.mul(internalDecimals).div(xETHScalingFactor);
            uint256 xETHValueKeep = tokensToTransfer.mul(internalDecimals).div(xETHScalingFactor);
            uint256 xETHValueReward = tokensForRewards.mul(internalDecimals).div(xETHScalingFactor);
            
            
            uint256 xETHNextValue = xETHValueKeep.mul(xETHScalingFactor).div(BASE);
            
            _totalSupply = _totalSupply-fee;
            _xETHBalances[address(0)] = _xETHBalances[address(0)].add(fee/2);
            _xETHBalances[msg.sender] = _xETHBalances[msg.sender].sub(xETHValue); 
            _xETHBalances[to] = _xETHBalances[to].add(xETHNextValue);
            _xETHBalances[rewardAddress] = _xETHBalances[rewardAddress].add(xETHValueReward);
            emit Transfer(msg.sender, to, tokensToTransfer);
            emit Transfer(msg.sender, address(0), tokensToBurn);
            emit Transfer(msg.sender, rewardAddress, tokensForRewards);
        }
        else{
          if(!_isWhitelisted(msg.sender, to)){
                uint256 fee = getTxBurn(value);
                uint256 tokensToBurn = fee/2;
                uint256 tokensForRewards = fee-tokensToBurn;
                uint256 tokensToTransfer = value-fee;
                    
                uint256 xETHValue = value.mul(internalDecimals).div(xETHScalingFactor);
                uint256 xETHValueKeep = tokensToTransfer.mul(internalDecimals).div(xETHScalingFactor);
                uint256 xETHValueReward = tokensForRewards.mul(internalDecimals).div(xETHScalingFactor);
                
                _totalSupply = _totalSupply-fee;
                _xETHBalances[address(0)] = _xETHBalances[address(0)].add(fee/2);
                _xETHBalances[msg.sender] = _xETHBalances[msg.sender].sub(xETHValue); 
                _xETHBalances[to] = _xETHBalances[to].add(xETHValueKeep);
                _xETHBalances[rewardAddress] = _xETHBalances[rewardAddress].add(xETHValueReward);
                emit Transfer(msg.sender, to, tokensToTransfer);
                emit Transfer(msg.sender, address(0), tokensToBurn);
                emit Transfer(msg.sender, rewardAddress, tokensForRewards);
           }
             else{
                uint256 xETHValue = value.mul(internalDecimals).div(xETHScalingFactor);
               
                _xETHBalances[msg.sender] = _xETHBalances[msg.sender].sub(xETHValue); 
                _xETHBalances[to] = _xETHBalances[to].add(xETHValue);
                emit Transfer(msg.sender, to, xETHValue);
             }
        }
        return true;
    }



    /**
    * @dev Transfer tokens from one address to another.
    * @param from The address you want to send tokens from.
    * @param to The address you want to transfer to.
    * @param value The amount of tokens to be transferred.
    */
    function transferFrom(address from, address to, uint256 value)
        external
        returns (bool)
    {
        // decrease allowance
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        if(_isRebaseWhitelisted(from)){
            uint256 noReValue = value.mul(internalDecimals).div(BASE);
            uint256 noReNextValue = noReValue.mul(BASE).div(xETHScalingFactor);
            _xETHBalances[from] = _xETHBalances[from].sub(noReValue); //value==underlying
            _xETHBalances[to] = _xETHBalances[to].add(noReNextValue);
            emit Transfer(from, to, value);
        }
        else if(_isRebaseWhitelisted(to)){
            uint256 fee = getSellBurn(value);
            uint256 tokensForRewards = fee-(fee/2);
            uint256 tokensToTransfer = value-fee;
            
            uint256 xETHValue = value.mul(internalDecimals).div(xETHScalingFactor);
            uint256 xETHValueKeep = tokensToTransfer.mul(internalDecimals).div(xETHScalingFactor);
            uint256 xETHValueReward = tokensForRewards.mul(internalDecimals).div(xETHScalingFactor);
            uint256 xETHNextValue = xETHValueKeep.mul(xETHScalingFactor).div(BASE);
            
            _totalSupply = _totalSupply-fee;
            
            _xETHBalances[from] = _xETHBalances[from].sub(xETHValue); 
            _xETHBalances[to] = _xETHBalances[to].add(xETHNextValue);
            _xETHBalances[rewardAddress] = _xETHBalances[rewardAddress].add(xETHValueReward);
            _xETHBalances[address(0)] = _xETHBalances[address(0)].add(fee/2);
            emit Transfer(from, to, tokensToTransfer);
            emit Transfer(from, address(0), fee/2);
            emit Transfer(from, rewardAddress, tokensForRewards);
        }
        else{
          if(!_isWhitelisted(from, to)){
                uint256 fee = getTxBurn(value);
                uint256 tokensToBurn = fee/2;
                uint256 tokensForRewards = fee-tokensToBurn;
                uint256 tokensToTransfer = value-fee;
                    
                uint256 xETHValue = value.mul(internalDecimals).div(xETHScalingFactor);
                uint256 xETHValueKeep = tokensToTransfer.mul(internalDecimals).div(xETHScalingFactor);
                uint256 xETHValueReward = tokensForRewards.mul(internalDecimals).div(xETHScalingFactor);
            
                _totalSupply = _totalSupply-fee;
                _xETHBalances[address(0)] = _xETHBalances[address(0)].add(fee/2);
                _xETHBalances[from] = _xETHBalances[from].sub(xETHValue); 
                _xETHBalances[to] = _xETHBalances[to].add(xETHValueKeep);
                _xETHBalances[rewardAddress] = _xETHBalances[rewardAddress].add(xETHValueReward);
                emit Transfer(from, to, tokensToTransfer);
                emit Transfer(from, address(0), tokensToBurn);
                emit Transfer(from, rewardAddress, tokensForRewards);
           }
             else{
                uint256 xETHValue = value.mul(internalDecimals).div(xETHScalingFactor);
               
                _xETHBalances[from] = _xETHBalances[from].sub(xETHValue); 
                _xETHBalances[to] = _xETHBalances[to].add(xETHValue);
                emit Transfer(from, to, xETHValue);
                
            
             }
        }
        return true;
    }

    /**
    * @param who The address to query.
    * @return The balance of the specified address.
    */
    function balanceOf(address who)
      external
      view
      returns (uint256)
    {
      if(_isRebaseWhitelisted(who)){
        return _xETHBalances[who].mul(BASE).div(internalDecimals);
      }
      else{
        return _xETHBalances[who].mul(xETHScalingFactor).div(internalDecimals);
      }
    }

    /** @notice Currently returns the internal storage amount
    * @param who The address to query.
    * @return The underlying balance of the specified address.
    */
    function balanceOfUnderlying(address who)
      external
      view
      returns (uint256)
    {
      return _xETHBalances[who];
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        external
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /* - Governance Functions - */

    /** @notice sets the rebaser
     * @param rebaser_ The address of the rebaser contract to use for authentication.
     */
    function _setRebaser(address rebaser_)
        external
        onlyOwner
    {
        address oldRebaser = rebaser;
        rebaser = rebaser_;
        emit NewRebaser(oldRebaser, rebaser_);
    }
    
     function _setRewardAddress(address rewards_)
        external
        onlyOwner
    {
        rewardAddress = rewards_;
      
    }
    
    /**
    * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
    *
    * @dev The supply adjustment equals (totalSupply * DeviationFromTargetRate) / rebaseLag
    *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
    *      and targetRate is CpiOracleRate / baseCpi
    */
    function rebase(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    )
        external
        onlyRebaser
        returns (uint256)
    {
        if (indexDelta == 0 || !positive) {
          emit Rebase(epoch, xETHScalingFactor);
          return _totalSupply;
        }

            uint256 newScalingFactor = xETHScalingFactor.mul(BASE.add(indexDelta)).div(BASE);
            if (newScalingFactor < _maxScalingFactor()) {
                xETHScalingFactor = newScalingFactor;
            } else {
              xETHScalingFactor = _maxScalingFactor();
            }
        

        _totalSupply = ((initSupply.sub(_xETHBalances[address(0)]).sub(_xETHBalances[noRebaseAddress]))
                        .mul(xETHScalingFactor).div(internalDecimals))
                        .add(_xETHBalances[noRebaseAddress].mul(BASE).div(internalDecimals));
        emit Rebase(epoch, xETHScalingFactor);
        return _totalSupply;
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
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

 
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
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

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
  
  function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        uint256 r = x / y;
        if (x % y != 0) {
            r = r + 1;
        }

        return r;
    }
}