/**
 *Submitted for verification at Etherscan.io on 2023-06-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * ============================================
 * ============================================
 * =====                                  =====
 * =====         JOIN OUR TELEGRAM        =====
 * =====  https://t.me/StarlordSlimPortal =====
 * =====                                  =====
 * ============================================
 * ============================================
 */

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

interface IERC20Taxable is IERC20 {
    event ChangeBuyTax(uint256 prevTax, uint256 newTax);
    event ChangeSellTax(uint256 prevTax, uint256 newTax);
    event SetPool(address isNowPool);
    event FailsafeTokenSwap(uint256 amount);
    event FailsafeETHTransfer(uint256 amount);

    function setBuyTax(uint8 newTax) external;

    function setSellTax(uint8 newTax) external;

    function setPool(address addr) external;

    function isPool(address addr) external view returns (bool);

    function failsafeTokenSwap(uint256 amount) external;

    function failsafeETHtransfer() external;
}

contract ERC20 is IERC20Taxable, Context {
    /**
     * =====================
     * =====================
     * =====           =====
     * ===== Variables =====
     * =====           =====
     * =====================
     * =====================
     */

    bool private _trading;

    // States
    bool private _swapping;

    // Mappings
    mapping(address => bool) private _isPool;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // ERC20
    uint256 private _totalSupply = 10**12 * 10**9; // 1 trillion
    string private constant _name = "Starlord Slim";
    string private constant _symbol = "$SLIM";
    uint8 private constant _decimals = 9;

    // Tax
    uint8 private _buyTax = 3;
    uint8 private _sellTax = 3;

    // Addresses
    address private immutable _lp;
    address payable private immutable _vault =
        payable(0x9B912ac80494b381a96dDa900B6824Ac7999E926);
    address payable private immutable _authorized;
    address private constant _uniRouter =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 private UniV2Router;

    constructor(address authorized) {
        require(
            authorized != address(0),
            "$SLIM: cannot assign privilege to zero address"
        );
        _lp = authorized;
        _balances[authorized] = _totalSupply;
        UniV2Router = IUniswapV2Router02(_uniRouter);
        _authorized = payable(authorized);
    }

    modifier onlyAuthorized() {
        require(_msgSender() == _authorized, "$SLIM: unauthorized");
        _;
    }

    modifier lockSwap() {
        _swapping = true;
        _;
        _swapping = false;
    }

    /**
     * =====================
     * =====================
     * =====           =====
     * =====   ERC20   =====
     * =====           =====
     * =====================
     * =====================
     */
    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(
            _allowances[sender][_msgSender()] >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer exceeds balance");
        require(amount > 0, "$SLIM: cannot transfer zero");
        require(
            !(_isPool[sender] && _isPool[recipient]),
            "$SLIM: cannot transfer pool to pool"
        );

        if (!_trading) {
            require(sender == _lp, "$SLIM: trading disabled");
        }

        unchecked {
            _balances[sender] -= amount;
        }

        uint256 taxedAmount = amount;
        uint256 tax = 0;

        if (
            _isPool[sender] == true &&
            recipient != _lp &&
            recipient != _uniRouter
        ) {
            tax = (amount * _buyTax) / 100;
            taxedAmount = amount - tax;
            _balances[address(this)] += tax;
        }
        if (
            _isPool[recipient] == true && sender != _lp && sender != _uniRouter
        ) {
            tax = (amount * _sellTax) / 100;
            taxedAmount = amount - tax;
            _balances[address(this)] += tax;

            if (_balances[address(this)] > 100 * 10**9 && !_swapping) {
                uint256 _swapAmount = _balances[address(this)];
                if (_swapAmount > (amount * 40) / 100)
                    _swapAmount = (amount * 40) / 100;
                _tokensToETH(_swapAmount);
            }
        }

        _balances[recipient] += taxedAmount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * =====================
     * =====================
     * =====           =====
     * =====    Tax    =====
     * =====           =====
     * =====================
     * =====================
     */
    function setBuyTax(uint8 newTax) external override onlyAuthorized {
        require(newTax <= 10, "$SLIM: tax cannot exceed 10%");
        emit ChangeBuyTax(_buyTax, newTax);
        _buyTax = newTax;
    }

    function setSellTax(uint8 newTax) external override onlyAuthorized {
        require(newTax <= 10, "$SLIM: tax cannot exceed 10%");
        emit ChangeSellTax(_sellTax, newTax);
        _sellTax = newTax;
    }

    function setPool(address addr) external override onlyAuthorized {
        require(addr != address(0), "$SLIM: zero address cannot be pool");
        _isPool[addr] = true;
        emit SetPool(addr);
    }

    function isPool(address addr) external view override returns (bool) {
        return _isPool[addr];
    }

    /**
     * =====================
     * =====================
     * =====           =====
     * =====  Utility  =====
     * =====           =====
     * =====================
     * =====================
     */
    function _transferETH(uint256 amount, address payable _to) private {
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function _tokensToETH(uint256 amount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniV2Router.WETH();

        _approve(address(this), _uniRouter, amount);
        UniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        if (address(this).balance > 0) {
            _transferETH(address(this).balance, _vault);
        }
    }

    function failsafeTokenSwap(uint256 amount)
        external
        override
        onlyAuthorized
    {
        _tokensToETH(amount);
        emit FailsafeTokenSwap(amount);
    }

    function failsafeETHtransfer() external override onlyAuthorized {
        emit FailsafeETHTransfer(address(this).balance);
        (bool sent, ) = _msgSender().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function activateTrading() external onlyAuthorized {
        require(!_trading, "$SLIM: trading already enabled");
        _trading = true;
    }

    receive() external payable {}

    fallback() external payable {}
}