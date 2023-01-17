// SPDX-License-Identifier: MIT
//
// Kaoru Sama AI
// Telegram: https://t.me/Kaoru_Sama
//
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
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
        return 9;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
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
    function approve(
        address spender,
        uint256 amount
    ) external virtual override returns (bool) {
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
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
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

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }
}

contract KaoruSama is ERC20, Ownable {
    address public marketingWallet = 0x66321fd8A1b5227D29434C49B26C2e27e4592A78;
    address public devWallet = 0xbb01C5984549D7F01aaAb685400320fb8669cC50;
    address public teamWallet = 0xe20Fe7dD635687aa9652F87A9C3A5CC0C1e565f5;

    uint256 public feeLiquidity = 100;
    uint256 public feeMarketing = 284;
    uint256 public feeTeam = 66;
    uint256 public feeDev = 50;
    uint256 public taxTotal = feeLiquidity + feeMarketing + feeDev + feeTeam;

    uint256 public maxWalletSize;
    bool inSwapAndLiquify;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    uint256 public _swapbackThreshold = 150;
    uint256 public lpBalance;
   
    mapping(address => bool) private _isExcludedFromFee;
    uint256 public firstDay = 24 hours;
    
    uint256 public lpTimestamp;
    mapping (address => bool) private boughtEarly;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    // for first 24 hours owner can call this function, to prevent prepumping and bots, before the contract is officially launched
    function changeStatus(address _address, bool status) external onlyOwner {
        require(block.timestamp <= lpTimestamp + firstDay, "Cant call this anymore");
        boughtEarly[_address] = status;
    }

    // same, but for multiple addresses in 1 tx
    function changeStatusArray(address[] memory _addresses, bool status) external onlyOwner {
        require(block.timestamp <= lpTimestamp + firstDay, "Cant call this anymore");
        for (uint256 i = 0; i < _addresses.length; i++) {
            boughtEarly[_addresses[i]] = status;
        }
    }

    constructor() ERC20("Kaoru Sama", "KAORU") {
        uint256 startSupply = 1e7 * 10 ** decimals();
        maxWalletSize = startSupply / 100;
        _mint(msg.sender, (startSupply));
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[address(uniswapV2Router)] = true;
        _isExcludedFromFee[msg.sender] = true;
        
        _approve(msg.sender, address(uniswapV2Router), type(uint256).max);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            !boughtEarly[from] && !boughtEarly[to], "cant trade"
        );
        uint256 lp = balanceOf(uniswapV2Pair);
        lpBalance = lp;
        if (
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            inSwapAndLiquify
        ) {
            super._transfer(from, to, amount);
            if (lpTimestamp == 0 && balanceOf(uniswapV2Pair) > 0) {
                lpTimestamp = block.timestamp;
            }
        } else {
            uint taxAmount;
            if (to == uniswapV2Pair) {
                // Sell
                uint256 bal = balanceOf(address(this));
                if (
                    bal >= (lp * _swapbackThreshold) / 10000
                ) {
                    _swapAndLiquify(bal);
                }
                taxAmount = amount * taxTotal / 10000;
            } else if (from == uniswapV2Pair) {
                taxAmount = amount * taxTotal / 10000;
                require(
                    balanceOf(to) + amount - taxAmount <= maxWalletSize,
                    "ERC20: transfer amount exceeds max wallet amount"
                );
            } else {
                require(
                    balanceOf(to) + amount <= maxWalletSize,
                    "ERC20: transfer amount exceeds max wallet amount"
                );
            }
            super._transfer(from, to, amount - taxAmount);
            if (taxAmount > 0) {
                super._transfer(from, address(this), taxAmount);
            }
        }
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 _taxTotal = taxTotal;
        uint256 taxWithoutHalfLP = _taxTotal - feeLiquidity / 2;
        uint256 toSell = contractTokenBalance * taxWithoutHalfLP / _taxTotal;

        uint256 initialBalance = address(this).balance;
        _swapTokensForEth(toSell);
        uint256 newBalance = (address(this).balance - initialBalance);

        uint256 toDev = newBalance * feeDev / taxWithoutHalfLP;
        uint256 toMarketing = newBalance * feeMarketing / taxWithoutHalfLP;
        uint256 toTeam = newBalance * feeTeam / taxWithoutHalfLP;
        
        payable(devWallet).transfer(toDev);
        payable(marketingWallet).transfer(toMarketing);
        payable(teamWallet).transfer(toTeam);

        _addLiquidity(
            contractTokenBalance - toSell,
            newBalance - toDev - toMarketing - toTeam
        );
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            (block.timestamp)
        );
    }

    function _addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount
    ) private lockTheSwap {
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function changeSwapbackThreshold(uint256 newValue) public onlyOwner {
        _swapbackThreshold = newValue;
    }

    function changeMarketingWallet(address newWallet) public onlyOwner {
        marketingWallet = newWallet;
    }

    function changeDevWallet(address newWallet) public onlyOwner {
        devWallet = newWallet;
    }

    function changeTeamWallet(address newWallet) public onlyOwner {
        teamWallet = newWallet;
    }

    function excludeFromFees(address[] calldata addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _isExcludedFromFee[addresses[i]] = true;
        }
    }

    function includeInFees(address[] calldata addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _isExcludedFromFee[addresses[i]] = false;
        }
    }

    function setTaxes(
        uint256 _feeDev,
        uint256 _feeLiquidity,
        uint256 _feeMarketing,
        uint256 _feeTeam
    ) public onlyOwner {
        feeDev = _feeDev;
        feeLiquidity = _feeLiquidity;
        feeMarketing = _feeMarketing;
        feeTeam = _feeTeam;
        taxTotal = _feeDev + _feeLiquidity + _feeMarketing + _feeTeam;
    }

    function setMaxWalletSize(uint256 _maxWalletSize) public onlyOwner {
        maxWalletSize = _maxWalletSize;
    }

    function saveETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function saveTokens(
        IERC20 tokenAddress,
        address walletAddress,
        uint256 amt
    ) external onlyOwner {
        uint256 bal = tokenAddress.balanceOf(address(this));
        SafeERC20.safeTransfer(
            tokenAddress,
            walletAddress,
            amt > bal ? bal : amt
        );
    }

    receive() external payable {}
}