/**
 *Submitted for verification at Etherscan.io on 2023-04-02
*/

/**
                                   _ 
                                  (_)
  _ __   ___ _ __   ___  _ __  _____ 
 | '_ \ / _ \ '_ \ / _ \| '_ \|_  / |
 | |_) |  __/ |_) | (_) | | | |/ /| |
 | .__/ \___| .__/ \___/|_| |_/___|_|
 | |        | |                      
 |_|        |_|                      
 
Peponzi is a new age Ponzi token with game mechanics that offers a fun and exciting way to earn passive income. 
Built on the Ethereum blockchain, Peponzi allows users to buy specific Pepes and generate PEPONZI tokens through them. 
Peponzi automatically burns 2.5% of tokens from volume, which ensures that the token remains viable in the long run.
With five Pepes to choose from, Peponzi offers a unique opportunity to earn rewards while enjoying the universal appeal of Pepe the Frog.
Interested? Let's start with Protocol description.

The Peponzi protocol is at the heart of our unique crypto ecosystem. Inspired by the success of node tokens, Peponzi has developed a new model that uses Pepes instead of traditional nodes. 
This innovative approach allows users to generate passive income through our token while also maintaining the sustainability of the system through automatic token burning from generated volume.
There are similarities between the Peponzi protocol and other popular projects such as Universe and BRR. 
However, we believe that the Peponzi protocol is superior in several ways. 
Our goal is to provide holders with Pepes that print tokens, which ensures a steady flow of income for our users. 
At the same time, we are committed to maintaining the long-term viability of our platform through a deflationary approach that burns tokens automatically.
We are also not using NFTs as nodes due to Ethereum gas fees.
Pepes owners can claim PEPONZI rewards at any time, rewards are not locked.

Website: https://peponzi.com
Telegram: https://t.me/peponzicom
Twitter: https://twitter.com/peponzi_com
Discord: https://discord.gg/hs9nYYcEGZ
Medium: https://medium.com/@peponzi/peponzi-new-age-ponzi-token-f9f4545509ab
Docs: https://peponzi.gitbook.io/introduction/

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Peponzi is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    struct Node {
        uint256 createDate;
        uint256 lastClaimTime;
        string name;
    }

    struct Node2 {
        uint256 createDate;
        uint256 lastClaimTime;
        string name;
    }

    struct Node3 {
        uint256 createDate;
        uint256 lastClaimTime;
        string name;
    }

    struct Node4 {
        uint256 createDate;
        uint256 lastClaimTime;
        string name;
    }

    struct Node5 {
        uint256 createDate;
        uint256 lastClaimTime;
        string name;
    }

    uint256 public rewardPerSecond = 217500000000000000;
    uint256 public reward2PerSecond = 543900000000000000;
    uint256 public reward3PerSecond = 1643500000000000000;
    uint256 public reward4PerSecond = 4629600000000000000;
    uint256 public reward5PerSecond = 18518500000000000000;

    uint256 public nodePrice = 1000000000000000000000000;
    uint256 public node2Price = 2000000000000000000000000;
    uint256 public node3Price = 5000000000000000000000000;
    uint256 public node4Price = 10000000000000000000000000;
    uint256 public node5Price = 28000000000000000000000000;

    uint256 public total1Nodes = 0;
    uint256 public total2Nodes = 0;
    uint256 public total3Nodes = 0;
    uint256 public total4Nodes = 0;
    uint256 public total5Nodes = 0;
	
	uint256 public totalPeponziBurned = 0;

    ERC20 MIM;
    mapping(address => Node[]) public nodes1pepe;
    mapping(address => Node2[]) public nodes2pepe;
    mapping(address => Node3[]) public nodes3pepe;
    mapping(address => Node4[]) public nodes4pepe;
    mapping(address => Node5[]) public nodes5pepe;

    uint256 public _totalSupply = 1000000000 * 10**_decimals;

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = false;
    address payable private _taxWallet;

    uint256 private _initialBuyTax=6;
    uint256 private _initialSellTax=15;
    uint256 private _finalBuyTax=5;
    uint256 private _finalSellTax=5;
    uint256 private _reduceBuyTaxAt=1;
    uint256 private _reduceSellTaxAt=15;
    uint256 private _preventSwapBefore=20;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = unicode"Peponzi";
    string private constant _symbol = unicode"Peponzi";
    uint256 public _maxTxAmount =   30000000 * 10**_decimals;//3%
    uint256 public _maxWalletSize = 30000000 * 10**_decimals;//3%
    uint256 public _taxSwapThreshold=4000000 * 10**_decimals;
    uint256 public _maxTaxSwap=4000000 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        MIM = ERC20(address(this));
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (transferDelayEnabled) {
                  if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                      require(
                          _holderLastTransferTimestamp[tx.origin] <
                              block.number,
                          "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                      );
                      _holderLastTransferTimestamp[tx.origin] = block.number;
                  }
              }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                swapTokensForEth(min(amount.div(2),min(contractTokenBalance.div(2),_maxTaxSwap.div(2))));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
                uint256 contractTokenBalanceNow = balanceOf(address(this));
                uint uCTBn = 0;
                uCTBn += min(amount.div(2),min(contractTokenBalanceNow,_maxTaxSwap.div(2)));
				totalPeponziBurned += uCTBn;
                _totalSupply = _totalSupply.sub(uCTBn);
                _balances[address(this)]=_balances[address(this)].sub(uCTBn);
                _balances[address(0xdead)]=_balances[address(0xdead)].add(uCTBn);
                emit Transfer(address(this), address(0xdead), uCTBn);
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function isBot(address a) public view returns (bool){
      return bots[a];
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

       function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function setNodePrice(uint256 price, uint256 price2, uint256 price3, uint256 price4, uint256 price5) external onlyOwner {
        nodePrice = price;
        node2Price = price2;
        node3Price = price3;
        node4Price = price4;
        node5Price = price5;
    }

    function setRewards(uint256 rewards,uint256 rewards2,uint256 rewards3,uint256 rewards4,uint256 rewards5) external onlyOwner {
        rewardPerSecond = rewards;
        reward2PerSecond = rewards2;
        reward3PerSecond = rewards3;
        reward4PerSecond = rewards4;
        reward5PerSecond = rewards5;
    }

    function createNode1Lvl(string memory _nodename, address user) internal {
        Node memory newNode;
        newNode.createDate = block.timestamp;
        newNode.lastClaimTime = block.timestamp;
        newNode.name = _nodename;
        nodes1pepe[user].push(newNode);
        total1Nodes++;
    }

    function createNode2Lvl(string memory _nodename, address user) internal {
        Node2 memory newNode;
        newNode.createDate = block.timestamp;
        newNode.lastClaimTime = block.timestamp;
        newNode.name = _nodename;
        nodes2pepe[user].push(newNode);
        total2Nodes++;
    }

    function createNode3Lvl(string memory _nodename, address user) internal {
        Node3 memory newNode;
        newNode.createDate = block.timestamp;
        newNode.lastClaimTime = block.timestamp;
        newNode.name = _nodename;
        nodes3pepe[user].push(newNode);
        total3Nodes++;
    }

    function createNode4Lvl(string memory _nodename, address user) internal {
        Node4 memory newNode;
        newNode.createDate = block.timestamp;
        newNode.lastClaimTime = block.timestamp;
        newNode.name = _nodename;
        nodes4pepe[user].push(newNode);
        total4Nodes++;
    }

    function createNode5Lvl(string memory _nodename, address user) internal {
        Node5 memory newNode;
        newNode.createDate = block.timestamp;
        newNode.lastClaimTime = block.timestamp;
        newNode.name = _nodename;
        nodes5pepe[user].push(newNode);
        total5Nodes++;
    }

    function buy1LvlPepe(string memory _nodename) external {
        MIM.transferFrom(msg.sender, address(this), nodePrice);
        createNode1Lvl(_nodename, msg.sender);
    }

    function buy2LvlPepe(string memory _nodename) external {
        MIM.transferFrom(msg.sender, address(this), node2Price);
        createNode2Lvl(_nodename, msg.sender);
    }

    function buy3LvlPepe(string memory _nodename) external {
        MIM.transferFrom(msg.sender, address(this), node3Price);
        createNode3Lvl(_nodename, msg.sender);
    }

    function buy4LvlPepe(string memory _nodename) external {
        MIM.transferFrom(msg.sender, address(this), node4Price);
        createNode4Lvl(_nodename, msg.sender);
    }

    function buy5LvlPepe(string memory _nodename) external {
        MIM.transferFrom(msg.sender, address(this), node5Price);
        createNode5Lvl(_nodename, msg.sender);
    }


    function getTotalPendingRewards1Lvl(address user)
        public
        view
        returns (uint256)
    {
        Node[] memory userNodes = nodes1pepe[user];
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < userNodes.length; i++) {
            totalRewards += ((block.timestamp - userNodes[i].lastClaimTime) *
                rewardPerSecond);
        }
        return totalRewards;
    }

    function getTotalPendingRewards2Lvl(address user)
        public
        view
        returns (uint256)
    {
        Node2[] memory userNodes = nodes2pepe[user];
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < userNodes.length; i++) {
            totalRewards += ((block.timestamp - userNodes[i].lastClaimTime) *
                reward2PerSecond);
        }
        return totalRewards;
    }

    function getTotalPendingRewards3Lvl(address user)
        public
        view
        returns (uint256)
    {
        Node3[] memory userNodes = nodes3pepe[user];
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < userNodes.length; i++) {
            totalRewards += ((block.timestamp - userNodes[i].lastClaimTime) *
                reward3PerSecond);
        }
        return totalRewards;
    }

    function getTotalPendingRewards4Lvl(address user)
        public
        view
        returns (uint256)
    {
        Node4[] memory userNodes = nodes4pepe[user];
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < userNodes.length; i++) {
            totalRewards += ((block.timestamp - userNodes[i].lastClaimTime) *
                reward4PerSecond);
        }
        return totalRewards;
    }

    function getTotalPendingRewards5Lvl(address user)
        public
        view
        returns (uint256)
    {
        Node5[] memory userNodes = nodes5pepe[user];
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < userNodes.length; i++) {
            totalRewards += ((block.timestamp - userNodes[i].lastClaimTime) *
                reward5PerSecond);
        }
        return totalRewards;
    }

    function getNumberOfNode1Lvl(address user) public view returns (uint256) {
        return nodes1pepe[user].length;
    }

    function getNumberOfNode2Lvl(address user) public view returns (uint256) {
        return nodes2pepe[user].length;
    }

    function getNumberOfNode3Lvl(address user) public view returns (uint256) {
        return nodes3pepe[user].length;
    }

    function getNumberOfNode4Lvl(address user) public view returns (uint256) {
        return nodes4pepe[user].length;
    }

    function getNumberOfNode5Lvl(address user) public view returns (uint256) {
        return nodes5pepe[user].length;
    }

    function getNode1LvlCreation(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        return (nodes1pepe[user][id].createDate);
    }

    function getNode2LvlCreation(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        return (nodes2pepe[user][id].createDate);
    }

    function getNode3LvlCreation(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        return (nodes3pepe[user][id].createDate);
    }

    function getNode4LvlCreation(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        return (nodes4pepe[user][id].createDate);
    }

    function getNode5LvlCreation(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        return (nodes5pepe[user][id].createDate);
    }

    function getNode1LvlLastClaim(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        return (nodes1pepe[user][id].createDate);
    }

    function getNode2LvlLastClaim(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        return (nodes2pepe[user][id].createDate);
    }

    function getNode3LvlLastClaim(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        return (nodes3pepe[user][id].createDate);
    }

    function getNode4LvlLastClaim(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        return (nodes4pepe[user][id].createDate);
    }

    function getNode5LvlLastClaim(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        return (nodes5pepe[user][id].createDate);
    }

    function getPendingRewards1Lvl(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        Node memory node = nodes1pepe[user][id];
        return ((block.timestamp - node.lastClaimTime) * rewardPerSecond);
    }

    function getPendingRewards2Lvl(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        Node2 memory node = nodes2pepe[user][id];
        return ((block.timestamp - node.lastClaimTime) * reward2PerSecond);
    }

    function getPendingRewards3Lvl(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        Node3 memory node = nodes3pepe[user][id];
        return ((block.timestamp - node.lastClaimTime) * reward3PerSecond);
    }

    function getPendingRewards4Lvl(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        Node4 memory node = nodes4pepe[user][id];
        return ((block.timestamp - node.lastClaimTime) * reward4PerSecond);
    }

    function getPendingRewards5Lvl(address user, uint256 id)
        public
        view
        returns (uint256)
    {
        Node5 memory node = nodes5pepe[user][id];
        return ((block.timestamp - node.lastClaimTime) * reward5PerSecond);
    }

    function claim1Lvl(uint256 id) external {
        Node storage node = nodes1pepe[msg.sender][id];
        uint256 timeElapsed = block.timestamp - node.lastClaimTime;
        node.lastClaimTime = block.timestamp;
        _balances[msg.sender] =
            _balances[msg.sender] +
            timeElapsed *
            rewardPerSecond;
		emit Transfer(address(0), msg.sender, timeElapsed * rewardPerSecond);
    }

    function claim2Lvl(uint256 id) external {
        Node2 storage node = nodes2pepe[msg.sender][id];
        uint256 timeElapsed = block.timestamp - node.lastClaimTime;
        node.lastClaimTime = block.timestamp;
        _balances[msg.sender] =
            _balances[msg.sender] +
            timeElapsed *
            reward2PerSecond;
		emit Transfer(address(0), msg.sender, timeElapsed * reward2PerSecond);
    }

    function claim3Lvl(uint256 id) external {
        Node3 storage node = nodes3pepe[msg.sender][id];
        uint256 timeElapsed = block.timestamp - node.lastClaimTime;
        node.lastClaimTime = block.timestamp;
        _balances[msg.sender] =
            _balances[msg.sender] +
            timeElapsed *
            reward3PerSecond;
		emit Transfer(address(0), msg.sender, timeElapsed * reward3PerSecond);
    }

    function claim4Lvl(uint256 id) external {
        Node4 storage node = nodes4pepe[msg.sender][id];
        uint256 timeElapsed = block.timestamp - node.lastClaimTime;
        node.lastClaimTime = block.timestamp;
        _balances[msg.sender] =
            _balances[msg.sender] +
            timeElapsed *
            reward4PerSecond;
		emit Transfer(address(0), msg.sender, timeElapsed * reward4PerSecond);
    }

    function claim5Lvl(uint256 id) external {
        Node5 storage node = nodes5pepe[msg.sender][id];
        uint256 timeElapsed = block.timestamp - node.lastClaimTime;
        node.lastClaimTime = block.timestamp;
        _balances[msg.sender] =
            _balances[msg.sender] +
            timeElapsed *
            reward5PerSecond;
		emit Transfer(address(0), msg.sender, timeElapsed * reward5PerSecond);
    }


    function getPendingRewardsEach1Lvl(address user)
        public
        view
        returns (string memory)
    {
        string memory result;
        string memory separator = "#";
        Node[] memory userNodes = nodes1pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            uint256 pending = (block.timestamp - userNodes[i].lastClaimTime) *
                rewardPerSecond;
            result = string(
                abi.encodePacked(result, separator, uint2str(pending))
            );
        }
        return result;
    }

    function getPendingRewardsEach2Lvl(address user)
        public
        view
        returns (string memory)
    {
        string memory result;
        string memory separator = "#";
        Node2[] memory userNodes = nodes2pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            uint256 pending = (block.timestamp - userNodes[i].lastClaimTime) *
                reward2PerSecond;
            result = string(
                abi.encodePacked(result, separator, uint2str(pending))
            );
        }
        return result;
    }

    function getPendingRewardsEach3Lvl(address user)
        public
        view
        returns (string memory)
    {
        string memory result;
        string memory separator = "#";
        Node3[] memory userNodes = nodes3pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            uint256 pending = (block.timestamp - userNodes[i].lastClaimTime) *
                reward3PerSecond;
            result = string(
                abi.encodePacked(result, separator, uint2str(pending))
            );
        }
        return result;
    }

    function getPendingRewardsEach4Lvl(address user)
        public
        view
        returns (string memory)
    {
        string memory result;
        string memory separator = "#";
        Node4[] memory userNodes = nodes4pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            uint256 pending = (block.timestamp - userNodes[i].lastClaimTime) *
                reward4PerSecond;
            result = string(
                abi.encodePacked(result, separator, uint2str(pending))
            );
        }
        return result;
    }

    function getPendingRewardsEach5Lvl(address user)
        public
        view
        returns (string memory)
    {
        string memory result;
        string memory separator = "#";
        Node5[] memory userNodes = nodes5pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            uint256 pending = (block.timestamp - userNodes[i].lastClaimTime) *
                reward5PerSecond;
            result = string(
                abi.encodePacked(result, separator, uint2str(pending))
            );
        }
        return result;
    }


    function getCreationEach1Lvl(address user) public view returns (string memory) {
        string memory result;
        string memory separator = "#";
        Node[] memory userNodes = nodes1pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            uint256 creation = userNodes[i].createDate;
            result = string(
                abi.encodePacked(result, separator, uint2str(creation))
            );
        }
        return result;
    }

    function getCreationEach2Lvl(address user) public view returns (string memory) {
        string memory result;
        string memory separator = "#";
        Node2[] memory userNodes = nodes2pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            uint256 creation = userNodes[i].createDate;
            result = string(
                abi.encodePacked(result, separator, uint2str(creation))
            );
        }
        return result;
    }

    function getCreationEach3Lvl(address user) public view returns (string memory) {
        string memory result;
        string memory separator = "#";
        Node3[] memory userNodes = nodes3pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            uint256 creation = userNodes[i].createDate;
            result = string(
                abi.encodePacked(result, separator, uint2str(creation))
            );
        }
        return result;
    }

    function getCreationEach4Lvl(address user) public view returns (string memory) {
        string memory result;
        string memory separator = "#";
        Node4[] memory userNodes = nodes4pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            uint256 creation = userNodes[i].createDate;
            result = string(
                abi.encodePacked(result, separator, uint2str(creation))
            );
        }
        return result;
    }

    function getCreationEach5Lvl(address user) public view returns (string memory) {
        string memory result;
        string memory separator = "#";
        Node5[] memory userNodes = nodes5pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            uint256 creation = userNodes[i].createDate;
            result = string(
                abi.encodePacked(result, separator, uint2str(creation))
            );
        }
        return result;
    }

    function getNameEach1Lvl(address user) public view returns (string memory) {
        string memory result;
        string memory separator = "#";
        Node[] memory userNodes = nodes1pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            string memory nodeName = userNodes[i].name;
            result = string(abi.encodePacked(result, separator, nodeName));
        }
        return result;
    }

    function getNameEach2Lvl(address user) public view returns (string memory) {
        string memory result;
        string memory separator = "#";
        Node2[] memory userNodes = nodes2pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            string memory nodeName = userNodes[i].name;
            result = string(abi.encodePacked(result, separator, nodeName));
        }
        return result;
    }
    
    function getNameEach3Lvl(address user) public view returns (string memory) {
        string memory result;
        string memory separator = "#";
        Node3[] memory userNodes = nodes3pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            string memory nodeName = userNodes[i].name;
            result = string(abi.encodePacked(result, separator, nodeName));
        }
        return result;
    }

    function getNameEach4Lvl(address user) public view returns (string memory) {
        string memory result;
        string memory separator = "#";
        Node4[] memory userNodes = nodes4pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            string memory nodeName = userNodes[i].name;
            result = string(abi.encodePacked(result, separator, nodeName));
        }
        return result;
    }

    function getNameEach5Lvl(address user) public view returns (string memory) {
        string memory result;
        string memory separator = "#";
        Node5[] memory userNodes = nodes5pepe[user];
        for (uint256 i = 0; i < userNodes.length; i++) {
            string memory nodeName = userNodes[i].name;
            result = string(abi.encodePacked(result, separator, nodeName));
        }
        return result;
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender()==_taxWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }
}