// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interfaces/IWhitelist.sol";
import "./interfaces/IReflectable.sol";

contract RETRO is ERC20, Ownable, IReflectable {
    using SafeMath for uint256;

    modifier lockSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier liquidityAdd() {
        _inLiquidityAdd = true;
        _;
        _inLiquidityAdd = false;
    }

    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether;
    uint256 public constant BPS_DENOMINATOR = 10_000;

    /// @notice Max buy amount in wei
    uint256 public buyLimit;
    /// @notice Cooldown in seconds
    uint256 public cooldown = 60;

    /// @notice Buy tax0 in BPS
    uint256 public buyTax0 = 1300;
    /// @notice Sell tax0 in BPS
    uint256 public sellTax0 = 2300;
    /// @notice Buy tax1 in BPS
    uint256 public buyTax1 = 100;
    /// @notice Sell tax1 in BPS
    uint256 public sellTax1 = 100;
    /// @notice Buy tax2 in BPS
    uint256 public buyTax2 = 100;
    /// @notice Sell tax2 in BPS
    uint256 public sellTax2 = 100;
    /// @notice Buy reflection tax in BPS
    uint256 public buyReflectionTax = 0;
    /// @notice Sell reflection tax in BPS
    uint256 public sellReflectionTax = 0;

    /// @notice Contract RETRO balance threshold before `_swap` is invoked
    uint256 public minTokenBalance = 1000 ether;
    bool public swapFees = true;

    /// @notice tokens that are allocated for tax0 tax
    uint256 public totalTax0;
    /// @notice tokens that are allocated for tax1 tax
    uint256 public totalTax1;
    /// @notice tokens that are allocated for tax2 tax
    uint256 public totalTax2;

    /// @notice Counter for all reflections collected
    uint256 public reflectionBasis;
    /// @notice Mapping of each user's last reflection basis
    mapping(address => uint256) public lastReflectionBasis;
    /// @notice Mapping of each user's owed reflections
    mapping(address => uint256) public override reflectionOwed;

    /// @notice address that tax0 is sent to
    address payable public tax0Wallet;
    /// @notice address that tax1 is sent to
    address payable public tax1Wallet;
    /// @notice address that tax2 is sent to
    address payable public tax2Wallet;

    uint256 internal _totalSupply = 0;
    IUniswapV2Router02 internal _router = IUniswapV2Router02(address(0));
    address internal _pair;
    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;
    bool public tradingActive = false;

    IWhitelist public whitelist;

    mapping(address => uint256) private _balances;
    mapping(address => bool) public taxExcluded;
    mapping(address => uint256) public lastBuy;

    event Tax0WalletChanged(address previousWallet, address nextWallet);
    event Tax1WalletChanged(address previousWallet, address nextWallet);
    event Tax2WalletChanged(address previousWallet, address nextWallet);
    event BuyTax0Changed(uint256 previousTax, uint256 nextTax);
    event SellTax0Changed(uint256 previousTax, uint256 nextTax);
    event BuyTax1Changed(uint256 previousTax, uint256 nextTax);
    event SellTax1Changed(uint256 previousTax, uint256 nextTax);
    event BuyTax2Changed(uint256 previousTax, uint256 nextTax);
    event SellTax2Changed(uint256 previousTax, uint256 nextTax);
    event BuyReflectionTaxChanged(uint256 previousTax, uint256 nextTax);
    event SellReflectionTaxChanged(uint256 previousTax, uint256 nextTax);
    event MinTokenBalanceChanged(uint256 previousMin, uint256 nextMin);
    event Tax0Rescued(uint256 amount);
    event Tax1Rescued(uint256 amount);
    event Tax2Rescued(uint256 amount);
    event TradingActiveChanged(bool enabled);
    event TaxExclusionChanged(address user, bool taxExcluded);
    event BuyLimitChanged(uint256 previousMax, uint256 nextMax);
    event SwapFeesChanged(bool enabled);
    event CooldownChanged(uint256 previousCooldown, uint256 nextCooldown);
    event WhitelistChanged(address previousWhitelist, address nextWhitelist);

    constructor(
        address _uniswapFactory,
        address _uniswapRouter,
        uint256 _buyLimit,
        address payable _tax0Wallet,
        address payable _tax1Wallet,
        address payable _tax2Wallet
    ) ERC20("Retroverse", "RETRO") Ownable() {
        taxExcluded[owner()] = true;
        taxExcluded[address(0)] = true;
        taxExcluded[_tax0Wallet] = true;
        taxExcluded[_tax1Wallet] = true;
        taxExcluded[_tax2Wallet] = true;
        taxExcluded[address(this)] = true;

        buyLimit = _buyLimit;
        tax0Wallet = _tax0Wallet;
        tax1Wallet = _tax1Wallet;
        tax2Wallet = _tax2Wallet;

        _router = IUniswapV2Router02(_uniswapRouter);
        IUniswapV2Factory uniswapContract = IUniswapV2Factory(_uniswapFactory);
        _pair = uniswapContract.createPair(address(this), _router.WETH());
    }

    /// @notice Change the address of the tax0 wallet
    /// @param _tax0Wallet The new address of the tax0 wallet
    function setTax0Wallet(address payable _tax0Wallet) external onlyOwner {
        emit Tax0WalletChanged(tax0Wallet, _tax0Wallet);
        tax0Wallet = _tax0Wallet;
    }

    /// @notice Change the address of the tax1 wallet
    /// @param _tax1Wallet The new address of the tax1 wallet
    function setTax1Wallet(address payable _tax1Wallet) external onlyOwner {
        emit Tax1WalletChanged(tax1Wallet, _tax1Wallet);
        tax1Wallet = _tax1Wallet;
    }

    /// @notice Change the address of the tax2 wallet
    /// @param _tax2Wallet The new address of the tax2 wallet
    function setTax2Wallet(address payable _tax2Wallet) external onlyOwner {
        emit Tax2WalletChanged(tax2Wallet, _tax2Wallet);
        tax2Wallet = _tax2Wallet;
    }

    /// @notice Change the buy tax0 rate
    /// @param _buyTax0 The new buy tax0 rate
    function setBuyTax0(uint256 _buyTax0) external onlyOwner {
        require(
            _buyTax0 <= BPS_DENOMINATOR,
            "_buyTax0 cannot exceed BPS_DENOMINATOR"
        );
        emit BuyTax0Changed(buyTax0, _buyTax0);
        buyTax0 = _buyTax0;
    }

    /// @notice Change the sell tax0 rate
    /// @param _sellTax0 The new sell tax0 rate
    function setSellTax0(uint256 _sellTax0) external onlyOwner {
        require(
            _sellTax0 <= BPS_DENOMINATOR,
            "_sellTax0 cannot exceed BPS_DENOMINATOR"
        );
        emit SellTax0Changed(sellTax0, _sellTax0);
        sellTax0 = _sellTax0;
    }

    /// @notice Change the buy tax1 rate
    /// @param _buyTax1 The new buy tax1 rate
    function setBuyTax1(uint256 _buyTax1) external onlyOwner {
        require(
            _buyTax1 <= BPS_DENOMINATOR,
            "_buyTax1 cannot exceed BPS_DENOMINATOR"
        );
        emit BuyTax1Changed(buyTax1, _buyTax1);
        buyTax1 = _buyTax1;
    }

    /// @notice Change the sell tax1 rate
    /// @param _sellTax1 The new sell tax1 rate
    function setSellTax1(uint256 _sellTax1) external onlyOwner {
        require(
            _sellTax1 <= BPS_DENOMINATOR,
            "_sellTax1 cannot exceed BPS_DENOMINATOR"
        );
        emit SellTax1Changed(sellTax1, _sellTax1);
        sellTax1 = _sellTax1;
    }

    /// @notice Change the buy tax2 rate
    /// @param _buyTax2 The new buy tax2 rate
    function setBuyTax2(uint256 _buyTax2) external onlyOwner {
        require(
            _buyTax2 <= BPS_DENOMINATOR,
            "_buyTax2 cannot exceed BPS_DENOMINATOR"
        );
        emit BuyTax2Changed(buyTax2, _buyTax2);
        buyTax2 = _buyTax2;
    }

    /// @notice Change the sell tax2 rate
    /// @param _sellTax2 The new sell tax2 rate
    function setSellTax2(uint256 _sellTax2) external onlyOwner {
        require(
            _sellTax2 <= BPS_DENOMINATOR,
            "_sellTax2 cannot exceed BPS_DENOMINATOR"
        );
        emit SellTax2Changed(sellTax2, _sellTax2);
        sellTax2 = _sellTax2;
    }

    /// @notice Change the buy reflection rate
    /// @param _buyReflectionTax The new buy reflection tax rate
    function setBuyReflectionTax(uint256 _buyReflectionTax) external onlyOwner {
        require(
            _buyReflectionTax <= BPS_DENOMINATOR,
            "_buyReflectionTax cannot exceed BPS_DENOMINATOR"
        );
        emit BuyReflectionTaxChanged(buyReflectionTax, _buyReflectionTax);
        buyReflectionTax = _buyReflectionTax;
    }

    /// @notice Change the sell reflection rate
    /// @param _sellReflectionTax The new sell reflection tax rate
    function setSellReflectionTax(uint256 _sellReflectionTax)
        external
        onlyOwner
    {
        require(
            _sellReflectionTax <= BPS_DENOMINATOR,
            "_sellReflectionTax cannot exceed BPS_DENOMINATOR"
        );
        emit SellReflectionTaxChanged(sellReflectionTax, _sellReflectionTax);
        sellReflectionTax = _sellReflectionTax;
    }

    /// @notice Change the minimum contract RETRO balance before `_swap` gets invoked
    /// @param _minTokenBalance The new minimum balance
    function setMinTokenBalance(uint256 _minTokenBalance) external onlyOwner {
        emit MinTokenBalanceChanged(minTokenBalance, _minTokenBalance);
        minTokenBalance = _minTokenBalance;
    }

    /// @notice Change the cooldown for buys
    /// @param _cooldown The new cooldown in seconds
    function setCooldown(uint256 _cooldown) external onlyOwner {
        emit CooldownChanged(cooldown, _cooldown);
        cooldown = _cooldown;
    }

    /// @notice Change the whitelist
    /// @param _whitelist The new whitelist contract
    function setWhitelist(IWhitelist _whitelist) external onlyOwner {
        emit WhitelistChanged(address(whitelist), address(_whitelist));
        whitelist = _whitelist;
    }

    /// @notice Rescue RETRO from the tax0 amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of RETRO to rescue
    /// @param _recipient The recipient of the rescued RETRO
    function rescueTax0Tokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    {
        require(
            _amount <= totalTax0,
            "Amount cannot be greater than totalTax0"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit Tax0Rescued(_amount);
        totalTax0 -= _amount;
    }

    /// @notice Rescue RETRO from the tax1 amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of RETRO to rescue
    /// @param _recipient The recipient of the rescued RETRO
    function rescueTax1Tokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    {
        require(
            _amount <= totalTax1,
            "Amount cannot be greater than totalTax1"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit Tax1Rescued(_amount);
        totalTax1 -= _amount;
    }

    /// @notice Rescue RETRO from the tax2 amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of RETRO to rescue
    /// @param _recipient The recipient of the rescued RETRO
    function rescueTax2Tokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    {
        require(
            _amount <= totalTax2,
            "Amount cannot be greater than totalTax2"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit Tax2Rescued(_amount);
        totalTax2 -= _amount;
    }

    function addLiquidity(uint256 tokens)
        external
        payable
        onlyOwner
        liquidityAdd
    {
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
    function setTaxExcluded(address _account, bool _taxExcluded)
        public
        onlyOwner
    {
        taxExcluded[_account] = _taxExcluded;
        emit TaxExclusionChanged(_account, _taxExcluded);
    }

    /// @notice Updates the max amount allowed to buy
    /// @param _buyLimit The new buy limit
    function setBuyLimit(uint256 _buyLimit) external onlyOwner {
        emit BuyLimitChanged(buyLimit, _buyLimit);
        buyLimit = _buyLimit;
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

        uint256 swapAmount = totalTax0.add(totalTax1).add(totalTax2);
        bool overMinTokenBalance = swapAmount >= minTokenBalance;

        if (overMinTokenBalance && !_inSwap && sender != _pair && swapFees) {
            _swap(swapAmount);
        }

        updateReflection(sender);
        updateReflection(recipient);

        uint256 send = amount;
        uint256 tax0;
        uint256 tax1;
        uint256 tax2;
        uint256 reflectionTax;
        if (sender == _pair) {
            if (address(whitelist) != address(0)) {
                require(
                    whitelist.isWhitelisted(recipient),
                    "User is not whitelisted to buy"
                );
            }
            require(tradingActive, "Trading is not yet active");
            require(amount <= buyLimit, "Buy limit exceeded");
            if (cooldown > 0) {
                require(
                    lastBuy[recipient] + cooldown <= block.timestamp,
                    "Cooldown still active"
                );
                lastBuy[recipient] = block.timestamp;
            }
            (send, tax0, tax1, tax2, reflectionTax) = _getTaxAmounts(
                amount,
                true
            );
        } else if (recipient == _pair) {
            require(tradingActive, "Trading is not yet active");
            if (address(whitelist) != address(0)) {
                require(
                    whitelist.isWhitelisted(sender),
                    "User is not whitelisted to sell"
                );
            }
            (send, tax0, tax1, tax2, reflectionTax) = _getTaxAmounts(
                amount,
                false
            );
        }
        _rawTransfer(sender, recipient, send);
        _takeTaxes(sender, tax0, tax1, tax2, reflectionTax);
    }

    /// @notice Perform a Uniswap v2 swap from RETRO to ETH and handle tax distribution
    /// @param amount The amount of RETRO to swap in wei
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

        uint256 totalTaxes = totalTax0.add(totalTax1).add(totalTax2);
        uint256 tax0Amount = amount.mul(totalTax0).div(totalTaxes);
        uint256 tax1Amount = amount.mul(totalTax1).div(totalTaxes);
        uint256 tax2Amount = amount.mul(totalTax2).div(totalTaxes);

        uint256 tax0Eth = tradeValue.mul(totalTax0).div(totalTaxes);
        uint256 tax1Eth = tradeValue.mul(totalTax1).div(totalTaxes);
        uint256 tax2Eth = tradeValue.mul(totalTax2).div(totalTaxes);

        totalTax0 = totalTax0.sub(tax0Amount);
        totalTax1 = totalTax1.sub(tax1Amount);
        totalTax2 = totalTax2.sub(tax2Amount);
        if (tax0Eth > 0) {
            tax0Wallet.transfer(tax0Eth);
        }
        if (tax1Eth > 0) {
            tax1Wallet.transfer(tax1Eth);
        }
        if (tax2Eth > 0) {
            tax2Wallet.transfer(tax2Eth);
        }
    }

    function swapAll() external {
        uint256 swapAmount = totalTax0.add(totalTax1).add(totalTax2);

        if (!_inSwap) {
            _swap(swapAmount);
        }
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Transfers RETRO from an account to this contract for taxes
    /// @param _account The account to transfer RETRO from
    /// @param _tax0Amount The amount of tax0 tax to transfer
    /// @param _tax1Amount The amount of tax1 tax to transfer
    /// @param _reflectionTaxAmount The amount of reflection tax to transfer
    function _takeTaxes(
        address _account,
        uint256 _tax0Amount,
        uint256 _tax1Amount,
        uint256 _tax2Amount,
        uint256 _reflectionTaxAmount
    ) internal {
        require(_account != address(0), "taxation from the zero address");

        uint256 totalAmount = _tax0Amount.add(_tax1Amount).add(_tax2Amount).add(
            _reflectionTaxAmount
        );
        _rawTransfer(_account, address(this), totalAmount);
        totalTax0 += _tax0Amount;
        totalTax1 += _tax1Amount;
        totalTax2 += _tax2Amount;
        reflectionBasis += _reflectionTaxAmount;
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount The amount to tax in wei
    /// @return send The raw amount to send
    /// @return tax0 The raw tax0 tax amount
    /// @return tax1 The raw tax1 tax amount
    /// @return tax2 The raw tax1 tax amount
    /// @return reflectionTax The raw tax1 tax amount
    function _getTaxAmounts(uint256 amount, bool buying)
        internal
        view
        returns (
            uint256 send,
            uint256 tax0,
            uint256 tax1,
            uint256 tax2,
            uint256 reflectionTax
        )
    {
        if (buying) {
            tax0 = amount.mul(buyTax0).div(BPS_DENOMINATOR);
            tax1 = amount.mul(buyTax1).div(BPS_DENOMINATOR);
            tax2 = amount.mul(buyTax2).div(BPS_DENOMINATOR);
            reflectionTax = amount.mul(buyReflectionTax).div(BPS_DENOMINATOR);
        } else {
            tax0 = amount.mul(sellTax0).div(BPS_DENOMINATOR);
            tax1 = amount.mul(sellTax1).div(BPS_DENOMINATOR);
            tax2 = amount.mul(sellTax2).div(BPS_DENOMINATOR);
            reflectionTax = amount.mul(sellReflectionTax).div(BPS_DENOMINATOR);
        }
        send = amount.sub(tax0).sub(tax1).sub(tax2).sub(reflectionTax);
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

    /// @notice Enable or disable whether swap occurs during `_transfer`
    /// @param _swapFees If true, enables swap during `_transfer`
    function setSwapFees(bool _swapFees) external onlyOwner {
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

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function airdrop(address[] memory accounts, uint256[] memory amounts)
        external
        onlyOwner
    {
        require(accounts.length == amounts.length, "array lengths must match");

        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    /// @notice Update the amount of owed reflections for a user
    /// @param addr The address to update the reflections for
    function updateReflection(address addr) public override {
        if (addr == _pair || addr == address(_router)) return;

        uint256 basisDifference = reflectionBasis.sub(
            lastReflectionBasis[addr]
        );
        reflectionOwed[addr] += basisDifference.mul(balanceOf(addr)).div(
            _totalSupply
        );

        lastReflectionBasis[addr] = reflectionBasis;
    }

    /// @notice Claim all owed reflections
    function claimReflection() public override {
        updateReflection(msg.sender);
        _rawTransfer(address(this), msg.sender, reflectionOwed[msg.sender]);
        reflectionOwed[msg.sender] = 0;
    }

    receive() external payable {}
}