/**
 *Submitted for verification at Etherscan.io on 2019-11-05
*/

// File: contracts/Xmalltoken.sol

pragma solidity 0.5.10;


interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _who) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    event Transfer( address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value);
}


interface ContractReceiver { 
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
} 


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
}


contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


contract Xmalltoken is ERC20, Ownable {
    using SafeMath for uint256;

    string public constant name = "cryptomall token";
    string public constant symbol = "XMALL";
    uint8 public constant decimals = 18;
    uint private constant DECIMALS = 1000000000000000000;
    uint256 public totalSupply = 500000000 * DECIMALS;

    address payable public founder; 

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public unlockUnixTime;

    event FrozenFunds(address indexed target, bool frozen);
    event LockedUp(address indexed target, uint256 locked);
    event Burn(address indexed from, uint256 amount);

    /**
     * @dev Constructor is called only once and can not be called again
     */
    constructor(address payable _address) public {
        founder  = _address;
        balanceOf[founder] = totalSupply; 
        emit Transfer(address(0), founder, totalSupply);
    }

    function freezeAccounts(address[] memory targets, bool isFrozen) onlyOwner public {
        require(targets.length > 0);

        for (uint j = 0; j < targets.length; j++) {
            require(targets[j] != address(0));
            frozenAccount[targets[j]] = isFrozen;
            emit FrozenFunds(targets[j], isFrozen);
        }
    }
    function lockupAccounts(address[] memory targets, uint[] memory unixTimes) onlyOwner public {
        require(targets.length > 0
                && targets.length == unixTimes.length);

        for(uint j = 0; j < targets.length; j++){
            require(unlockUnixTime[targets[j]] == 0); 
            require(unixTimes[j] > now); 
            unlockUnixTime[targets[j]] = unixTimes[j];
            emit LockedUp(targets[j], unixTimes[j]);
        }
    }

    function transfer(address _to, uint _value, bytes memory _data) public  returns (bool success) {
        require(_value > 0 
                && _to != address(0) 
                && frozenAccount[msg.sender] == false
                && frozenAccount[_to] == false
                && now > unlockUnixTime[msg.sender]
                && now > unlockUnixTime[_to]);

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value);
        }
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(_value > 0
                && _to != address(0) 
                && frozenAccount[msg.sender] == false
                && frozenAccount[_to] == false
                && now > unlockUnixTime[msg.sender]
                && now > unlockUnixTime[_to]);

        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value);
        }
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    function transferToAddress(address _to, uint _value) private returns (bool success) { 
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferToContract(address _to, uint _value, bytes memory _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0)
                && _value > 0
                && balanceOf[_from] >= _value
                && allowance[_from][msg.sender] >= _value
                && frozenAccount[_from] == false
                && frozenAccount[msg.sender] == false 
                && frozenAccount[_to] == false
                && now > unlockUnixTime[_from]
                && now > unlockUnixTime[_to]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function burn(uint256 _unitAmount) onlyOwner public { 
        require(_unitAmount > 0 && balanceOf[msg.sender] >= _unitAmount); 

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_unitAmount); 
        totalSupply = totalSupply.sub(_unitAmount);
        emit Burn(msg.sender, _unitAmount); 
    }

    function burnFrom(address _from, uint256 _unitAmount) onlyOwner public { 
        require(_unitAmount > 0 && balanceOf[_from] >= _unitAmount);
        require(allowance[_from][msg.sender] >= _unitAmount); 
        balanceOf[_from] = balanceOf[_from].sub(_unitAmount);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_unitAmount); 
        totalSupply = totalSupply.sub(_unitAmount);
        emit Burn(_from, _unitAmount);
    }

    function distributeAirdrop(address[] memory addresses, uint[] memory amounts) public returns (bool) {
        require(addresses.length > 0
                && addresses.length == amounts.length
                && frozenAccount[msg.sender] == false
                && now > unlockUnixTime[msg.sender]);

        uint256 totalAmount = 0;

        for(uint j = 0; j < addresses.length; j++){
            require(amounts[j] > 0
                    && addresses[j] != address(0)
                    && frozenAccount[addresses[j]] == false
                    && now > unlockUnixTime[addresses[j]]);

            amounts[j] = amounts[j].mul(1e8); 
            totalAmount = totalAmount.add(amounts[j]);
            balanceOf[addresses[j]] = balanceOf[addresses[j]].add(amounts[j]); 
            emit Transfer(msg.sender, addresses[j], amounts[j]);
        }
        require(balanceOf[msg.sender] >= totalAmount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }

    function collectTokens(address[] memory addresses, uint[] memory amounts) onlyOwner public returns (bool) {
        require(addresses.length > 0 && addresses.length == amounts.length);
        uint256 totalAmount = 0;

        for (uint j = 0; j < addresses.length; j++) {
            require(amounts[j] > 0
                    && addresses[j] != address(0)
                    && frozenAccount[addresses[j]] == false
                    && now > unlockUnixTime[addresses[j]]);

            amounts[j] = amounts[j].mul(1e8); 
            require(balanceOf[addresses[j]] >= amounts[j]);
            require(allowance[addresses[j]][msg.sender] >= amounts[j]); 
            balanceOf[addresses[j]] = balanceOf[addresses[j]].sub(amounts[j]);
            allowance[addresses[j]][msg.sender] = allowance[addresses[j]][msg.sender].sub(amounts[j]); 
            totalAmount = totalAmount.add(amounts[j]);
            emit Transfer(addresses[j], msg.sender, amounts[j]);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].add(totalAmount);
        return true;
    }

    function() payable external { } 

    function withdrawETH() public onlyOwner {
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0);
        founder.transfer(ethBalance);
    } 
}