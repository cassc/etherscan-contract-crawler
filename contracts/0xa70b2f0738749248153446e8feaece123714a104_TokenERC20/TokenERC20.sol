/**
 *Submitted for verification at Etherscan.io on 2019-03-11
*/

pragma solidity ^0.5.1;


contract TokenERC20 {

    string public name;

    string public symbol;

    uint8 public decimals = 8;  // 18 是建议的默认值

    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;  //

    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol) public{

        totalSupply = initialSupply * 10 ** uint256(decimals);

        balanceOf[msg.sender] = totalSupply;

        name = tokenName;

        symbol = tokenSymbol;

    }

    function _transfer(address _from, address _to, uint _value) internal {

        require(_to != address(0));

        require(balanceOf[_from] >= _value);

        require(balanceOf[_to] + _value > balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;

        balanceOf[_to] += _value;

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

        emit Transfer(_from, _to, _value);



    }

    function transfer(address _to, uint256 _value) public {

        _transfer(msg.sender, _to, _value);

    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(_value <= allowance[_from][msg.sender]);     // Check allowance

        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;

    }

    function approve(address _spender, uint256 _value) public

    returns (bool success) {

        allowance[msg.sender][_spender] = _value;

        return true;

    }


    function burn(uint256 _value) public returns (bool success) {

        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;

        totalSupply -= _value;

        emit Burn(msg.sender, _value);

        return true;

    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {

        require(balanceOf[_from] >= _value);

        require(_value <= allowance[_from][msg.sender]);

        balanceOf[_from] -= _value;

        allowance[_from][msg.sender] -= _value;

        totalSupply -= _value;

        emit Burn(_from, _value);

        return true;
    }
}