// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract BBI is ERC20, Ownable {
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

    // == CONSTANTS ==
    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether;
    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant SNIPE_BLOCKS = 2;

    // == LIMITS ==
    /// @notice Wallet limit in wei.
    uint256 public walletLimit;
    /// @notice Buy limit in wei.
    uint256 public buyLimit;
    /// @notice Cooldown in seconds
    uint256 public cooldown = 20;

    // == TAXES ==
    /// @notice Buy marketingTax in BPS
    uint256 public buyMarketingTax = 300;
    /// @notice Buy devTax in BPS
    uint256 public buyDevTax = 400;
    /// @notice Buy autoLiquidityTax in BPS
    uint256 public buyAutoLiquidityTax = 200;
    /// @notice Buy treasuryTax in BPS
    uint256 public buyTreasuryTax = 100;
    /// @notice Sell marketingTax in BPS
    uint256 public sellMarketingTax = 900;
    /// @notice Sell devTax in BPS
    uint256 public sellDevTax = 1000;
    /// @notice Sell autoLiquidityTax in BPS
    uint256 public sellAutoLiquidityTax = 400;
    /// @notice Sell treasuryTax in BPS
    uint256 public sellTreasuryTax = 200;
    /// @notice address that marketingTax is sent to
    address payable public marketingTaxWallet;
    /// @notice address that devTax is sent to
    address payable public devTaxWallet;
    /// @notice address that treasuryTax is sent to
    address payable public treasuryTaxWallet;
    /// @notice tokens that are allocated for marketingTax tax
    uint256 public totalMarketingTax;
    /// @notice tokens that are allocated for devTax tax
    uint256 public totalDevTax;
    /// @notice tokens that are allocated for auto liquidity tax
    uint256 public totalAutoLiquidityTax;
    /// @notice tokens that are allocated for treasury tax
    uint256 public totalTreasuryTax;

    // == FLAGS ==
    /// @notice flag indicating Uniswap trading status
    bool public tradingActive = false;
    /// @notice flag indicating swapAll enabled
    bool public swapFees = true;

    // == UNISWAP ==
    IUniswapV2Router02 public router = IUniswapV2Router02(address(0));
    address public pair;

    // == WALLET STATUSES ==
    /// @notice Maps each wallet to their tax exlcusion status
    mapping(address => bool) public taxExcluded;
    /// @notice Maps each wallet to the last timestamp they bought
    mapping(address => uint256) public lastBuy;
    /// @notice Maps each wallet to their blacklist status
    mapping(address => bool) public blacklist;
    /// @notice Maps each wallet to their whitelist status on buy limit
    mapping(address => bool) public walletLimitWhitelist;

    // == MISC ==
    /// @notice Block when trading is first enabled
    uint256 public tradingBlock;

    // == INTERNAL ==
    uint256 internal _totalSupply = 0;
    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;
    mapping(address => uint256) private _balances;

    event MarketingTaxWalletChanged(address previousWallet, address nextWallet);
    event DevTaxWalletChanged(address previousWallet, address nextWallet);
    event TreasuryTaxWalletChanged(address previousWallet, address nextWallet);
    event BuyMarketingTaxChanged(uint256 previousTax, uint256 nextTax);
    event SellMarketingTaxChanged(uint256 previousTax, uint256 nextTax);
    event BuyDevTaxChanged(uint256 previousTax, uint256 nextTax);
    event SellDevTaxChanged(uint256 previousTax, uint256 nextTax);
    event BuyAutoLiquidityTaxChanged(uint256 previousTax, uint256 nextTax);
    event SellAutoLiquidityTaxChanged(uint256 previousTax, uint256 nextTax);
    event BuyTreasuryTaxChanged(uint256 previousTax, uint256 nextTax);
    event SellTreasuryTaxChanged(uint256 previousTax, uint256 nextTax);
    event MarketingTaxRescued(uint256 amount);
    event DevTaxRescued(uint256 amount);
    event AutoLiquidityTaxRescued(uint256 amount);
    event TreasuryTaxRescued(uint256 amount);
    event TradingActiveChanged(bool enabled);
    event TaxExclusionChanged(address user, bool taxExcluded);
    event MaxTransferChanged(uint256 previousMax, uint256 nextMax);
    event BuyLimitChanged(uint256 previousMax, uint256 nextMax);
    event WalletLimitChanged(uint256 previousMax, uint256 nextMax);
    event CooldownChanged(uint256 previousCooldown, uint256 nextCooldown);
    event BlacklistUpdated(address user, bool previousStatus, bool nextStatus);
    event SwapFeesChanged(bool previousStatus, bool nextStatus);
    event WalletLimitWhitelistUpdated(
        address user,
        bool previousStatus,
        bool nextStatus
    );

    constructor(
        address _factory,
        address _router,
        uint256 _buyLimit,
        uint256 _walletLimit,
        address payable _marketingTaxWallet,
        address payable _devTaxWallet,
        address payable _treasuryTaxWallet
    ) ERC20("Balboa Inu", "BBI") Ownable() {
        taxExcluded[owner()] = true;
        taxExcluded[address(0)] = true;
        taxExcluded[_marketingTaxWallet] = true;
        taxExcluded[_devTaxWallet] = true;
        taxExcluded[address(this)] = true;

        buyLimit = _buyLimit;
        walletLimit = _walletLimit;
        marketingTaxWallet = _marketingTaxWallet;
        devTaxWallet = _devTaxWallet;
        treasuryTaxWallet = _treasuryTaxWallet;

        router = IUniswapV2Router02(_router);
        IUniswapV2Factory uniswapContract = IUniswapV2Factory(_factory);
        pair = uniswapContract.createPair(address(this), router.WETH());

        _updateWalletLimitWhitelist(address(this), true);
        _updateWalletLimitWhitelist(pair, true);
    }

    /// @notice Change the address of the buyback wallet
    /// @param _marketingTaxWallet The new address of the buyback wallet
    function setMarketingTaxWallet(address payable _marketingTaxWallet)
        external
        onlyOwner
    {
        emit MarketingTaxWalletChanged(marketingTaxWallet, _marketingTaxWallet);
        marketingTaxWallet = _marketingTaxWallet;
    }

    /// @notice Change the address of the devTax wallet
    /// @param _devTaxWallet The new address of the devTax wallet
    function setDevTaxWallet(address payable _devTaxWallet) external onlyOwner {
        emit DevTaxWalletChanged(devTaxWallet, _devTaxWallet);
        devTaxWallet = _devTaxWallet;
    }

    /// @notice Change the address of the treasuryTax wallet
    /// @param _treasuryTaxWallet The new address of the treasuryTax wallet
    function setTreasuryTaxWallet(address payable _treasuryTaxWallet)
        external
        onlyOwner
    {
        emit TreasuryTaxWalletChanged(treasuryTaxWallet, _treasuryTaxWallet);
        treasuryTaxWallet = _treasuryTaxWallet;
    }

    /// @notice Change the buy marketingTax rate
    /// @param _buyMarketingTax The new buy marketingTax rate
    function setBuyMarketingTax(uint256 _buyMarketingTax) external onlyOwner {
        require(
            _buyMarketingTax <= BPS_DENOMINATOR,
            "_buyMarketingTax cannot exceed BPS_DENOMINATOR"
        );
        emit BuyMarketingTaxChanged(buyMarketingTax, _buyMarketingTax);
        buyMarketingTax = _buyMarketingTax;
    }

    /// @notice Change the sell marketingTax rate
    /// @param _sellMarketingTax The new sell marketingTax rate
    function setSellMarketingTax(uint256 _sellMarketingTax) external onlyOwner {
        require(
            _sellMarketingTax <= BPS_DENOMINATOR,
            "_sellMarketingTax cannot exceed BPS_DENOMINATOR"
        );
        emit SellMarketingTaxChanged(sellMarketingTax, _sellMarketingTax);
        sellMarketingTax = _sellMarketingTax;
    }

    /// @notice Change the buy devTax rate
    /// @param _buyDevTax The new devTax rate
    function setBuyDevTax(uint256 _buyDevTax) external onlyOwner {
        require(
            _buyDevTax <= BPS_DENOMINATOR,
            "_buyDevTax cannot exceed BPS_DENOMINATOR"
        );
        emit BuyDevTaxChanged(buyDevTax, _buyDevTax);
        buyDevTax = _buyDevTax;
    }

    /// @notice Change the buy devTax rate
    /// @param _sellDevTax The new devTax rate
    function setSellDevTax(uint256 _sellDevTax) external onlyOwner {
        require(
            _sellDevTax <= BPS_DENOMINATOR,
            "_sellDevTax cannot exceed BPS_DENOMINATOR"
        );
        emit SellDevTaxChanged(sellDevTax, _sellDevTax);
        sellDevTax = _sellDevTax;
    }

    /// @notice Change the buy autoLiquidityTax rate
    /// @param _buyAutoLiquidityTax The new buy autoLiquidityTax rate
    function setBuyAutoLiquidityTax(uint256 _buyAutoLiquidityTax)
        external
        onlyOwner
    {
        require(
            _buyAutoLiquidityTax <= BPS_DENOMINATOR,
            "_buyAutoLiquidityTax cannot exceed BPS_DENOMINATOR"
        );
        emit BuyAutoLiquidityTaxChanged(
            buyAutoLiquidityTax,
            _buyAutoLiquidityTax
        );
        buyAutoLiquidityTax = _buyAutoLiquidityTax;
    }

    /// @notice Change the sell autoLiquidityTax rate
    /// @param _sellAutoLiquidityTax The new sell autoLiquidityTax rate
    function setSellAutoLiquidityTax(uint256 _sellAutoLiquidityTax)
        external
        onlyOwner
    {
        require(
            _sellAutoLiquidityTax <= BPS_DENOMINATOR,
            "_sellAutoLiquidityTax cannot exceed BPS_DENOMINATOR"
        );
        emit SellAutoLiquidityTaxChanged(
            sellAutoLiquidityTax,
            _sellAutoLiquidityTax
        );
        sellAutoLiquidityTax = _sellAutoLiquidityTax;
    }

    /// @notice Change the buy treasuryTax rate
    /// @param _buyTreasuryTax The new treasuryTax rate
    function setBuyTreasuryTax(uint256 _buyTreasuryTax) external onlyOwner {
        require(
            _buyTreasuryTax <= BPS_DENOMINATOR,
            "_buyTreasuryTax cannot exceed BPS_DENOMINATOR"
        );
        emit BuyTreasuryTaxChanged(buyTreasuryTax, _buyTreasuryTax);
        buyTreasuryTax = _buyTreasuryTax;
    }

    /// @notice Change the buy treasuryTax rate
    /// @param _sellTreasuryTax The new treasuryTax rate
    function setSellTreasuryTax(uint256 _sellTreasuryTax) external onlyOwner {
        require(
            _sellTreasuryTax <= BPS_DENOMINATOR,
            "_sellTreasuryTax cannot exceed BPS_DENOMINATOR"
        );
        emit SellTreasuryTaxChanged(sellTreasuryTax, _sellTreasuryTax);
        sellTreasuryTax = _sellTreasuryTax;
    }

    /// @notice Change the cooldown for buys
    /// @param _cooldown The new cooldown in seconds
    function setCooldown(uint256 _cooldown) external onlyOwner {
        emit CooldownChanged(cooldown, _cooldown);
        cooldown = _cooldown;
    }

    /// @notice Rescue BBI from the marketingTax amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of BBI to rescue
    /// @param _recipient The recipient of the rescued BBI
    function rescueMarketingTaxTokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    {
        require(
            _amount <= totalMarketingTax,
            "Amount cannot be greater than totalMarketingTax"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit MarketingTaxRescued(_amount);
        totalMarketingTax -= _amount;
    }

    /// @notice Rescue BBI from the devTax amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of BBI to rescue
    /// @param _recipient The recipient of the rescued BBI
    function rescueDevTaxTokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    {
        require(
            _amount <= totalDevTax,
            "Amount cannot be greater than totalDevTax"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit DevTaxRescued(_amount);
        totalDevTax -= _amount;
    }

    /// @notice Rescue BBI from the autoLiquidityTax amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of BBI to rescue
    /// @param _recipient The recipient of the rescued BBI
    function rescueAutoLiquidityTaxTokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    {
        require(
            _amount <= totalAutoLiquidityTax,
            "Amount cannot be greater than totalAutoLiquidityTax"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit AutoLiquidityTaxRescued(_amount);
        totalAutoLiquidityTax -= _amount;
    }

    /// @notice Rescue BBI from the treasuryTax amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of BBI to rescue
    /// @param _recipient The recipient of the rescued BBI
    function rescueTreasuryTaxTokens(uint256 _amount, address _recipient)
        external
        onlyOwner
    {
        require(
            _amount <= totalTreasuryTax,
            "Amount cannot be greater than totalTreasuryTax"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit TreasuryTaxRescued(_amount);
        totalTreasuryTax -= _amount;
    }

    function addLiquidity(uint256 tokens)
        external
        payable
        onlyOwner
        liquidityAdd
    {
        _mint(address(this), tokens);
        _approve(address(this), address(router), tokens);

        router.addLiquidityETH{value: msg.value}(
            address(this),
            tokens,
            0,
            0,
            owner(),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    /// @notice Admin function to update a wallet's blacklist status
    /// @param user the wallet
    /// @param status the new status
    function updateBlacklist(address user, bool status)
        external
        virtual
        onlyOwner
    {
        _updateBlacklist(user, status);
    }

    function _updateBlacklist(address user, bool status) internal virtual {
        emit BlacklistUpdated(user, blacklist[user], status);
        blacklist[user] = status;
    }

    /// @notice Admin function to update a wallet's buy limit status
    /// @param user the wallet
    /// @param status the new status
    function updateWalletLimitWhitelist(address user, bool status)
        external
        virtual
        onlyOwner
    {
        _updateWalletLimitWhitelist(user, status);
    }

    function _updateWalletLimitWhitelist(address user, bool status)
        internal
        virtual
    {
        emit WalletLimitWhitelistUpdated(
            user,
            walletLimitWhitelist[user],
            status
        );
        walletLimitWhitelist[user] = status;
    }

    /// @notice Enables or disables trading on Uniswap
    function setTradingActive(bool _tradingActive) external onlyOwner {
        if (_tradingActive && tradingBlock == 0) {
            tradingBlock = block.number;
        }
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

    /// @notice Updates the max amount allowed to be held by a single wallet
    /// @param _walletLimit The new max
    function setWalletLimit(uint256 _walletLimit) external onlyOwner {
        emit WalletLimitChanged(walletLimit, _walletLimit);
        walletLimit = _walletLimit;
    }

    /// @notice Enable or disable whether swap occurs during `_transfer`
    /// @param _swapFees If true, enables swap during `_transfer`
    function setSwapFees(bool _swapFees) external onlyOwner {
        emit SwapFeesChanged(swapFees, _swapFees);
        swapFees = _swapFees;
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
        require(!blacklist[recipient], "Recipient is blacklisted");

        if (taxExcluded[sender] || taxExcluded[recipient]) {
            _rawTransfer(sender, recipient, amount);
            return;
        }

        // Enforce wallet limits
        if (!walletLimitWhitelist[recipient]) {
            require(
                balanceOf(recipient).add(amount) <= walletLimit,
                "Wallet limit exceeded"
            );
        }

        uint256 send = amount;
        uint256 marketingTax;
        uint256 devTax;
        uint256 autoLiquidityTax;
        uint256 treasuryTax;
        if (sender == pair) {
            require(tradingActive, "Trading is not yet active");
            require(
                balanceOf(recipient).add(amount) <= buyLimit,
                "Buy limit exceeded"
            );
            if (block.number <= tradingBlock + SNIPE_BLOCKS) {
                _updateBlacklist(recipient, true);
            }
            if (cooldown > 0) {
                require(
                    lastBuy[recipient] + cooldown <= block.timestamp,
                    "Cooldown still active"
                );
                lastBuy[recipient] = block.timestamp;
            }
            (
                send,
                marketingTax,
                devTax,
                autoLiquidityTax,
                treasuryTax
            ) = _getTaxAmounts(amount, true);
        } else if (recipient == pair) {
            require(tradingActive, "Trading is not yet active");
            if (swapFees) swapAll();
            (
                send,
                marketingTax,
                devTax,
                autoLiquidityTax,
                treasuryTax
            ) = _getTaxAmounts(amount, false);
        }
        _rawTransfer(sender, recipient, send);
        _takeTaxes(sender, marketingTax, devTax, autoLiquidityTax, treasuryTax);
    }

    /// @notice Peforms auto liquidity and tax distribution
    function swapAll() public lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        // Auto-liquidity
        uint256 autoLiquidityAmount = totalAutoLiquidityTax.div(2);
        uint256 walletTaxes = totalMarketingTax.add(totalDevTax).add(
            totalTreasuryTax
        );
        _approve(
            address(this),
            address(router),
            walletTaxes.add(totalAutoLiquidityTax)
        );
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            autoLiquidityAmount.add(walletTaxes),
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            autoLiquidityAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
        totalAutoLiquidityTax = 0;

        // Distribute remaining taxes
        uint256 contractEth = address(this).balance;

        uint256 marketingTaxEth = contractEth.mul(totalMarketingTax).div(
            walletTaxes
        );
        uint256 devTaxEth = contractEth.mul(totalDevTax).div(walletTaxes);
        uint256 treasuryTaxEth = contractEth.mul(totalTreasuryTax).div(
            walletTaxes
        );

        totalMarketingTax = 0;
        totalDevTax = 0;
        totalTreasuryTax = 0;
        if (marketingTaxEth > 0) {
            marketingTaxWallet.transfer(marketingTaxEth);
        }
        if (devTaxEth > 0) {
            devTaxWallet.transfer(devTaxEth);
        }
        if (treasuryTaxEth > 0) {
            treasuryTaxWallet.transfer(treasuryTaxEth);
        }
    }

    /// @notice Admin function to rescue ETH from the contract
    function rescueETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Transfers BBI from an account to this contract for taxes
    /// @param _account The account to transfer BBI from
    /// @param _marketingTaxAmount The amount of marketingTax tax to transfer
    /// @param _devTaxAmount The amount of devTax tax to transfer
    function _takeTaxes(
        address _account,
        uint256 _marketingTaxAmount,
        uint256 _devTaxAmount,
        uint256 _autoLiquidityTaxAmount,
        uint256 _treasuryTaxAmount
    ) internal {
        require(_account != address(0), "taxation from the zero address");

        uint256 totalAmount = _marketingTaxAmount
            .add(_devTaxAmount)
            .add(_autoLiquidityTaxAmount)
            .add(_treasuryTaxAmount);
        _rawTransfer(_account, address(this), totalAmount);
        totalMarketingTax += _marketingTaxAmount;
        totalDevTax += _devTaxAmount;
        totalAutoLiquidityTax += _autoLiquidityTaxAmount;
        totalTreasuryTax += _treasuryTaxAmount;
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount The amount to tax in wei
    /// @return send The raw amount to send
    /// @return marketingTax The raw marketingTax tax amount
    /// @return devTax The raw devTax tax amount
    function _getTaxAmounts(uint256 amount, bool buying)
        internal
        view
        returns (
            uint256 send,
            uint256 marketingTax,
            uint256 devTax,
            uint256 autoLiquidityTax,
            uint256 treasuryTax
        )
    {
        if (buying) {
            marketingTax = amount.mul(buyMarketingTax).div(BPS_DENOMINATOR);
            devTax = amount.mul(buyDevTax).div(BPS_DENOMINATOR);
            autoLiquidityTax = amount.mul(buyAutoLiquidityTax).div(
                BPS_DENOMINATOR
            );
            treasuryTax = amount.mul(buyTreasuryTax).div(BPS_DENOMINATOR);
        } else {
            marketingTax = amount.mul(sellMarketingTax).div(BPS_DENOMINATOR);
            devTax = amount.mul(sellDevTax).div(BPS_DENOMINATOR);
            autoLiquidityTax = amount.mul(sellAutoLiquidityTax).div(
                BPS_DENOMINATOR
            );
            treasuryTax = amount.mul(sellTreasuryTax).div(BPS_DENOMINATOR);
        }
        send = amount.sub(marketingTax).sub(devTax).sub(autoLiquidityTax).sub(
            treasuryTax
        );
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

    receive() external payable {}
}