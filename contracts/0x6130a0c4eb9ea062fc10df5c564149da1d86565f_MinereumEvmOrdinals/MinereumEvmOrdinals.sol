/**
 *Submitted for verification at Etherscan.io on 2023-07-04
*/

pragma solidity ^0.8.12;

interface tokenInterface {
  function totalSupply () external view returns (uint);
  function balanceOf (address _address) external view returns (uint);
  function mintLimit () external view returns (uint);
  function minted () external view returns (uint);  
  function mintCompleted() external view returns (bool);
  function setMintedOrdinalsPerAddress(address _from) external;
}

contract MinereumEvmOrdinals
{
	
address public owner;	
uint public fee = 0;
bool public blockCreation = false;
uint public tokensCount = 0;
string public site = "evmordinals.com/";
uint public symbolBytesLimit = 4;

string[] public ordinals;
address public outerAddress;

mapping(string => address) tokens;
mapping(string => uint) tokensOrdinals;
mapping(address => string) tokensOrdinalsSymbol;
mapping(address => uint) tokensAddressOrdinal;
mapping(address => uint[]) deployedOrdinals;
mapping(address => address[]) mintedOrdinalsPerAddress;

constructor(string memory chain) {
	owner = msg.sender;
	outerAddress = msg.sender;
	site = string.concat(site, chain);
	site = string.concat(site, "/search?tick=");
}

event CreateTokenHistory(address indexed _owner, string indexed _symbol, address indexed _address, uint _supply, uint _mintLimit);

function deploy(string memory symbol, uint supply, uint mintLimit) public payable 
{
	symbol = strUpper(symbol);
	
	if (tokens[symbol] != 0x0000000000000000000000000000000000000000)
		revert('Symbol already exists');
	
	if (fee > 0)
	{
		if (!(msg.value == fee)) revert('invalid fee amount');
	}
	
	if (blockCreation) revert('creation blocked, see website for latest info');
	
	if (!(bytes(symbol).length == symbolBytesLimit)) revert('');
	
	Token token = new Token(site, msg.sender, symbol, supply, mintLimit, address(this));
	
	ordinals.push(symbol);
	tokensOrdinals[symbol] = ordinals.length - 1;
	tokens[symbol] = address(token);
	tokensAddressOrdinal[address(token)] = ordinals.length - 1;
	tokensOrdinalsSymbol[address(token)] = symbol;
		
	emit CreateTokenHistory(msg.sender, symbol, address(token), supply, mintLimit);
	tokensCount++;	
	
	deployedOrdinals[msg.sender].push(ordinals.length - 1);
}

function strUpper(string memory value) public pure returns (string memory) 
{
    bytes memory bytesValue = bytes(value);
    
    bytes memory bytesLower = new bytes(bytesValue.length);
    
    for (uint i = 0; i < bytesValue.length; i++)
    {
        if (( uint8(bytesValue[i]) >= 97) && (uint8(bytesValue[i]) <= 122))
        {				
            bytesLower[i] = bytes1(uint8(bytesValue[i]) - 32);
        } 
        else 
        {
            bytesLower[i] = bytesValue[i];
        }
    }
	return string(bytesLower);
}

function ordinalsLength() public view returns (uint)
{
    return ordinals.length;
}

function getOrdinalsAt(uint i) public view returns (string memory)
{
	return ordinals[i];
}

function getTokenAddress(string memory symbol) public view returns (address)
{
	symbol = strUpper(symbol);
	return tokens[symbol];
}

function getTokenOrdinal(string memory symbol) public view returns (uint)
{
	symbol = strUpper(symbol);
	return tokensOrdinals[symbol];
}

function getDeployedOrdinals(address _owner) public view returns (uint[] memory)
{	
	return deployedOrdinals[_owner];
}

function getDeployedOrdinalsLength(address _owner) public view returns (uint)
{	
	return deployedOrdinals[_owner].length;
}

function getTokensAddressOrdinal(address _address) public view returns (uint)
{
	return tokensAddressOrdinal[_address];
}

function getTokenDirectTotalSupply(address _address) public view returns (uint)
{
	tokenInterface ti = tokenInterface(_address);
	return ti.totalSupply();
}

function getTokenDirectMintLimit(address _address) public view returns (uint)
{
	tokenInterface ti = tokenInterface(_address);
	return ti.mintLimit();
}

function getTokenDirectTotalMinted(address _address) public view returns (uint)
{
	tokenInterface ti = tokenInterface(_address);
	return ti.minted();
}

function getTokenDirectMintCompleted(address _address) public view returns (bool)
{
	tokenInterface ti = tokenInterface(_address);
	return ti.mintCompleted();
}

function getMintedOrdinalsPerAddressLength(address _address) public view returns (uint)
{
	return mintedOrdinalsPerAddress[_address].length;
}

function getMintedOrdinalsPerAddressAt(address _address, uint i) public view returns (address)
{
	return mintedOrdinalsPerAddress[_address][i];
}

function ListOrdinals(uint _startingIndex, uint _recordsLength) public view returns (uint[] memory _ordinals, string[] memory _symbols, address[] memory _contractAddress, uint[] memory _supply, uint[] memory _limit, uint[] memory _minted, bool[] memory _mintCompleted)
{	
	tokenInterface ti;
	
	if (_recordsLength > ordinals.length)
       _recordsLength = ordinals.length;
   
    _ordinals = new uint[](_recordsLength);
	_symbols = new string[](_recordsLength);
	_contractAddress = new address[](_recordsLength);
	_supply =  new uint[](_recordsLength);
	_limit = new uint[](_recordsLength);
	_minted = new uint[](_recordsLength);
	_mintCompleted = new bool[](_recordsLength);
	
    uint count = 0;
	for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < ordinals.length; i++){
        _ordinals[count] = i;
		_symbols[count] = ordinals[i];
		_contractAddress[count] = tokens[ordinals[i]];
		ti = tokenInterface(_contractAddress[count]);
		_supply[count] = ti.totalSupply();
		_limit[count] = ti.mintLimit();
		_minted[count] = ti.minted();
		_mintCompleted[count] = ti.mintCompleted();
		count++;
    }
}

