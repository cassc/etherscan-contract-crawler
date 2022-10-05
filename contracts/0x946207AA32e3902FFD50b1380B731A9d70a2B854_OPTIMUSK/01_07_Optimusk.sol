// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

pragma solidity ^0.8.6;

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

pragma solidity ^0.8.6;

interface IPair{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function sync() external;
}

pragma solidity ^0.8.6;

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

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountATokenDesired,
        uint amountBTokenDesired,
        uint amountATokenMin,
        uint amountBTokenMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract OPTIMUSK is ERC20, Ownable{
    using Address for address payable;

    mapping(address => bool) public isFeeExempt;

    IRouter public router;
    address public pair;

    address public marketingWallet;

    bool private swapping;
    bool public swapEnabled;
    uint256 public swapThreshold;
    uint256 public maxWalletAmount;

    uint256 public transferFee;

    struct Fees {
        uint256 marketing;
    }

    Fees public buyFees = Fees(6);
    Fees public sellFees = Fees(6);
    uint256 public totalSellFee = 6;
    uint256 public totalBuyFee = 6;

    bool public enableTransfers;

    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }

    event TaxRecipientsUpdated(address newMarketingWallet);
    event FeesUpdated();
    event SwapEnabled(bool state);
    event SwapThresholdUpdated(uint256 amount);
    event MaxWalletAmountUpdated(uint256 amount);
    event RouterUpdated(address newRouter);
    event ExemptFromFeeUpdated(address user, bool state);
    event PairUpdated(address newPair);

    constructor(address _routerAddress, string memory _name_, string memory _symbol_) ERC20(_name_, _symbol_) {
        require(_routerAddress != address(0), "Router address cannot be zero address");
        IRouter _router = IRouter(_routerAddress);

        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;

        swapEnabled = true;
        swapThreshold = 500_000 * 10**18;
        maxWalletAmount = 10_000_000 * 10**18;

        marketingWallet = msg.sender;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        _mint(msg.sender, 1_000_000_000 * 10**18);
    }

    function setTaxRecipients(address _marketingWallet) external onlyOwner{
        require(_marketingWallet != address(0), "marketingWallet cannot be the zero address");
        marketingWallet = _marketingWallet;

        isFeeExempt[marketingWallet] = true;

        emit TaxRecipientsUpdated(_marketingWallet);
    }

    function setTransferFee(uint256 _transferFee) external onlyOwner{
        require(_transferFee < 10, "Transfer fee must be less than 10");
        transferFee = _transferFee;
        emit FeesUpdated();
    }

    function setBuyFees(uint256 _marketing) external onlyOwner{
        require(_marketing < 10, "Buy fee must be less than 10");
        buyFees = Fees(_marketing);
        totalBuyFee = _marketing;
        emit FeesUpdated();
    }

    function setSellFees(uint256 _marketing) external onlyOwner{
        require(_marketing < 10, "Sell fee must be less than 10");
        sellFees = Fees(_marketing);
        totalSellFee = _marketing;
        emit FeesUpdated();
    }

    function setSwapEnabled(bool state) external onlyOwner{
        swapEnabled = state;
        emit SwapEnabled(state);
    }

    function setSwapThreshold(uint256 amount) external onlyOwner{
        swapThreshold = amount * 10**18;
        emit SwapThresholdUpdated(amount);
    }

    function setMaxWalletAmount(uint256 amount) external onlyOwner{
        require(amount >= 1_000_000, "Max wallet amount must be >= 100,000");
        maxWalletAmount = amount * 10**18;
        emit MaxWalletAmountUpdated(amount);
    }

    function setRouter(address newRouter) external onlyOwner{
        router = IRouter(newRouter);
        emit RouterUpdated(newRouter);
    }

    function setPair(address newPair) external onlyOwner{
        require(newPair != address(0), "Pair cannot be zero address");
        pair = newPair;
        emit PairUpdated(newPair);
    }

    function exemptFromFee(address user, bool state) external onlyOwner{
        require(isFeeExempt[user] != state, "State already set");
        isFeeExempt[user] = state;
        emit ExemptFromFeeUpdated(user, state);
    }

    function rescueETH() external onlyOwner{
        require(address(this).balance > 0, "Insufficient ETH balance");
        payable(owner()).sendValue(address(this).balance);
    }

    function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner{
        require(tokenAdd != address(this), "Cannot rescue itself");
        require(IERC20(tokenAdd).balanceOf(address(this)) >= amount, "Insufficient ERC20 balance");
        IERC20(tokenAdd).transfer(owner(), amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!isFeeExempt[from] && !isFeeExempt[to]) {
            require(enableTransfers, "Transactions are not enable");
            if(to != pair) require(balanceOf(to) + amount <= maxWalletAmount, "Receiver balance is exceeding maxWalletAmount");
        }

        uint256 taxAmt;

        if(!swapping && !isFeeExempt[from] && !isFeeExempt[to]){
            if(to == pair){
                taxAmt = amount * totalSellFee / 100;
            } else if(from == pair){
                taxAmt = amount * totalBuyFee / 100;
            } else {
                taxAmt = amount * transferFee / 100;
            }
        }

        if (!swapping && swapEnabled && to == pair && totalSellFee > 0) {
            handle_fees();
        }

        super._transfer(from, to, amount - taxAmt);
        if(taxAmt > 0) {
            super._transfer(from, address(this), taxAmt);
        }
    }

    function handle_fees() private inSwap {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapThreshold) {
            if(swapThreshold > 1) {
                contractBalance = swapThreshold;
            }

            swapTokensForETH(contractBalance);
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> ETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, marketingWallet, block.timestamp);

    }

    function setEnableTransfers() external onlyOwner {
        enableTransfers = true;
    }

    // fallbacks
    receive() external payable {}
}