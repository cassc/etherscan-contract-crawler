// SPDX-License-Identifier: MIT
///
/// Please feel free to contact @mbd4476744 on TG if you have any queries about this smart contract.
///
///// KYLON TOKEN
///// Total Supply: 1000000000
///// Website: https://www.kylon.at/ || https://kylonfoundation.org
///// Twitter: https://twitter.com/Kylonfoundation
///// Telegram: https://t.me/kyloncoin

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./pancakeswap.sol";

contract KylonToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {

    using SafeMath for uint256;

    IPancakeSwapV2Router02 private PancakeSwapV2Router;
    address private PancakeSwapV2Pair;

    bool initialized = false;
    bool public tradingEnabled = false;
    bool public dumpProtectionEnabled = true;
    bool public sniperTaxEnabled = true;

    bool inSwap = false;

    // Settings of Auto Swapping the tokens which are collected from taxes
    bool public autoSwap = false;
    uint256 public swapThreshold = 0;

    // Tax Settings 
    uint256 public buyTax = 650;
    uint256 public sellTax = 650;
    uint256 public transferTax = 650;
    uint256 public liquidityShare = 0;
    uint256 public marketingShare = 75;
    uint256 public charityShare = 25;
    uint256 public burnShare = 0;
    uint256 public totalShares = 100;
    uint256 public constant DENOMINATOR=10000;

    // Officially launched time (when trading enabled on DEXs) * Required for Dynamic Sell Tax Settings
    uint256 public launchTime;

    // Gas value for transferring funds
    uint256 public transferGas = 3000;
  
    mapping (string => Wallet) public wallets;
    mapping (address => bool) public isWhitelisted;
    mapping (address => bool) public isCEX;
    mapping (address => bool) public isMarketMaker;

    event ProjectInitialized(bool completed);
    event EnableTrading();
    event SniperTaxRemoved();
    event DisableDumpProtection();
    event TriggerSwapBack();
    event RecoverBNB(uint256 amount);
    event RecoverBEP20(address indexed token, uint256 amount);
    event UpdateGasForProcessing(uint256 indexed newValue, uint256 indexed oldValue);
    event SetWhitelisted(address indexed account, bool indexed status);
    event SetCEX(address indexed account, bool indexed exempt);
    event SetMarketMaker(address indexed account, bool indexed isMM);
    event SetWallet(string keyword, Wallet wallets);
    event SetTaxes(uint256 buy, uint256 sell, uint256 transfer);
    event SetShares(uint256 liquidityShare, uint256 marketingShare, uint256 charityShare, uint256 burnShare);
    event SetSwapBackSettings(bool enabled, uint256 amount);
    event AutoLiquidity(uint256 PancakeSwapV2Pair, uint256 tokens);
    event DepositWallet(address indexed wallet, uint256 amount);

    struct Wallet {
        string name;
        address addr;
    }

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() ERC20("KYLON", "KYLN") ERC20Permit("KYLON") {
        _mint(address(msg.sender), 1000000000 * 10**18);
    }

    receive() external payable {}

    function _mint(address account, uint256 amount) internal virtual override(ERC20) {
        require(!initialized, "Project has already initialized!");
        ERC20._mint(account, amount);
    }

    function initializeProject() external onlyOwner {
        require(!initialized, "Project has already been initialized!");
        require(wallets["marketing"].addr != address(0) && wallets["charity"].addr != address(0), "Marketing & charity is not defined yet.");

        // MN: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // TN: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3

        IPancakeSwapV2Router02 _pancakeSwapV2Router = IPancakeSwapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _pancakeSwapV2Pair = IPancakeSwapV2Factory(_pancakeSwapV2Router.factory())
        .createPair(address(this), _pancakeSwapV2Router.WETH());

        PancakeSwapV2Router = _pancakeSwapV2Router;
        PancakeSwapV2Pair = _pancakeSwapV2Pair;

        _approve(address(this), address(PancakeSwapV2Router), type(uint256).max);
        
        isMarketMaker[PancakeSwapV2Pair] = true;

        isWhitelisted[owner()] = true;
     
        initialized = true;
        emit ProjectInitialized(true);

    }

    // Override
    function _transfer(address sender, address recipient, uint256 amount) internal override {

        if (isWhitelisted[sender] || isWhitelisted[recipient]) {
            super._transfer(sender, recipient, amount);
            return;
        }

        require(tradingEnabled);

        if (_shouldSwapBack(isMarketMaker[recipient] && autoSwap && balanceOf(address(this)) >= swapThreshold)) { 
            _swapBack();
        }

        uint256 amountAfterTaxes = _takeTax(sender, recipient, amount);

        super._transfer(sender, recipient, amountAfterTaxes);

    }

    // Public

    function getDynamicSellTax() public view returns (uint256) {
        uint256 endingTime = launchTime + 7 days;
        if (endingTime > block.timestamp) {
            uint256 remainingTime = endingTime - block.timestamp;
            return sellTax.add(sellTax.mul(remainingTime / 7 days));
        } else {
            return sellTax;
        }
    }

    function _takeTax(address sender, address recipient, uint256 amount) internal returns (uint256) {

        if (amount == 0) { return amount; }

        uint256 tax = _getTotalTax(sender, recipient);

        uint256 taxAmount = amount.mul(tax).div(DENOMINATOR);

        if (taxAmount > 0) { super._transfer(sender, address(this), taxAmount); }

        return amount.sub(taxAmount);

    }

    function _getTotalTax(address sender, address recipient) internal view returns (uint256) {

        if (sniperTaxEnabled) { return 9900; }
        if (isCEX[recipient]) { return sellTax; }
        if (isCEX[sender]) { return buyTax; }

        if (isMarketMaker[sender]) {
            return buyTax;
        } else if (isMarketMaker[recipient]) {
            return dumpProtectionEnabled ? getDynamicSellTax() : sellTax;
        } else {
            return transferTax;
        }

    }

    function _shouldSwapBack(bool run) internal view returns (bool) {
        return tradingEnabled && run;
    }


    function _swapBack() internal swapping {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = PancakeSwapV2Router.WETH();

        uint256 totalBNBShares = totalShares;

        uint256 burnAmount = 0;
        uint256 liquidityTokens = 0;

        if(burnShare > 0) {
            burnAmount = swapThreshold.mul(burnShare).div(DENOMINATOR);
            IERC20(address(this)).transfer(address(0x000000000000000000000000000000000000dEaD), burnAmount);
            totalBNBShares = totalBNBShares.sub(burnShare);
        }

        uint256 netAmount = swapThreshold.sub(burnAmount);

        if(liquidityShare > 0) {
           liquidityTokens = netAmount.mul(liquidityShare).div(totalShares).div(2);
        }           

        uint256 amountToSwap = netAmount.sub(liquidityTokens);
        uint256 balanceBefore = address(this).balance;

        PancakeSwapV2Router.swapExactTokensForETH(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 amountBNBLiquidity = 0;

        if(liquidityTokens > 0) {
            totalBNBShares = totalBNBShares.sub(liquidityShare.div(2));
            amountBNBLiquidity = amountBNB.mul(liquidityShare).div(totalBNBShares).div(2);
            PancakeSwapV2Router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                liquidityTokens,
                0,
                0,
                address(this),
                block.timestamp
            );

            emit AutoLiquidity(amountBNBLiquidity, liquidityTokens);

        }


        uint256 amountBNBMarketing = amountBNB.mul(marketingShare).div(totalBNBShares);
        uint256 amountBNBCharity = amountBNB.mul(charityShare).div(totalBNBShares);

        (bool marketingSuccess,) = payable(wallets["marketing"].addr).call{value: amountBNBMarketing, gas: transferGas}("");
        if (marketingSuccess) { emit DepositWallet(wallets["marketing"].addr, amountBNBMarketing); }

        (bool charitySuccess,) = payable(wallets["charity"].addr).call{value: amountBNBCharity, gas: transferGas}("");
        if (charitySuccess) { emit DepositWallet(wallets["charity"].addr, amountBNBCharity); }

    }

    // Owner
    function disableDumpProtection() external onlyOwner {
        dumpProtectionEnabled = false;
        emit DisableDumpProtection();
    }

    function removeSniperTax() external onlyOwner {
        sniperTaxEnabled = false;
        emit SniperTaxRemoved();
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled);
        tradingEnabled = true;
        launchTime = block.timestamp;
        emit EnableTrading();
    }

    function triggerSwapBack() external onlyOwner {
        _swapBack();
        emit TriggerSwapBack();
    }

    function recoverBNB(string memory walletName) external onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent,) = payable(wallets[walletName].addr).call{value: amount, gas: transferGas}("");
        require(sent, "Tx failed");
        emit RecoverBNB(amount);
    }

    function recoverBEP20(IERC20 token, address recipient) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(recipient, amount);
        emit RecoverBEP20(address(token), amount);
    }

    function setIsWhitelisted(address account, bool value) external onlyOwner {
        isWhitelisted[account] = value;
        emit SetWhitelisted(account, value);
    }

    function setIsCEX(address account, bool value) external onlyOwner {
        isCEX[account] = value;
        emit SetCEX(account, value);
    }

    function setIsMarketMaker(address account, bool value) external onlyOwner {
        require(account != PancakeSwapV2Pair);
        isMarketMaker[account] = value;
        emit SetMarketMaker(account, value);
    }

    function setTaxes(uint256 newBuyTax, uint256 newSellTax, uint256 newTransferTax) external onlyOwner {
        require(newBuyTax <= 1000 && newSellTax <= 1000 && newTransferTax <= 1000);
        buyTax = newBuyTax;
        sellTax = newSellTax;
        transferTax = newTransferTax;
        emit SetTaxes(buyTax, sellTax, transferTax);
    }

    function setShares(uint256 newLiquidityShare, uint256 newMarketingShare, uint256 newCharityShare, uint256 newBurnShare) external onlyOwner {
        liquidityShare = newLiquidityShare;
        marketingShare = newMarketingShare;
        charityShare = newCharityShare;
        burnShare = newBurnShare;
        totalShares = newLiquidityShare.add(newMarketingShare).add(newCharityShare).add(newBurnShare);
        emit SetShares(liquidityShare, marketingShare, charityShare, burnShare);
    }

    function setSwapBackSettings(bool status, uint256 amount) external onlyOwner {
        autoSwap = status;
        swapThreshold = amount.mul(10**18);
        emit SetSwapBackSettings(status, swapThreshold);
    }

    function setTransferGas(uint256 newGas) external onlyOwner {
        require(newGas >= 25000 && newGas <= 50000);
        emit UpdateGasForProcessing(newGas,transferGas);
        transferGas = newGas;
    }

    function setWallets(Wallet memory wallet) external onlyOwner {
        isWhitelisted[wallets[wallet.name].addr] = false;
        wallets[wallet.name] = wallet;
        isWhitelisted[wallet.addr] = true;
        emit SetWallet(wallet.name, wallet);
    }

}