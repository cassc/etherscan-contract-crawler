/**
 *Submitted for verification at Etherscan.io on 2023-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
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

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract DexBot is Ownable, ERC20 {

    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    IUniswapV2Router02 public immutable uniswapV2Router;

    bool swapping;
    bool public exchangeable;
    bool public transferable;
    bool public maxLimited;
    bool public botLimited;
    address public team;
    address public rewardPool;
    address public burnAddress;
    address public exToken;
    uint256 public buyFeeRate;
    uint256 public sellFeeRate;
    uint256 public totalFeeAmount;
    uint256 public swapAmount;
    uint256 public swapShare;
    uint256 public burnShare;
    uint256 public teamShare;
    uint256 public burnLimit;
    uint256 public maxHoldingAmount;
    mapping (address => mapping(address => uint256)) public balanceFromPool;
    mapping (address => bool) public uniswapPool;
    mapping (address => bool) public blacklist;
    mapping (address => bool) public dutyFree;
    mapping (address => uint256) public lastTradingBlock;

    event Exchanged(address indexed owner, uint256 indexed amount);
    event SwapAmountSet(address indexed owner, uint256 indexed amount);
    event TeamSet(address indexed owner, address indexed account);
    event BurnAddressSet(address indexed owner, address indexed account);
    event ShareSet(address indexed owner, uint256 swapShare, uint256 burnShare, uint256 teamShare);
    event RewardPoolSet(address indexed owner, address indexed account);
    event LimitSet(address indexed owner, bool indexed limited, uint256 indexed amount);
    event PoolSet(address indexed owner, address indexed account, bool indexed value);
    event DutyFreeSet(address indexed owner, address indexed account, bool indexed value);
    event FeeRateSet(address indexed owner, uint256 indexed buyFeeRate, uint256 indexed sellFeeRate);
    event BurnLimitSet(address indexed owner, uint256 burnLimit);
    event BlacklistSet(address indexed owner, address[] accounts);
    event BlacklistRemoved(address indexed owner, address[] accounts);

    constructor(address _token, uint256 _totalSupply) ERC20("DexBot", "DEXBOT") {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       
        exchangeable = true;
        maxLimited = false;
        botLimited = true;
        swapping = false;

        swapAmount = (_totalSupply * 25) / 10000; 
        maxHoldingAmount = _totalSupply;

        swapShare = 0.2 ether;
        burnShare = 0.4 ether;
        teamShare = 0.4 ether;

        burnLimit = _totalSupply / 10;

        buyFeeRate = 0.05 ether;
        sellFeeRate = 0.05 ether;
        
        exToken = _token;
        team = msg.sender;
        burnAddress = msg.sender;

        dutyFree[msg.sender] = true;
        dutyFree[address(this)] = true;

        _mint(msg.sender, _totalSupply);
    }

    fallback() external payable {}

    receive() external payable {}

    function exchange(uint256 amount) external {
        require(exchangeable, "non exchangeable");

        IERC20(exToken).transferFrom(msg.sender, DEAD_ADDRESS, amount);
        IERC20(address(this)).transfer(msg.sender, amount);

        emit Exchanged(msg.sender, amount);
    }

    function setExchangeable() external onlyOwner {
        exchangeable = !exchangeable;
    }

    function setTransferable() external onlyOwner {
        transferable = !transferable;
    }

    function withdrawToken(address token, address to) external onlyOwner {
        require(token != address(0), "token address cannot be zero address");
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to, balance);
    }

    function withdrawEth(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}(new bytes(0));
        require(success, "eth transfer failed");
    }

    function setMaxLimit(bool _limited, uint256 _amount) external onlyOwner {
        maxLimited = _limited;
        maxHoldingAmount = _amount;
        emit LimitSet(msg.sender, maxLimited, maxHoldingAmount);
    }

    function setBotLimited() external onlyOwner {
        botLimited = !botLimited;
    }

    function setPool(address account) external onlyOwner {
        uniswapPool[account] = !uniswapPool[account];
        emit PoolSet(msg.sender, account, uniswapPool[account]);
    }

    function setTeam(address account) external onlyOwner {
        dutyFree[team] = false;

        team = account;
        dutyFree[team] = true;

        emit TeamSet(msg.sender, team);
    }

    function setRewardPool(address account) external onlyOwner {
        rewardPool = account;
        emit RewardPoolSet(msg.sender, rewardPool);
    }

    function setBurnAddress(address account) external onlyOwner {
        burnAddress = account;
        emit BurnAddressSet(msg.sender, burnAddress);
    }

    function setDutyFree(address account) public onlyOwner {
        dutyFree[account] = !dutyFree[account];
        emit DutyFreeSet(msg.sender, account, dutyFree[account]);
    }

    function setFeeRate(uint256 _buyFeeRate, uint256 _sellFeeRate) external onlyOwner {
        buyFeeRate = _buyFeeRate;
        sellFeeRate = _sellFeeRate;
        emit FeeRateSet(msg.sender, _buyFeeRate, _sellFeeRate);
    }

    function setBurnLimit(uint256 _burnLimit) external onlyOwner {
        burnLimit = _burnLimit;
        emit BurnLimitSet(msg.sender, _burnLimit);
    }

    function setSwapAmount(uint256 _swapAmount) external onlyOwner {
        swapAmount = _swapAmount;
        emit SwapAmountSet(msg.sender, _swapAmount);
    }

    function setShare(uint256 _swapShare, uint256 _burnShare, uint256 _teamShare) external onlyOwner {
        uint256 totalShare = _swapShare+_burnShare+_teamShare;
        require(totalShare == 1 ether, "forbid");
        swapShare = _swapShare;
        burnShare = _burnShare;
        teamShare = _teamShare;
        emit ShareSet(msg.sender, swapShare, burnShare, teamShare);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!blacklist[to] && !blacklist[from], "blacklisted");

        if (!transferable) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        if (maxLimited && uniswapPool[from]) {
            require(balanceFromPool[to][from] + amount <= maxHoldingAmount, "buy limit");
            balanceFromPool[to][from] += amount;
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (!swapping && !uniswapPool[from]) {
            swapping = true;
            _swapBack();
            swapping = false;
        }

        uint256 feeRate = 0;
        if (uniswapPool[from]) {
            if (botLimited) {
                require(lastTradingBlock[to] != block.number, "bot limit");
                lastTradingBlock[to] = block.number;
            }

            if (!dutyFree[to]) {
                feeRate = buyFeeRate;
            }
        } else if (uniswapPool[to]) {
            if (botLimited) {
                require(lastTradingBlock[from] != block.number, "bot limit");
                lastTradingBlock[from] = block.number;
            }

            if (!dutyFree[from]) {
                feeRate = sellFeeRate;
            }
        }

        if (feeRate > 0 && amount > 0) {
            uint256 fee = amount * feeRate / 1 ether;
            totalFeeAmount += fee;
            super._transfer(from, address(this), fee);
            amount -= fee;
        }
    

        super._transfer(from, to, amount);
    }

    function _swapBack() internal {
        if (totalFeeAmount <= swapAmount) {
            return;
        }

        bool success;

        uint256 amountToBurn = totalFeeAmount * burnShare / 1 ether;
        uint256 amountToTeam = totalFeeAmount * teamShare / 1 ether;
        uint256 amountToShare = totalFeeAmount * swapShare / 1 ether;

        uint256 halfAmountToTeam = amountToTeam / 2;

        uint256 amountToSwap = amountToShare + halfAmountToTeam;

        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwap);

        uint256 halfETHBalance = (address(this).balance - initialETHBalance) / 2;

        (success, ) = team.call{value: halfETHBalance}(new bytes(0));
        require(success, "eth transfer failed");

        (success, ) = rewardPool.call{value: halfETHBalance}(new bytes(0));
        require(success, "eth transfer failed");

        if( totalSupply() >= burnLimit){
            IERC20(address(this)).transfer(burnAddress, amountToBurn);
        }

        IERC20(address(this)).transfer(team, halfAmountToTeam);

        totalFeeAmount = 0;
    }

    function _swapTokensForEth(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if (allowance(address(this), address(uniswapV2Router)) < amount) {
            _approve(address(this), address(uniswapV2Router), type(uint256).max);
        }

        uniswapV2Router.swapExactTokensForETH(amount, 0, path, address(this), block.timestamp);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}