// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Moon is Context, ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private _uniswapV2Router02;

    mapping(address => bool) private _excludedFromFees;
    mapping(address => bool) private _excludedFromMaxTxAmount;

    bool public tradingOpen = false;
    bool private _swapping = false;
    bool public swapEnabled = false;
    bool public feesEnabled = true;
    bool public transferFeesEnabled = false;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    uint256 private _totalFees;
    uint256 private _marketingFee;

    uint256 public buyMarketingFee = 10;
    uint256 private _previousBuyMarketingFee = buyMarketingFee;

    uint256 public sellMarketingFee = 10;
    uint256 private _previousSellMarketingFee = sellMarketingFee;

    uint256 public transferMarketingFee = 10;
    uint256 private _previousTransferMarketingFee = transferMarketingFee;

    uint256 private _tokensForMarketing;
    uint256 private _swapTokensAtAmount = 0;

    address payable public marketingWalletAddress =
        payable(0x06AE8571Dd5124EdE5f634A6422dDB9F5b5c68D6);

    address private _uniswapV2Pair;

    enum TransactionType {
        BUY,
        SELL,
        TRANSFER
    }

    modifier lockSwapping() {
        _swapping = true;
        _;
        _swapping = false;
    }

    event OpenTrading();
    event SetMaxBuyAmount(uint256 newMaxBuyAmount);
    event SetMaxSellAmount(uint256 newMaxSellAmount);
    event SetMaxWalletAmount(uint256 newMaxWalletAmount);
    event SetSwapTokensAtAmount(uint256 newSwapTokensAtAmount);
    event SetBuyFee(uint256 buyMarketingFee);
    event SetSellFee(uint256 sellMarketingFee);
    event SetTransferFee(uint256 transferMarketingFee);

    constructor() ERC20("Moon Coin", "MOON") {
        uint256 _totalSupply = 100_000_000 ether;

        maxBuyAmount = _totalSupply;
        maxSellAmount = _totalSupply;
        maxWalletAmount = _totalSupply;

        _excludedFromFees[owner()] = true;
        _excludedFromFees[address(this)] = true;
        _excludedFromFees[address(0xdead)] = true;
        _excludedFromFees[marketingWalletAddress] = true;

        _excludedFromMaxTxAmount[owner()] = true;
        _excludedFromMaxTxAmount[address(this)] = true;
        _excludedFromMaxTxAmount[address(0xdead)] = true;
        _excludedFromMaxTxAmount[marketingWalletAddress] = true;

        _mint(owner(), _totalSupply);
    }

    receive() external payable {}

    fallback() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0x0), "ERC20: transfer from the zero address");
        require(to != address(0x0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;
        TransactionType txType = (from == _uniswapV2Pair)
            ? TransactionType.BUY
            : (to == _uniswapV2Pair)
            ? TransactionType.SELL
            : TransactionType.TRANSFER;
        if (
            from != owner() &&
            to != owner() &&
            to != address(0x0) &&
            to != address(0xdead) &&
            !_swapping
        ) {
            if (!tradingOpen)
                require(
                    _excludedFromFees[from] || _excludedFromFees[to],
                    "Trading is not allowed yet."
                );

            if (
                txType == TransactionType.BUY &&
                to != address(_uniswapV2Router02) &&
                !_excludedFromMaxTxAmount[to]
            ) {
                require(
                    amount <= maxBuyAmount,
                    "Transfer amount exceeds the maxBuyAmount."
                );
                require(
                    balanceOf(to).add(amount) <= maxWalletAmount,
                    "Exceeds maximum wallet token amount."
                );
            }

            if (
                txType == TransactionType.SELL &&
                from != address(_uniswapV2Router02) &&
                !_excludedFromMaxTxAmount[from]
            )
                require(
                    amount <= maxSellAmount,
                    "Transfer amount exceeds the maxSellAmount."
                );
        }

        if (
            _excludedFromFees[from] ||
            _excludedFromFees[to] ||
            !feesEnabled ||
            (!transferFeesEnabled && txType == TransactionType.TRANSFER)
        ) takeFee = false;

        uint256 contractBalance = balanceOf(address(this));
        bool canSwap = (contractBalance > _swapTokensAtAmount) &&
            (txType == TransactionType.SELL);

        if (
            canSwap &&
            swapEnabled &&
            !_swapping &&
            !_excludedFromFees[from] &&
            !_excludedFromFees[to]
        ) {
            _swapBack(contractBalance);
        }

        _tokenTransfer(from, to, amount, takeFee, txType);
    }

    function _swapBack(uint256 contractBalance) internal lockSwapping {
        bool success;

        if (contractBalance == 0 || _tokensForMarketing == 0) return;

        if (contractBalance > _swapTokensAtAmount.mul(5))
            contractBalance = _swapTokensAtAmount.mul(5);

        _swapTokensForETH(contractBalance);

        _tokensForMarketing = 0;

        (success, ) = address(marketingWalletAddress).call{
            value: address(this).balance
        }("");
    }

    function _swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router02.WETH();
        _approve(address(this), address(_uniswapV2Router02), tokenAmount);
        _uniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _sendETHToFee(uint256 amount) internal {
        marketingWalletAddress.transfer(amount);
    }

    function openTrading() public onlyOwner {
        require(!tradingOpen, "Trading is already open");

        if (block.chainid == 1 || block.chainid == 5)
            _uniswapV2Router02 = IUniswapV2Router02(
                0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            ); // ETH: Uniswap V2
        else if (block.chainid == 56)
            _uniswapV2Router02 = IUniswapV2Router02(
                0x10ED43C718714eb63d5aA57B78B54704E256024E
            ); // BSC Chain: PCS V2
        else if (block.chainid == 42161)
            _uniswapV2Router02 = IUniswapV2Router02(
                0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
            ); // ARB Chain: SushiSwap
        else revert("Chain not set.");

        _approve(address(this), address(_uniswapV2Router02), totalSupply());
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router02.factory())
            .createPair(address(this), _uniswapV2Router02.WETH());
        _uniswapV2Router02.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(_uniswapV2Pair).approve(
            address(_uniswapV2Router02),
            type(uint256).max
        );

        maxBuyAmount = totalSupply().mul(1).div(100);
        maxSellAmount = totalSupply().mul(1).div(100);
        maxWalletAmount = totalSupply().mul(1).div(100);
        _swapTokensAtAmount = totalSupply().mul(5).div(10000);
        swapEnabled = true;
        tradingOpen = true;
        emit OpenTrading();
    }

    function setSwapEnabled(bool onoff) public onlyOwner {
        swapEnabled = onoff;
    }

    function setFeesEnabled(bool onoff) public onlyOwner {
        feesEnabled = onoff;
    }

    function setTransferFeesEnabled(bool onoff) public onlyOwner {
        transferFeesEnabled = onoff;
    }

    function setMaxBuyAmount(uint256 _maxBuyAmount) public onlyOwner {
        require(
            _maxBuyAmount >= (totalSupply().mul(1).div(1000)),
            "Max buy amount cannot be lower than 0.1% total supply."
        );
        maxBuyAmount = _maxBuyAmount;
        emit SetMaxBuyAmount(maxBuyAmount);
    }

    function setMaxSellAmount(uint256 _maxSellAmount) public onlyOwner {
        require(
            _maxSellAmount >= (totalSupply().mul(1).div(1000)),
            "Max sell amount cannot be lower than 0.1% total supply."
        );
        maxSellAmount = _maxSellAmount;
        emit SetMaxSellAmount(maxSellAmount);
    }

    function setMaxWalletAmount(uint256 _maxWalletAmount) public onlyOwner {
        require(
            _maxWalletAmount >= (totalSupply().mul(1).div(1000)),
            "Max wallet amount cannot be lower than 0.1% total supply."
        );
        maxWalletAmount = _maxWalletAmount;
        emit SetMaxWalletAmount(maxWalletAmount);
    }

    function setSwapTokensAtAmount(uint256 swapTokensAtAmount)
        public
        onlyOwner
    {
        require(
            swapTokensAtAmount >= (totalSupply().mul(1).div(1000000)),
            "Swap amount cannot be lower than 0.0001% total supply."
        );
        require(
            swapTokensAtAmount <= (totalSupply().mul(5).div(1000)),
            "Swap amount cannot be higher than 0.5% total supply."
        );
        _swapTokensAtAmount = swapTokensAtAmount;
        emit SetSwapTokensAtAmount(_swapTokensAtAmount);
    }

    function setMarketingWalletAddress(address _marketingWalletAddress)
        public
        onlyOwner
    {
        require(
            _marketingWalletAddress != address(0x0),
            "marketingWalletAddress cannot be 0"
        );
        _excludedFromFees[marketingWalletAddress] = false;
        _excludedFromMaxTxAmount[marketingWalletAddress] = false;
        marketingWalletAddress = payable(_marketingWalletAddress);
        _excludedFromFees[marketingWalletAddress] = true;
        _excludedFromMaxTxAmount[marketingWalletAddress] = true;
    }

    function excludeFromFees(address[] memory accounts, bool isEx)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++)
            _excludedFromFees[accounts[i]] = isEx;
    }

    function excludeFromMaxTxAmount(address[] memory accounts, bool isEx)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++)
            _excludedFromMaxTxAmount[accounts[i]] = isEx;
    }

    function setBuyFee(uint256 _buyMarketingFee) public onlyOwner {
        require(_buyMarketingFee <= 12, "Must keep buy taxes below 12%");
        buyMarketingFee = _buyMarketingFee;
        emit SetBuyFee(buyMarketingFee);
    }

    function setSellFee(uint256 _sellMarketingFee) public onlyOwner {
        require(_sellMarketingFee <= 12, "Must keep sell taxes below 12%");
        sellMarketingFee = _sellMarketingFee;
        emit SetSellFee(sellMarketingFee);
    }

    function setTransferFee(uint256 _transferMarketingFee) public onlyOwner {
        require(
            _transferMarketingFee <= 12,
            "Must keep transfer taxes below 12%"
        );
        transferMarketingFee = _transferMarketingFee;
        emit SetTransferFee(transferMarketingFee);
    }

    function _removeAllFee() internal {
        if (
            buyMarketingFee == 0 &&
            sellMarketingFee == 0 &&
            transferMarketingFee == 0
        ) return;

        _previousBuyMarketingFee = buyMarketingFee;
        _previousSellMarketingFee = sellMarketingFee;
        _previousTransferMarketingFee = transferMarketingFee;

        buyMarketingFee = 0;
        sellMarketingFee = 0;
        transferMarketingFee = 0;
    }

    function _restoreAllFee() internal {
        buyMarketingFee = _previousBuyMarketingFee;
        sellMarketingFee = _previousSellMarketingFee;
        transferMarketingFee = _previousTransferMarketingFee;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee,
        TransactionType txType
    ) internal {
        if (!takeFee) _removeAllFee();
        else amount = _takeFees(sender, amount, txType);

        super._transfer(sender, recipient, amount);

        if (!takeFee) _restoreAllFee();
    }

    function _takeFees(
        address sender,
        uint256 amount,
        TransactionType txType
    ) internal returns (uint256) {
        if (txType == TransactionType.SELL) _sell();
        else if (txType == TransactionType.BUY) _buy();
        else if (txType == TransactionType.TRANSFER) _transfer();
        else revert("Invalid transaction type.");

        uint256 fees;
        if (_totalFees > 0) {
            fees = amount.mul(_totalFees).div(100);
            _tokensForMarketing += (fees.mul(_marketingFee)).div(_totalFees);
        }

        if (fees > 0) super._transfer(sender, address(this), fees);

        return amount -= fees;
    }

    function _sell() internal {
        _marketingFee = sellMarketingFee;
        _totalFees = _marketingFee;
    }

    function _buy() internal {
        _marketingFee = buyMarketingFee;
        _totalFees = _marketingFee;
    }

    function _transfer() internal {
        _marketingFee = transferMarketingFee;
        _totalFees = _marketingFee;
    }

    function fixClog() public onlyOwner lockSwapping {
        _swapTokensForETH(balanceOf(address(this)));
        _tokensForMarketing = 0;
        bool success;
        (success, ) = address(marketingWalletAddress).call{
            value: address(this).balance
        }("");
    }

    function rescueStuckTokens(address tkn) public onlyOwner {
        bool success;
        if (tkn == address(0))
            (success, ) = address(msg.sender).call{
                value: address(this).balance
            }("");
        else {
            require(tkn != address(this), "Cannot withdraw own token");
            require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
            uint256 amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
    }

    function removeLimits() public onlyOwner {
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        maxWalletAmount = totalSupply();
    }
}