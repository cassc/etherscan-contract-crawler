/**
 *Submitted for verification at Etherscan.io on 2019-11-08
*/

pragma solidity >=0.4.22 <0.6.0;

library SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a / b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a && c >= b);
    return c;
  }
}

contract ERC20Interface {
  uint256 public destorySupply; //销毁数量
  uint256 public totalSupply; //总发行量不变
  function balanceOf(address _addr) public view returns (uint256); //查询地址对应的token
  function transfer(address _to, uint256 _value) public returns (bool); //主动转账
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool); //被动转账
  function approval(address _delegatee, uint256 _value) public returns (bool); //授权
  function allowance(address _owner, address _spender) public view returns (uint256); //查询授权使用的token
  function destory(uint256 _value) public returns (bool); //Token销毁
  function destoryFrom(address _from, uint256 _value) public returns (bool); //授权Token销毁

  event Transfer(address indexed _from, address indexed _to, uint256 _value); //转账事件
  event Approval(address indexed _owner, address indexed _spender, uint256 _value); //授权事件
  event Destory(address indexed _owner, uint256 _value); //销毁事件

}

contract CIToken is ERC20Interface {
  address public owner; 

  mapping (address => uint256) public balances; 
  mapping (address => mapping (address => uint256)) public approvalBalance;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }


  function changeOwner(address _newOwner) external onlyOwner {
    require(_newOwner != address(0x0),"address cannot be empty.");
    require(_newOwner != owner,"address unchanged.");
    owner = _newOwner;
  }


  //转账交易
  function _transfer(address _from, address _to, uint256 _value) internal {
    require(balances[_from] >= _value,"insufficient number of tokens."); 
    require(_to != address(0x0),"address cannot be empty.");  
    require(balances[_to] + _value > balances[_to],"_value too large"); 

    uint256 previousBalance = SafeMath.safeAdd(balances[_from], balances[_to]); //校验
    balances[_from] = SafeMath.safeSub(balances[_from], _value);
    balances[_to] = SafeMath.safeAdd(balances[_to], _value);
    emit Transfer(_from, _to, _value);

    // 判断总额是否一致, 避免过程出错
    assert (SafeMath.safeAdd(balances[_from], balances[_to]) == previousBalance);
  }

  //主动转账
  function transfer(address _to, uint256 _value) public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  //被动转账
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(approvalBalance[_from][msg.sender] >= _value,"insufficient number of authorized tokens."); 
    approvalBalance[_from][msg.sender] = SafeMath.safeSub(approvalBalance[_from][msg.sender], _value);
    _transfer(_from, _to, _value);
    return true;
  }

  //授权
  function approval(address _delegatee, uint256 _value) public returns (bool) {
    require(balances[msg.sender] >= _value,"insufficient number of tokens.");
    require(_delegatee != address(0x0),"address cannot be empty.");
    approvalBalance[msg.sender][_delegatee] = _value;
    emit Approval(msg.sender, _delegatee, _value);
    return true;
  }

  //Token销毁
  function destory(uint256 _value) public returns (bool) {
    require(balances[msg.sender] >= _value,"insufficient number of tokens.");
    balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);
    totalSupply = SafeMath.safeSub(totalSupply, _value);
    destorySupply = SafeMath.safeAdd(destorySupply, _value);
    emit Destory(msg.sender, _value);
    return true;
  }

  //授权Token销毁
  function destoryFrom(address _from, uint256 _value) public returns (bool) {
    require(approvalBalance[_from][msg.sender] >= _value,"insufficient number of authorized tokens.");
    require(balances[_from] >= _value,"insufficient number of tokens.");
    balances[_from] = SafeMath.safeSub(balances[_from], _value);
    approvalBalance[_from][msg.sender] = SafeMath.safeSub(approvalBalance[_from][msg.sender], _value);
    totalSupply = SafeMath.safeSub(totalSupply, _value);
    destorySupply = SafeMath.safeAdd(destorySupply, _value);
    emit Destory(msg.sender, _value);
    return true;
  }

  //查询地址对应的token
  function balanceOf(address _addr) public view returns (uint256) {
    return balances[_addr];
  }

  //查询授权使用的token
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return approvalBalance[_owner][_spender];
  }
}

contract CI is CIToken {
  //REVERT 碰到无效代码后，仍将回滚所有状态
  function () external { revert(); }

  string public constant name = "CI"; 
  string public constant symbol = "CI";
  uint8 public constant decimals = 18;

  constructor() public {
    owner = msg.sender;
    destorySupply = 0;
    totalSupply = formatDecimals(100000000);
    balances[owner] = totalSupply;
  }

  //格式化(_value * 10 ** uint256(decimals))
  function formatDecimals(uint256 _value) internal pure returns (uint256){
    return _value * 10 ** uint256(decimals);
  }
}