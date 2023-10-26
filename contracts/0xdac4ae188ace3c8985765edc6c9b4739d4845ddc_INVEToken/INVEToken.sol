/**
 *Submitted for verification at Etherscan.io on 2018-07-31
*/

pragma solidity ^0.4.24;
/*

  Copyright 2018 InterValue Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b); //The first number should not be zero
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
  
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;
    
  /// This is where we hold INVE token and the only address from which
  /// `issue token` can be invocated.
  ///
  /// Note: this will be initialized during the contract deployment.
  address public owner;
  
  /// This is a switch to control the liquidity of INVE
  bool public transferable = true;
  
  mapping(address => uint) balances;

  //The frozen accounts 
  mapping (address => bool) public frozenAccount;
  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }
  
  modifier unFrozenAccount{
      require(!frozenAccount[msg.sender]);
      _;
  }
  
  modifier onlyOwner {
      if (owner == msg.sender) {
          _;
      } else {
          InvalidCaller(msg.sender);
          throw;
        }
  }
  
  modifier onlyTransferable {
      if (transferable) {
          _;
      } else {
          LiquidityAlarm("The liquidity of INVE is switched off");
          throw;
      }
  }
  /**
  *EVENTS
  */
  /// Emitted when the target account is frozen
  event FrozenFunds(address target, bool frozen);
  
  /// Emitted when a function is invocated by unauthorized addresses.
  event InvalidCaller(address caller);

  /// Emitted when some INVE coins are burn.
  event Burn(address caller, uint value);
  
  /// Emitted when the ownership is transferred.
  event OwnershipTransferred(address indexed from, address indexed to);
  
  /// Emitted if the account is invalid for transaction.
  event InvalidAccount(address indexed addr, bytes msg);
  
  /// Emitted when the liquity of INVE is switched off
  event LiquidityAlarm(bytes msg);
  
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) unFrozenAccount onlyTransferable {
    if (frozenAccount[_to]) {
        InvalidAccount(_to, "The receiver account is frozen");
    } else {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }
    
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) view returns (uint balance) {
    return balances[_owner];
  }

  ///@notice `freeze? Prevent | Allow` `target` from sending & receiving INVE preconditions
  ///@param target Address to be frozen
  ///@param freeze To freeze the target account or not
  function freezeAccount(address target, bool freeze) onlyOwner public {
      frozenAccount[target]=freeze;
      FrozenFunds(target, freeze);
    }
  
  function accountFrozenStatus(address target) view returns (bool frozen) {
      return frozenAccount[target];
  }
  
  function transferOwnership(address newOwner) onlyOwner public {
      if (newOwner != address(0)) {
          address oldOwner=owner;
          owner = newOwner;
          OwnershipTransferred(oldOwner, owner);
        }
  }
  
  function switchLiquidity (bool _transferable) onlyOwner returns (bool success) {
      transferable=_transferable;
      return true;
  }
  
  function liquidityStatus () view returns (bool _transferable) {
      return transferable;
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken {

  mapping (address => mapping (address => uint)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) unFrozenAccount onlyTransferable{
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;
    
    // Check account _from and _to is not frozen
    require(!frozenAccount[_from]&&!frozenAccount[_to]);
    
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) unFrozenAccount {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) view returns (uint remaining) {
    return allowed[_owner][_spender];
  }
  
}

/// @title InterValue Protocol Token.
/// For more information about this token, please visit http://inve.one
contract INVEToken is StandardToken {
    string public name = "InterValue";
    string public symbol = "INVE";
    uint public decimals = 18;

    /**
     * CONSTRUCTOR 
     * 
     * @dev Initialize the INVE Coin
     * @param _owner The escrow account address, all ethers will
     * be sent to this address.
     * This address will be : 0x...
     */
    function INVEToken(address _owner) {
        owner = _owner;
        totalSupply = 40 * 10 ** 26;
        balances[owner] = totalSupply;
    }

    /*
     * PUBLIC FUNCTIONS
     */

    /// @dev This default function allows token to be purchased by directly
    /// sending ether to this smart contract.
    function () public payable {
        revert();
    }
}