// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract APAD is ERC20, Ownable {
    using SafeMath for uint256;

    modifier lockSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier liquidityAdd {
        _inLiquidityAdd = true;
        _;
        _inLiquidityAdd = false;
    }

    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether;
    uint256 public constant BPS_DENOMINATOR = 10_000;

    /// @notice Max transfer rate in BPS. Initialized at 0.4%
    uint256 public maxTransfer;
    /// @notice Cooldown in seconds
    uint256 public cooldown = 20;
    /// @notice Buy tax0 in BPS
    uint256 public buyTax0 = 1125;
    /// @notice Sell tax0 in BPS
    uint256 public sellTax0 = 1875;
    /// @notice Buy tax1 in BPS
    uint256 public buyTax1 = 375;
    /// @notice Sell tax1 in BPS
    uint256 public sellTax1 = 625;

    /// @notice Contract APAD balance threshold before `_swap` is invoked
    uint256 public minTokenBalance = 1000 ether;
    bool public swapFees = true;

    /// @notice tokens that are allocated for tax0 tax
    uint256 public totalTax0;
    /// @notice tokens that are allocated for tax1 tax
    uint256 public totalTax1;

    /// @notice address that tax0 is sent to
    address payable public tax0Wallet;
    /// @notice address that tax1 is sent to
    address payable public tax1Wallet;

    uint256 internal _totalSupply = 0;
    IUniswapV2Router02 internal _router = IUniswapV2Router02(address(0));
    address internal _pair;
    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;
    bool public tradingActive = false;

    mapping(address => uint256) private _balances;
    mapping(address => bool) public taxExcluded;
    mapping(address => uint256) public lastBuy;

    event Tax0WalletChanged(address previousWallet, address nextWallet);
    event Tax1WalletChanged(address previousWallet, address nextWallet);
    event BuyTax0Changed(uint256 previousTax, uint256 nextTax);
    event SellTax0Changed(uint256 previousTax, uint256 nextTax);
    event BuyTax1Changed(uint256 previousTax, uint256 nextTax);
    event SellTax1Changed(uint256 previousTax, uint256 nextTax);
    event MinTokenBalanceChanged(uint256 previousMin, uint256 nextMin);
    event Tax0Rescued(uint256 amount);
    event Tax1Rescued(uint256 amount);
    event TradingActiveChanged(bool enabled);
    event TaxExclusionChanged(address user, bool taxExcluded);
    event MaxTransferChanged(uint256 previousMax, uint256 nextMax);
    event SwapFeesChanged(bool enabled);
    event CooldownChanged(uint256 previousCooldown, uint256 nextCooldown);

    constructor(
        address _uniswapFactory,
        address _uniswapRouter,
        uint256 _maxTransfer,
        address payable _tax0Wallet,
        address payable _tax1Wallet
    ) ERC20("Alpha Pad", "APAD") Ownable() {
        taxExcluded[owner()] = true;
        taxExcluded[address(0)] = true;
        taxExcluded[_tax0Wallet] = true;
        taxExcluded[_tax1Wallet] = true;
        taxExcluded[address(this)] = true;

        maxTransfer = _maxTransfer;
        tax0Wallet = _tax0Wallet;
        tax1Wallet = _tax1Wallet;

        _router = IUniswapV2Router02(_uniswapRouter);
        IUniswapV2Factory uniswapContract = IUniswapV2Factory(_uniswapFactory);
        _pair = uniswapContract.createPair(address(this), _router.WETH());
    }

    /// @notice Change the address of the buyback wallet
    /// @param _tax0Wallet The new address of the buyback wallet
    function setTax0Wallet(address payable _tax0Wallet) external onlyOwner() {
        emit Tax0WalletChanged(tax0Wallet, _tax0Wallet);
        tax0Wallet = _tax0Wallet;
    }

    /// @notice Change the address of the tax1 wallet
    /// @param _tax1Wallet The new address of the tax1 wallet
    function setTax1Wallet(address payable _tax1Wallet) external onlyOwner() {
        emit Tax1WalletChanged(tax1Wallet, _tax1Wallet);
        tax1Wallet = _tax1Wallet;
    }

    /// @notice Change the buy tax0 rate
    /// @param _buyTax0 The new buy tax0 rate
    function setBuyTax0(uint256 _buyTax0) external onlyOwner() {
        require(_buyTax0 <= BPS_DENOMINATOR, "_buyTax0 cannot exceed BPS_DENOMINATOR");
        emit BuyTax0Changed(buyTax0, _buyTax0);
        buyTax0 = _buyTax0;
    }

    /// @notice Change the sell tax0 rate
    /// @param _sellTax0 The new sell tax0 rate
    function setSellTax0(uint256 _sellTax0) external onlyOwner() {
        require(_sellTax0 <= BPS_DENOMINATOR, "_sellTax0 cannot exceed BPS_DENOMINATOR");
        emit SellTax0Changed(sellTax0, _sellTax0);
        sellTax0 = _sellTax0;
    }

    /// @notice Change the buy tax1 rate
    /// @param _buyTax1 The new tax1 rate
    function setBuyTax1(uint256 _buyTax1) external onlyOwner() {
        require(_buyTax1 <= BPS_DENOMINATOR, "_buyTax1 cannot exceed BPS_DENOMINATOR");
        emit BuyTax1Changed(buyTax1, _buyTax1);
        buyTax1 = _buyTax1;
    }

    /// @notice Change the buy tax1 rate
    /// @param _sellTax1 The new tax1 rate
    function setSellTax1(uint256 _sellTax1) external onlyOwner() {
        require(_sellTax1 <= BPS_DENOMINATOR, "_sellTax1 cannot exceed BPS_DENOMINATOR");
        emit SellTax1Changed(sellTax1, _sellTax1);
        sellTax1 = _sellTax1;
    }

    /// @notice Change the minimum contract APAD balance before `_swap` gets invoked
    /// @param _minTokenBalance The new minimum balance
    function setMinTokenBalance(uint256 _minTokenBalance) external onlyOwner() {
        emit MinTokenBalanceChanged(minTokenBalance, _minTokenBalance);
        minTokenBalance = _minTokenBalance;
    }

    /// @notice Change the cooldown for buys
    /// @param _cooldown The new cooldown in seconds
    function setCooldown(uint256 _cooldown) external onlyOwner() {
        emit CooldownChanged(cooldown, _cooldown);
        cooldown = _cooldown;
    }

    /// @notice Rescue APAD from the tax0 amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of APAD to rescue
    /// @param _recipient The recipient of the rescued APAD
    function rescueTax0Tokens(uint256 _amount, address _recipient) external onlyOwner() {
        require(_amount <= totalTax0, "Amount cannot be greater than totalTax0");
        _rawTransfer(address(this), _recipient, _amount);
        emit Tax0Rescued(_amount);
        totalTax0 -= _amount;
    }

    /// @notice Rescue APAD from the tax1 amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of APAD to rescue
    /// @param _recipient The recipient of the rescued APAD
    function rescueTax1Tokens(uint256 _amount, address _recipient) external onlyOwner() {
        require(_amount <= totalTax1, "Amount cannot be greater than totalTax1");
        _rawTransfer(address(this), _recipient, _amount);
        emit Tax1Rescued(_amount);
        totalTax1 -= _amount;
    }

    function addLiquidity(uint256 tokens) external payable onlyOwner() liquidityAdd {
        _mint(address(this), tokens);
        _approve(address(this), address(_router), tokens);

        _router.addLiquidityETH{value: msg.value}(
            address(this),
            tokens,
            0,
            0,
            owner(),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    /// @notice Enables or disables trading on Uniswap
    function setTradingActive(bool _tradingActive) external onlyOwner {
        tradingActive = _tradingActive;
        emit TradingActiveChanged(_tradingActive);
    }

    /// @notice Updates tax exclusion status
    /// @param _account Account to update the tax exclusion status of
    /// @param _taxExcluded If true, exclude taxes for this user
    function setTaxExcluded(address _account, bool _taxExcluded) public onlyOwner() {
        taxExcluded[_account] = _taxExcluded;
        emit TaxExclusionChanged(_account, _taxExcluded);
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function _addBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] + amount;
    }

    function _subtractBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] - amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (taxExcluded[sender] || taxExcluded[recipient]) {
            _rawTransfer(sender, recipient, amount);
            return;
        }

        uint256 maxTxAmount = totalSupply().mul(maxTransfer).div(BPS_DENOMINATOR);
        require(amount <= maxTxAmount || _inLiquidityAdd || _inSwap || recipient == address(_router), "Exceeds max transaction amount");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokenBalance;

        if(contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        if (
            overMinTokenBalance &&
            !_inSwap &&
            sender != _pair &&
            swapFees
        ) {
            _swap(contractTokenBalance);
        }

        uint256 send = amount;
        uint256 tax0;
        uint256 tax1;
        if (sender == _pair) {
            require(tradingActive, "Trading is not yet active");
            if (cooldown > 0) {
                require(lastBuy[recipient] + cooldown <= block.timestamp, "Cooldown still active");
                lastBuy[recipient] = block.timestamp;
            }
            (
                send,
                tax0,
                tax1
            ) = _getTaxAmounts(amount, true);
        } else if (recipient == _pair) {
            require(tradingActive, "Trading is not yet active");
            (
                send,
                tax0,
                tax1
            ) = _getTaxAmounts(amount, false);
        }
        _rawTransfer(sender, recipient, send);
        _takeTaxes(sender, tax0, tax1);
    }

    /// @notice Perform a Uniswap v2 swap from APAD to ETH and handle tax distribution
    /// @param amount The amount of APAD to swap in wei
    /// @dev `amount` is always <= this contract's ETH balance. Calculate and distribute taxes
    function _swap(uint256 amount) internal lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), amount);

        uint256 contractEthBalance = address(this).balance;

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 tradeValue = address(this).balance - contractEthBalance;

        uint256 totalTaxes = totalTax0.add(totalTax1);
        uint256 tax0Amount = amount.mul(totalTax0).div(totalTaxes);
        uint256 tax1Amount = amount.mul(totalTax1).div(totalTaxes);

        uint256 tax0Eth = tradeValue.mul(totalTax0).div(totalTaxes);
        uint256 tax1Eth = tradeValue.mul(totalTax1).div(totalTaxes);

        if (tax0Eth > 0) {
            tax0Wallet.transfer(tax0Eth);
        }
        if (tax1Eth > 0) {
            tax1Wallet.transfer(tax1Eth);
        }
        totalTax0 = totalTax0.sub(tax0Amount);
        totalTax1 = totalTax1.sub(tax1Amount);
    }

    function swapAll() external {
        uint256 maxTxAmount = totalSupply().mul(maxTransfer).div(BPS_DENOMINATOR);
        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= maxTxAmount)
        {
            contractTokenBalance = maxTxAmount;
        }

        if (
            !_inSwap
        ) {
            _swap(contractTokenBalance);
        }
    }

    function withdrawAll() external onlyOwner() {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Transfers APAD from an account to this contract for taxes
    /// @param _account The account to transfer APAD from
    /// @param _tax0Amount The amount of tax0 tax to transfer
    /// @param _tax1Amount The amount of tax1 tax to transfer
    function _takeTaxes(
        address _account,
        uint256 _tax0Amount,
        uint256 _tax1Amount
   ) internal {
        require(_account != address(0), "taxation from the zero address");

        uint256 totalAmount = _tax0Amount.add(_tax1Amount);
        _rawTransfer(_account, address(this), totalAmount);
        totalTax0 += _tax0Amount;
        totalTax1 += _tax1Amount;
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount The amount to tax in wei
    /// @return send The raw amount to send
    /// @return tax0 The raw tax0 tax amount
    /// @return tax1 The raw tax1 tax amount
    function _getTaxAmounts(uint256 amount, bool buying)
        internal
        view
        returns (
            uint256 send,
            uint256 tax0,
            uint256 tax1
        )
    {
        if (buying) {
            tax0 = amount.mul(buyTax0).div(BPS_DENOMINATOR);
            tax1 = amount.mul(buyTax1).div(BPS_DENOMINATOR);
        } else {
            tax0 = amount.mul(sellTax0).div(BPS_DENOMINATOR);
            tax1 = amount.mul(sellTax1).div(BPS_DENOMINATOR);
        }
        send = amount.sub(tax0).sub(tax1);
    }

    // modified from OpenZeppelin ERC20
    function _rawTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _subtractBalance(sender, amount);
        }
        _addBalance(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    /// @notice Updates the max amount allowed to transfer
    /// @param _maxTransfer The new max transfer rate
    function setMaxTransfer(uint256 _maxTransfer) external onlyOwner() {
        require(_maxTransfer <= BPS_DENOMINATOR, "_maxTransfer cannot exceed BPS_DENOMINATOR");
        emit MaxTransferChanged(maxTransfer, _maxTransfer);
        maxTransfer = _maxTransfer;
    }

    /// @notice Enable or disable whether swap occurs during `_transfer`
    /// @param _swapFees If true, enables swap during `_transfer`
    function setSwapFees(bool _swapFees) external onlyOwner() {
        swapFees = _swapFees;
        emit SwapFeesChanged(_swapFees);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal override {
        require(_totalSupply.add(amount) <= MAX_SUPPLY, "Max supply exceeded");
        _totalSupply += amount;
        _addBalance(account, amount);
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 amount) external onlyOwner() {
        _mint(account, amount);
    }

    function airdrop(address[] memory accounts, uint256[] memory amounts) external onlyOwner() {
        require(accounts.length == amounts.length, "array lengths must match");

        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    receive() external payable {}
}