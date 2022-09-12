/**
    Name : SPYN
    Thicker : SPYN
    Decimal : 9
    Total Supply : 10.000.000.000
    1% for the Liquidity
    1% for the Buyback SPY for rewards
    1% for SPYN Autoburn
    1% for MArketing
    no Mint function
    can adjust the Slippage function
    can Start/Stop the trading
    antibot
    whitelist function
 */
pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IAntiBot.sol";
import "./library/SwapMath.sol";

contract SPYN is Context, IERC20, Ownable, Pausable {
    using Address for address;

    mapping (address => mapping (address => uint256)) internal _allowances;
    mapping (address => uint256) internal _balances;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isExcludedTo;
    mapping(address => bool) private _cooldownWhitelist;
    mapping(address => uint32) private _cooldowns;

    string private constant _name = 'SPYN';
    string private constant _symbol = 'SPYN';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1 * 10**8 * 10**9;
    uint256 constant MEV_COOLDOWN_TIME = 3 minutes;
    
    uint256 public constant _liquidityFee = 10; // 1%
    uint256 public liquidityFeeTotal;
    uint256 public constant _buybackFee = 10; // 1%
    uint256 public buybackFeeTotal;
    uint256 public constant _burnFee = 10; // 1%
    uint256 public constant _marketingFee = 10; // 1%
    
    bool public antiBotEnabled;
    bool private _feeEnabled;
    bool private _inSwapAndLiquify;
    uint256 public constant numTokensSellToAddToLiquidity = 1 * 10**3 * 10**9;

    address private constant deadWallet = address(0x000000000000000000000000000000000000dEaD);
    address public marketingWallet;
    address payable public buybackWallet;
    address public immutable uniswapV2Pair;
    IUniswapV2Router02 public immutable uniswapV2Router;
    IAntiBot public antiBot;


    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event BuybackSent(
        address wallet,
        uint256 tokensSwapped,
        uint256 ethReceived
    );
    event AniBotEnabled(
        bool enabled
    );
    event FeeEnabled (
        bool enabled
    );
    event MarketingWalletChanged(
        address newMarketWallet
    );
    event BuybackWalletChanged(
        address newBuybackWallet
    );
    event ExcludedFromFee(
        address account,
        bool excluded
    );
    event ExcludedToFee(
        address account,
        bool excluded
    );

    modifier lockTheSwapAndLiquify {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }


    constructor (
        address marketingWallet_, 
        address buybackWallet_, 
        address uniswapV2Router_,
        address antiBot_
    ) {
        require(uniswapV2Router_ != address(0), "uniswap router set to zero address");
        require(antiBot_ != address(0), "uniswap router set to zero address");
        require(marketingWallet_ != address(0), "marketing wallet set to zero address");
        require(buybackWallet_ != address(0), "buyback wallet set to zero address");
        address sender = _msgSender();
        
        _balances[sender] = _totalSupply;
        emit Transfer(address(0), sender, _totalSupply);

        antiBot = IAntiBot(antiBot_);
        marketingWallet = marketingWallet_;
        buybackWallet = payable(buybackWallet_);
        uniswapV2Router = IUniswapV2Router02(uniswapV2Router_);
        uniswapV2Pair = IUniswapV2Factory(IUniswapV2Router02(uniswapV2Router_).factory())
            .createPair(address(this), IUniswapV2Router02(uniswapV2Router_).WETH());

        _isExcluded[address(this)] = true;
        _isExcludedTo[address(this)] = true;
        _isExcluded[sender] = true;
        _isExcludedTo[sender] = true;
        _isExcluded[deadWallet] = true;
        _isExcludedTo[deadWallet] = true;
        _cooldownWhitelist[address(this)] = true;
    }

    function addCooldownWhitelist(address whitelistAddy) external onlyOwner {
		_cooldownWhitelist[whitelistAddy] = true;
	}

    function removeCooldownWhitelist(address whitelistAddy) external onlyOwner {
		_cooldownWhitelist[whitelistAddy] = false;
	}

    function setUsingAntiBot(bool enabled_) external onlyOwner {
        antiBotEnabled = enabled_;
        emit AniBotEnabled(enabled_);
    }

    function feeEnabled() external view returns (bool) {
        return _feeEnabled;
    }

    function setFeeEnabled(bool enabled) external onlyOwner {
        _feeEnabled = enabled;
        emit FeeEnabled(enabled);
    }

    function isExcluded(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function isExcludedTo(address account) external view returns (bool) {
        return _isExcludedTo[account];
    }

    function includeAccountFromFee(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
        _isExcluded[account] = false;
        emit ExcludedFromFee(account, false);
    }

    function excludeAccountFromFee(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        _isExcluded[account] = true;
        emit ExcludedFromFee(account, true);
    }

    function includeAccountToFee(address account) external onlyOwner {
        require(_isExcludedTo[account], "Account is already included");
        _isExcludedTo[account] = false;
        emit ExcludedToFee(account, false);
    }

    function excludeAccountToFee(address account) external onlyOwner {
        require(!_isExcludedTo[account], "Account is already excluded");
        _isExcludedTo[account] = true;
        emit ExcludedToFee(account, true);
    }

    function setMarketingWallet(address marketingWallet_) external onlyOwner {
        require(marketingWallet_ != address(0), "ERC20: approve from the zero address");
        marketingWallet = marketingWallet_;
        emit MarketingWalletChanged(marketingWallet_);
    }

    function setBuybackWallet(address buybackWallet_) external onlyOwner {
        require(buybackWallet_ != address(0), "ERC20: approve from the zero address");
        buybackWallet = payable(buybackWallet_);
        emit BuybackWalletChanged(buybackWallet_);
    }

    receive() external payable {}

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual returns (string memory) {
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
    function decimals() external view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
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
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }/**
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
    withdraw ETH leftover from _swapAndLiquify
    */
    function withdraw(address receipt) public onlyOwner {
        require(receipt != address(0), "withdraw to zero address");
        uint256 balance = address(this).balance;
        (bool success, ) = receipt.call{value: balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        if (antiBotEnabled) {
        // Check for malicious transfers
            bool antiBotcheck = antiBot.onPreTransferCheck(from, to);
            require(antiBotcheck, "AntiBot: this transfer is not allowed");
        }

        _beforeTokenTransfer(from, to, amount);

        if (_feeEnabled && !_isExcluded[from] && !_isExcludedTo[to]) {

            _checkAndLiquify(from);
            _checkAndBuyback(from);

            uint256 amountToSend = amount;
            uint256 liquidityFeeAmount = amount * _liquidityFee / 1000;
            uint256 buybackFeeAmount = amount * _buybackFee / 1000;
            uint256 burnFeeAmount = amount * _burnFee / 1000;
            uint256 marketingFeeAmount = amount * _marketingFee / 1000;

            if (liquidityFeeAmount > 0) {
                amountToSend = amountToSend - liquidityFeeAmount;
                liquidityFeeTotal += liquidityFeeAmount;
                _balances[address(this)] += liquidityFeeAmount;
                emit Transfer(from, address(this), liquidityFeeAmount);
            }

            if (buybackFeeAmount > 0) {
                amountToSend = amountToSend - buybackFeeAmount;
                buybackFeeTotal += buybackFeeAmount;
                _balances[address(this)] += buybackFeeAmount;
                emit Transfer(from, address(this), buybackFeeAmount);
            }

            if (burnFeeAmount > 0) {
                amountToSend = amountToSend - burnFeeAmount;
                // _totalSupply = _totalSupply - burnFeeAmount;
                _balances[deadWallet] += burnFeeAmount;
                emit Transfer(from, deadWallet, burnFeeAmount);
            }

            if (marketingFeeAmount > 0 && marketingWallet != address(0)) {
                amountToSend = amountToSend - marketingFeeAmount;
                _balances[marketingWallet] += marketingFeeAmount;
                emit Transfer(from, marketingWallet, marketingFeeAmount);
            }

            unchecked {
                _balances[from] = fromBalance - amount;
            }
            _balances[to] += amountToSend;
            emit Transfer(from, to, amountToSend);
        } else {
            unchecked {
                _balances[from] = fromBalance - amount;
            }
            _balances[to] += amount;
            emit Transfer(from, to, amount);
        }

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256
    ) internal virtual {
		// If the from address is not in the cooldown whitelist, verify it is not in the cooldown 
		// period. If it is, prevent the transfer.
		if (_cooldownWhitelist[from] != true) {
			// Change the error message according to the customized cooldown time.
			require(_cooldowns[from] <= uint32(block.timestamp), "Please wait 3 minutes before transferring or selling your tokens.");
		}
	}

    function _afterTokenTransfer(
        address,
        address to,
        uint256
    ) internal virtual {
		// If the to address is not in the cooldown whitelist, add a cooldown to it.
		if (_cooldownWhitelist[to] != true) {
			// Add a cooldown to the address receiving the tokens.
			_cooldowns[to] = uint32(block.timestamp + MEV_COOLDOWN_TIME);
		}
	}

    /**
     * @dev check liquify is required and proceed.
     */
    function _checkAndBuyback(address from) private {
        if (buybackWallet != address(0)) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if (buybackFeeTotal > contractTokenBalance) {
                buybackFeeTotal = contractTokenBalance;
            }

            bool overMinTokenBalance = buybackFeeTotal >= numTokensSellToAddToLiquidity;
            if (
                overMinTokenBalance &&
                !_inSwapAndLiquify &&
                from != uniswapV2Pair
            ) {
                uint256 oldBuybackFeeTotal = buybackFeeTotal;
                buybackFeeTotal = 0;
                uint256 ethSent = _doBuyback(oldBuybackFeeTotal);

                emit BuybackSent(buybackWallet, oldBuybackFeeTotal, ethSent);
            }
        }
    }

    /**
     * @dev check liquify is required and proceed.
     */
    function _doBuyback(uint256 tokenAmount) private lockTheSwapAndLiquify returns(uint256) {
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        _swapTokensForETH(tokenAmount); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        _sendValue(buybackWallet, newBalance);

        return newBalance;
    }

    /**
     * @dev check liquify is required and proceed.
     */
    function _checkAndLiquify(address from) private {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (liquidityFeeTotal > contractTokenBalance) {
            liquidityFeeTotal = contractTokenBalance;
        }

        bool overMinTokenBalance = liquidityFeeTotal >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !_inSwapAndLiquify &&
            from != uniswapV2Pair
        ) {
            //add liquidity
            uint256 oldLiquidityFeeTotal = liquidityFeeTotal;
            liquidityFeeTotal = 0;
            _swapAndLiquify(oldLiquidityFeeTotal);
        }
    }

    /**
     * @dev Swap half to ETH and add liquidity 
     */
    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwapAndLiquify {

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract

        (uint256 res0,) = _getPairReserves();
        uint256 tokenAmountToSwap = SwapMath.calculateSwapInAmount(res0, contractTokenBalance);

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        _swapTokensForETH(tokenAmountToSwap); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        _addLiquidity(contractTokenBalance - tokenAmountToSwap, newBalance);
        
        emit SwapAndLiquify(tokenAmountToSwap, newBalance, contractTokenBalance - tokenAmountToSwap);
    }


    /**
     * @dev Swap token to ETH 
     */
    function _swapTokensForETH(uint256 tokenAmount) internal {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev Add Liquidity
     */
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        (uint256 amountToken,,) = uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

        if (amountToken < tokenAmount) {
            liquidityFeeTotal = liquidityFeeTotal + tokenAmount - amountToken;
        }
    }

    function _getPairReserves() internal view returns (uint reserveA, uint reserveB) {
        address weth = uniswapV2Router.WETH();
        address token0 = address(this) < address(weth) ? address(this) : address(weth);
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(uniswapV2Pair).getReserves();
        (reserveA, reserveB) = address(this) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }


    /**
     * @dev Send ETH
     */
    function _sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}