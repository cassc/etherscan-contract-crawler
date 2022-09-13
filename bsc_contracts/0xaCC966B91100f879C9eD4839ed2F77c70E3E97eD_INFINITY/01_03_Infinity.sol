//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Ownable.sol";

interface ISwapper {
    function buy(address recipient) external payable;
    function sell(address recipient) external;
}

contract INFINITY is IERC20, Ownable {

    // total supply
    uint256 private _totalSupply;

    // token data
    string private constant _name = "Infinity MDB";
    string private constant _symbol = "INF-MDB";
    uint8  private constant _decimals = 18;

    // balances
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    // Taxation on transfers
    uint256 public buyFee             = 300;
    uint256 public sellFee            = 300;
    uint256 public transferFee        = 500;
    uint256 public constant TAX_DENOM = 10000;

    // Max Transaction Limit
    uint256 public max_sell_transaction_limit;
    uint256 public MAX_WALLET;

    // permissions
    struct Permissions {
        bool isFeeExempt;
        bool isLiquidityPool;
        bool isBlacklisted;
        bool isMaxWalletExempt;
        bool isMaxSellExempt;
        bool isTradePausedExempt;
    }
    mapping ( address => Permissions ) public permissions;

    // Fee Recipients
    address public sellFeeRecipient;
    address public buyFeeRecipient;
    address public transferFeeRecipient;

    // Trading Paused
    bool public tradingPaused;

    // Swapper
    address public infinitySwapper;

    // events
    event TradingPaused();
    event TradingResumed();
    event SetBuyFeeRecipient(address recipient);
    event SetSellFeeRecipient(address recipient);
    event SetInfinitySwapper(address newSwapper);
    event SetTransferFeeRecipient(address recipient);
    event SetBlacklist(address addr, bool isBlacklisted);
    event SetFeeExemption(address account, bool isFeeExempt);
    event SetAutomatedMarketMaker(address account, bool isMarketMaker);
    event SetFees(uint256 buyFee, uint256 sellFee, uint256 transferFee);

    constructor() {

        // set initial starting supply
        _totalSupply = 10**7 * 10**_decimals;

        // set max wallet size
        MAX_WALLET = _totalSupply;

        // max transaction
        max_sell_transaction_limit = _totalSupply / 100;

        // exempt sender for tax-free initial distribution
        permissions[msg.sender].isFeeExempt = true;
        permissions[msg.sender].isMaxWalletExempt = true;
        permissions[msg.sender].isMaxSellExempt = true;
        permissions[msg.sender].isTradePausedExempt = true;

        // initial supply allocation
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    
    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if (recipient == msg.sender) {
            return _sell(msg.sender, amount);
        } else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(
            _allowances[sender][msg.sender] >= amount,
            'Insufficient Allowance'
        );
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        return _transferFrom(sender, recipient, amount);
    }

    function sell(uint256 amount) external returns (bool) {
        return _sell(msg.sender, amount);
    }

    function buy(address recipient) external payable {
        ISwapper(infinitySwapper).buy{value: msg.value}(recipient);
    }

    function burn(uint256 amount) external returns (bool) {
        return _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external returns (bool) {
        require(
            _allowances[account][msg.sender] >= amount,
            'Insufficient Allowance'
        );
        _allowances[account][msg.sender] = _allowances[account][msg.sender] - amount;
        return _burn(account, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(
            recipient != address(0),
            'Zero Recipient'
        );
        require(
            recipient != address(this),
            'Cannot Send To INFINITY Itself'
        );
        require(
            amount > 0,
            'Zero Amount'
        );
        require(
            amount <= _balances[sender],
            'Insufficient Balance'
        );
        require(
            !permissions[sender].isBlacklisted &&
            !permissions[recipient].isBlacklisted,
            'Blacklisted Address'
        );
        if (!permissions[sender].isTradePausedExempt) {
            require(
                !tradingPaused,
                'Trading Is Paused'
            );
        }
        
        // decrement sender balance
        _balances[sender] = _balances[sender] - amount;
        // fee for transaction
        (uint256 fee, address feeDestination) = getTax(sender, recipient, amount);

        // allocate fee
        if (fee > 0) {
            address feeRecipient = feeDestination == address(0) ? address(this) : feeDestination;
            if (feeRecipient == sellFeeRecipient && !permissions[sender].isMaxSellExempt) {
                require(
                    amount <= max_sell_transaction_limit,
                    'Amount Exceeds Max Transaction Limit'
                );
            }
            _balances[feeRecipient] += fee;
            emit Transfer(sender, feeRecipient, fee);
        }

        // give amount to recipient
        uint256 sendAmount = amount - fee;
        _balances[recipient] = _balances[recipient] + sendAmount;

        // ensure max wallet is protected
        if (!permissions[recipient].isMaxWalletExempt) {
            require(
                _balances[recipient] <= MAX_WALLET,
                'Balance Exceeds Max Wallet Size'
            );
        }

        // emit transfer
        emit Transfer(sender, recipient, sendAmount);
        return true;
    }

    function setMaxSellTransactionLimit(uint256 maxSellTransactionLimit) external onlyOwner {
        require(
            maxSellTransactionLimit >= _totalSupply / 1000,
            'Max Sell Tx Limit Too Low'
        );
        max_sell_transaction_limit = maxSellTransactionLimit;
    }

    function withdraw(address token) external onlyOwner {
        require(token != address(0), 'Zero Address');
        bool s = IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        require(s, 'Failure On Token Withdraw');
    }

    function withdrawBNB() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function setTransferFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), 'Zero Address');
        transferFeeRecipient = recipient;
        permissions[recipient].isFeeExempt = true;
        permissions[recipient].isMaxWalletExempt = true;
        permissions[recipient].isMaxSellExempt = true;
        emit SetTransferFeeRecipient(recipient);
    }

    function setBuyFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), 'Zero Address');
        buyFeeRecipient = recipient;
        permissions[recipient].isFeeExempt = true;
        permissions[recipient].isMaxWalletExempt = true;
        permissions[recipient].isMaxSellExempt = true;
        emit SetBuyFeeRecipient(recipient);
    }

    function setSellFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), 'Zero Address');
        sellFeeRecipient = recipient;
        permissions[recipient].isFeeExempt = true;
        permissions[recipient].isMaxWalletExempt = true;
        permissions[recipient].isMaxSellExempt = true;
        emit SetSellFeeRecipient(recipient);
    }

    function registerAutomatedMarketMaker(address account) external onlyOwner {
        require(account != address(0), 'Zero Address');
        require(!permissions[account].isLiquidityPool, 'Already An AMM');
        permissions[account].isLiquidityPool = true;
        permissions[account].isMaxWalletExempt = true;
        permissions[account].isMaxSellExempt = true;
        emit SetAutomatedMarketMaker(account, true);
    }

    function unRegisterAutomatedMarketMaker(address account) external onlyOwner {
        require(account != address(0), 'Zero Address');
        require(permissions[account].isLiquidityPool, 'Not An AMM');
        permissions[account].isLiquidityPool = false;
        emit SetAutomatedMarketMaker(account, false);
    }

    function setBlacklist(address addr, bool isBlacklisted) external onlyOwner {
        require(addr != address(0), 'Zero Address');
        permissions[addr].isBlacklisted = isBlacklisted;
        emit SetBlacklist(addr, isBlacklisted);
    }

    function pauseTrading() external onlyOwner {
        tradingPaused = true;
        emit TradingPaused();
    }

    function resumeTrading() external onlyOwner {
        tradingPaused = false;
        emit TradingResumed();
    }

    function setInfinitySwapper(address newSwapper) external onlyOwner {
        require(newSwapper != address(0), 'Zero Address');
        infinitySwapper = newSwapper;
        emit SetInfinitySwapper(newSwapper);
    }

    function setFees(uint _buyFee, uint _sellFee, uint _transferFee) external onlyOwner {
        require(
            _buyFee <= 2500,
            'Buy Fee Too High'
        );
        require(
            _sellFee <= 2500,
            'Sell Fee Too High'
        );
        require(
            _transferFee <= 2500,
            'Transfer Fee Too High'
        );

        buyFee = _buyFee;
        sellFee = _sellFee;
        transferFee = _transferFee;

        emit SetFees(_buyFee, _sellFee, _transferFee);
    }

    function setFeeExempt(address account, bool isExempt) external onlyOwner {
        require(account != address(0), 'Zero Address');
        permissions[account].isFeeExempt = isExempt;
        emit SetFeeExemption(account, isExempt);
    }

    function setMaxSellExempt(address account, bool isExempt) external onlyOwner {
        require(account != address(0), 'Zero Address');
        permissions[account].isMaxSellExempt = isExempt;
    }

    function setMaxWalletExempt(address account, bool isExempt) external onlyOwner {
        require(account != address(0), 'Zero Address');
        permissions[account].isMaxWalletExempt = isExempt;
    }
    
    function setMaxWalletSize(uint256 newMaxWallet) external onlyOwner {
        require(
            newMaxWallet >= _totalSupply / 1000,
            'Max Wallet Too Small'
        );
        MAX_WALLET = newMaxWallet;
    }

    function setTradePausedExempt(address user, bool isExempt) external onlyOwner {
        permissions[user].isTradePausedExempt = isExempt;
    }

    function getTax(address sender, address recipient, uint256 amount) public view returns (uint256, address) {
        if ( permissions[sender].isFeeExempt || permissions[recipient].isFeeExempt ) {
            return (0, address(0));
        }
        return permissions[sender].isLiquidityPool ? 
               ((amount * buyFee) / TAX_DENOM, buyFeeRecipient) : 
               permissions[recipient].isLiquidityPool ? 
               ((amount * sellFee) / TAX_DENOM, sellFeeRecipient) :
               ((amount * transferFee) / TAX_DENOM, transferFeeRecipient);
    }

    function _burn(address account, uint256 amount) internal returns (bool) {
        require(
            account != address(0),
            'Zero Address'
        );
        require(
            amount > 0,
            'Zero Amount'
        );
        require(
            amount <= balanceOf(account),
            'Insufficient Balance'
        );
        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
        return true;
    }

    function _sell(address recipient, uint256 amount) internal returns (bool) {
        require(
            !permissions[recipient].isBlacklisted,
            'Blacklisted User'
        );
        require(
            amount > 0,
            'Zero Amount'
        );
        require(
            amount <= _balances[recipient],
            'Insufficient Balance'
        );

        // Allocate Balance To Swapper
        _balances[recipient] -= amount;
        _balances[infinitySwapper] += amount;
        emit Transfer(recipient, infinitySwapper, amount);

        // Sell From Swapper
        ISwapper(infinitySwapper).sell(recipient);
        return true;
    }

    receive() external payable {
        ISwapper(infinitySwapper).buy{value: msg.value}(msg.sender);
    }
}