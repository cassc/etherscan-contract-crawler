/**
 *Submitted for verification at Etherscan.io on 2023-07-04
*/

// SPDX-License-Identifier: MIT

/*
~~~~~~~~~~~~!P7......................................................................JP?7~~~~~~~~~~~
~~~~~~~~~~~!P!.................................................................::....:GJ?7~~~~~~~~~~
~~~~~~~~~~~P7.........................................................................7G??!~~~~~~~~~
~~~~~~~~~~5J.............................:~!!!!~^:.....................................55??!~~~~~~~~
~~~~~~~~~7G:...........................~YB###BBBGG57^:.................................:PY??!~~~~~~~
~~~~~~~~~YJ...................::::..:7PBGYJY5YJJYY5GBPJ~:...............................^P5??7~~~~~~
~~~~~~~~~G~...................:::.:?B#PJ!~~~~~~~~~~~7BBGP?.............................:!5PJ??7!~~~~
~~~~~~~~?P....................::..~&G??7~~~~~~~~!!~~~YBPGBJ.........................:!J5Y?!!!~!!~~~~
~~~~~~~~G!.:....................:.J#JJJYYJ!~~JYJYY7!~7#GPPB~......................:?55J7!~~~~~~~~~~~
~~~~~?7YJ......................::?#PBBGP5GJ!JBGGGGGPYYP#GPB7.................^!?YPPY?7!~~~~~~~~~~~~~
~~~~~!JP7^......................:P#5PGG5?G5?G55PGG5??GGG&&&5^.............:.!P?!BP??7~~~~~~~~~~~~~~~
~~~~~~~!?JJ7^.:.................:GPY5PPPPP!~JPY5PPPP5PJ~7&@#B?.........^!?YPY7~:GJ?!~~~~~~~~~~~~~~~~
~~~~~~~~~~~?P5JJ~...............^GJJJJJJPY!!?P5YJJJ??7!~~5&BG#^.....:7JJ?!JP~!~:7G!~~~~~~~~~~~~~~~~~
~~~~~~~~~7Y5J!!YPJ7!~:..........7P7!~!~!J5?7?!77!~~~~~~~~~GBBP:..:^!G57~^:!5^!^::YY~~~~~~~~~~~~~~~!J
~~~~~~!?55?~:^7J?7!~!??!^::::::.J57!~~~~?J??7~~~~~~~~~~~~~Y&BJ?JYJJ?575?^:^!^!^::^5?~~~~~~~~~~~!?YY7
~~~~!7YG7^::^!!^:::::^~?Y55YJYYJBP?!~~~!J5#BB#GJ~~~~~~~~~~J#?7!77!~~!~~57^:^:~::::^P7~~~~~~~~!JY?^..
~~~7?JG7::::^:::::^~!7?7!~~!?Y55P#J7!~~~?BBY55Y5P7~~~~~~~!G&PP55Y?~~!~:~J~:::::::::~5?~~~~~7YJ!:....
!~7??GJ^:::::::::^~~^^:^!JY5555J!5#[email protected]!:::^^:::::::::^YJ!!JG#?.......
?7??YG!::::::::::::::^7JYJJYJ777J5G#577Y5YYYYJJ!~~~~~~~75&&?JPY?JJJ?????!^::::::::::::7P&@BYY.:.....
Y5Y?BJ^::::::::::::~?J?!~^^^:^YPJ7!JGY?J?77777!~~~~~~~J#@#?^:!5Y^^!7JJ?777^::::::::::::^5#JJG::.....
:~7GB!~^::::::::^!?7~^^^::::!B57!!!!!J5P?!~~~~~~~~~!JG#P?~::::~B?::::^!??7~^:::::::::::::!5557.:....
..~#?!!!!^::::::!!^:::::::^!55?7!!!!!!!Y55JJ????Y5PP5?~^:::::::75Y~::::::~7?7~^:::::::::::!JJ~......
..55!!!!!!!^::::::::::::::^7!!!!!!!!!!!!7?JY555YJ?!^^:::::::::::~JP?^:::::::~77~:::::::~?J7^.......:
.:GJ?7!!!!!!!^::::::::::::^!!!!!!!!!!!!!!!!!~~^^::::::::::::::::::~Y5~:::::::::~!~::^7Y?~:..........
..^!?JY7!!!!!!^:::::::::::::^~~!!!!!!!!~~^^::::::::::::::::::::::::^JP^:::::::::^!!?Y7^.............
......~YY!!!!!!^::::::::::::::::::::::::::::::::::::::::::::::::::::~P7:::::::::::7G:...............
.......:5Y!!!!!~::::::::::::::::::::::::::::::::::::::::::::::::::::^JP:::::::::::Y5.:..............
........:Y5?!~!!~::::::::::::::::::::::::::::::::::::::::::::::::::::!B~::::::::::7G:...............
..........^YY!~~!~:::::::::::::::::::::::::::::::::::::::::::::::::::^5?:::::::::::G!...............
...........:G7!^^!^::::::::::::::::::::::::::::::::::::::::::::::::::^?Y:::::::::::JY............::.
............5Y!!^:^:::::::::::::::::::::::::::::::::::::::::::::::::::~!:::::::::::!P............::.
//
// 
// NUMA NUMA
//
// Ma-i-a hi
// Ma-i-a hu
// Ma-i-a ho
// Ma-i-a ha-ha
//
// No tax, no dev, no socials.
// Get out there and NUMA NUMA as a community.
*/

pragma solidity ^0.4.23;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract NUMA is StandardToken {

  string public constant name = "NUMA NUMA"; // solium-disable-line uppercase
  string public constant symbol = "NUMA"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase

  uint256 public constant INITIAL_SUPPLY = 100000000 * (10 ** uint256(decimals));

  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

}