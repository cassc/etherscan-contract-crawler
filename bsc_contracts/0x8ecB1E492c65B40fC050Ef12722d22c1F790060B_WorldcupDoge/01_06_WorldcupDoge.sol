// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IUniswapRouter.sol";
import "./interface/IUniswapFactory.sol";


contract WorldcupDoge is Context, IERC20, Ownable {
    uint private constant PRECISION = 10**18;

    address public marketFeeAddress;

    IUniswapRouter public pancakeRouter;
    address public pancakePair;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    bool inSwapAndLiquify;

    uint public marketFee = 0;
    uint public liquidityFee = 0;

    uint256 private feeThreshold = 1000 * PRECISION;

    bool private enableSwapAndLiquify = true;
    bool private removeFee = false;

    mapping(address => bool) private blacklist;
    mapping(address => bool) private excludedFromFee;

    constructor(address pancake, address _marketFeeAddress) {
        _balances[_msgSender()] =  1000000000 * PRECISION;
        _totalSupply = 1000000000 * PRECISION;
        _name =  "Worldcup Doge";
        _symbol  =  "Worldcup Doge";
        pancakeRouter = IUniswapRouter(pancake);
        pancakePair = IUniswapFactory(pancakeRouter.factory())
        .createPair(address(this), pancakeRouter.WETH());

        _approve(address(this), address(pancakeRouter), type(uint).max);

        marketFeeAddress = _marketFeeAddress;
        excludedFromFee[_msgSender()] = true;
        excludedFromFee[address(this)] = true;
        excludedFromFee[marketFeeAddress] = true;
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function swapTokensForEth(uint256 tokenAmount, address receiver) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }

    receive() external payable {}

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0),
            block.timestamp
        );
    }

    function setEnableSwapAndLiquify(bool _enable) external onlyOwner {
        enableSwapAndLiquify =  _enable;
    }

    function setZeroFee(bool _b) external onlyOwner {
        removeFee =  _b;
    }

    function addWhiteList(address _a) external onlyOwner {
        excludedFromFee[_a] = true;
    }

    function addBlackList(address _a) external onlyOwner {
        blacklist[_a] = true;
    }

    function removeBlackList(address _a) external onlyOwner {
        blacklist[_a] = false;
    }

    function swapAndLiquify() private lockTheSwap {
        uint256 half = liquidityFee / 2;
        uint256 otherHalf = liquidityFee - half;
        liquidityFee = 0;

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(half, address(this));
        uint newBalance = address(this).balance - initialBalance;
        addLiquidity(otherHalf, newBalance);

        uint256 _fee = marketFee;
        marketFee = 0;
        swapTokensForEth(_fee, marketFeeAddress);
    }


    function deduction(address from, address to, uint amount) private returns(uint){
        if(removeFee) {
            return amount;
        }
        if(excludedFromFee[from] || excludedFromFee[to]) {
            return amount;
        }
        if(to != pancakePair && from != pancakePair) {
            return amount;
        }
        uint ramount = amount;
        marketFee =  (amount * 5 / 100) + marketFee;
        liquidityFee = (amount * 1 / 100) + liquidityFee;
        ramount = amount - (amount * 6 / 100);
        return ramount;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(!blacklist[from], "forbidden");
        require(amount > 10000, "too small");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

        if (
            enableSwapAndLiquify &&
            marketFee >= feeThreshold &&
            !inSwapAndLiquify &&
            from != pancakePair
        ) {
            swapAndLiquify();
        }
       if(from != pancakePair) {
           amount = amount * 9999 / 10000;
       }

       uint ramount = deduction(from, to, amount);
       _balances[from] -= amount;
       _balances[to] += ramount;
       _balances[address(this)] =  _balances[address(this)] + (amount - ramount);
       emit Transfer(from, to, ramount);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view virtual returns (uint256) {
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
}