function ListDeployedByOwner(address _address, uint _startingIndex, uint _recordsLength) public view returns (uint[] memory _ordinals, string[] memory _symbols, address[] memory _contractAddress)
{	
	if (_recordsLength > deployedOrdinals[_address].length)
       _recordsLength = deployedOrdinals[_address].length;
   
    _ordinals = new uint[](_recordsLength);
	_symbols = new string[](_recordsLength);
	_contractAddress = new address[](_recordsLength);	
	
    uint count = 0;
	for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < deployedOrdinals[_address].length; i++){

        uint j = deployedOrdinals[_address][i];
        _ordinals[count] = j;
		_symbols[count] = ordinals[j];
		_contractAddress[count] = tokens[ordinals[j]];
		count++;
    }
}

function ListOrdinalsBalance(address _address, uint _startingIndex, uint _recordsLength) public view returns (string[] memory _symbols, address[] memory _contractAddress, uint[] memory _balances)
{	
	tokenInterface ti;
	
	if (_recordsLength > ordinals.length)
       _recordsLength = ordinals.length;
   
    _symbols = new string[](_recordsLength);
	_contractAddress = new address[](_recordsLength);
	_balances =  new uint[](_recordsLength);
	
	
    uint count = 0;
	for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < mintedOrdinalsPerAddress[_address].length; i++){
		uint j = tokensAddressOrdinal[mintedOrdinalsPerAddress[_address][i]];
		_symbols[count] = ordinals[j];
		_contractAddress[count] = tokens[ordinals[j]];
		ti = tokenInterface(_contractAddress[count]);
		_balances[count] = ti.balanceOf(_address);
		count++;
    }
}

function setFee(uint value) public
{
	if(msg.sender == owner)
		fee = value;
	else
		revert();
}

function setSymbolBytesLimit(uint value) public
{
	if(msg.sender == owner)
		symbolBytesLimit = value;
	else
		revert();
}
	
function setBlockCreation(bool value) public
{
	if(msg.sender == owner)
		blockCreation = value;
	else
		revert();
}

function setSite(string memory value) public
{
	if(msg.sender == owner)
		site = value;
	else
		revert();
}

function release() public
{
	address payable add = payable(outerAddress);
	if(!add.send(address(this).balance)) revert();
}

function setOuterAddress(address _address) public
{
	if(msg.sender == owner)
		outerAddress = _address;
	else
		revert();
}

function setMintedOrdinalsPerAddress(address _from) public
{
    if(bytes(tokensOrdinalsSymbol[msg.sender]).length > 0)
	{
		mintedOrdinalsPerAddress[_from].push(msg.sender);
	}
	else
		revert('Ordinal Not Recognized');
}

}

contract Token {
    string public symbol = "";
    string public name = "";
    uint8 public constant decimals = 18;
    uint256 public _totalSupply = 0;
	uint256 public _mintLimit = 0;
    uint public _minted = 0;
	address public deployer;
	address public factory;
	
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 
    mapping(address => uint256) balances;
 
    mapping(address => mapping (address => uint256)) allowed;
 
    constructor(string memory csite, address cadr, string memory ctokenSymbol, uint ctokenSupply, uint cmintLimit, address cfactory) {
		deployer = cadr;
        symbol = ctokenSymbol;
        name = string.concat(csite, ctokenSymbol);
		_totalSupply = ctokenSupply * 1000000000000000000;
		_mintLimit = cmintLimit * 1000000000000000000;
        factory = cfactory;
		
		if (_mintLimit > _totalSupply) revert('invalid supply/mintlimit ratio');
    }
	
	function mint(uint amount, uint repeat) public
	{
		for (uint i = 0; i < repeat; i++)
		{
			if (_minted >= _totalSupply) revert('minted exceeds supply');
			if ((_minted + amount) > _totalSupply) revert('mint exceeds supply');
			if (amount > _mintLimit) revert('amount exceeds mint limit');
			balances[msg.sender] += amount;				
			_minted += amount;					
			emit Transfer(address(this), msg.sender, amount);
			tokenInterface ti = tokenInterface(factory);
			ti.setMintedOrdinalsPerAddress(msg.sender);
		}		
	}
   
    function totalSupply() public view returns (uint256) {        
        return _totalSupply;
    }
	
	function mintLimit() public view returns (uint256) {        
        return _mintLimit;
    }
	
	function minted() public view returns (uint256) {        
        return _minted;
    }
	
	function mintCompleted() public view returns (bool)
	{
		return (_minted == _totalSupply);	
	}
 
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
 
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )  public returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}