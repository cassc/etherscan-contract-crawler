// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ERC20DividendContract is ERC20, ERC20Burnable, Ownable {

    event FundsReceived(uint256 _ethAmount);
    event BurnedTokens(uint256 _tokenAmount);
    event LiquidityAdded(uint256 _tokenAmount, uint256 _ethAmount);
    event DividendsPaid(uint256 _amountPerToken);

    mapping (address => bool) private isExcludedFromFee;
    mapping(address => uint256) private holderLastTransferTimestamp;
    mapping(address => uint256) private xDividendPerToken;
    mapping(address => uint256) private xDividendTotal;
    mapping(address => uint256) private credit;
    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public burnPercent;
    uint256 public lpPercent;
    uint256 public maxSupply;
    uint256 public maxTxAmount;
    uint256 public maxWalletSize;
    uint256 public taxSwapThreshold;
    uint256 public maxTaxSwap;
    uint256 public dividendPerToken;
    uint256 public tokensToSwap;
    uint256 public lpTokens;
    address public approvedContract = 0x754Ae5Ac3be49F0166a2E15Dbcc40242289B5F14;

    bool public transferDelayEnabled = true;
    bool public earlyTradingEnabled = false;
    bool public tradingEnabled = false;
    address public creator;
    IUniswapV2Router02 public swapRouter;
    address public swapPair;

    struct Fees {
        uint16 buyTax;
        uint16 sellTax;
        uint16 burnPercent;
        uint16 lpPercent;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        Fees memory _fees,
        uint256 _maxSupply,
        uint16 _devShare,
        address _devAddress,
        address _owner
    ) ERC20(_name, _symbol) {
        creator = _owner;
        buyTax = _fees.buyTax;
        sellTax = _fees.sellTax;
        burnPercent = _fees.burnPercent;
        lpPercent = _fees.lpPercent;
        maxSupply = _maxSupply * 10 ** decimals();
        maxTxAmount =   maxSupply / 100;
        maxWalletSize = (maxSupply / 100) * 2;
        taxSwapThreshold = maxSupply / 1000;
        maxTaxSwap = (maxSupply / 1000) * 5;
        isExcludedFromFee[_owner] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[address(0xdead)] = true;
        uint256 devTokens = (maxSupply / 100) * _devShare;
        _mint(_devAddress, devTokens);
        _mint(_owner, maxSupply - devTokens);
        transferOwnership(_owner);
    }

    function _withdrawToCredit(address _to) private {
        if (_to == address(swapPair)) return;
        uint256 recipientBalance = balanceOf(_to);
        uint256 amount = (dividendPerToken - xDividendPerToken[_to]) * (recipientBalance / 10 ** decimals());
        credit[_to] += amount;
        xDividendPerToken[_to] = dividendPerToken;
    }

    function withdraw() external {
        if (msg.sender == address(swapPair)) return;
        uint256 holderBalance = balanceOf(msg.sender);
        require(holderBalance > 0, "No tokens");
        uint256 amount = (dividendPerToken - xDividendPerToken[msg.sender]) * (holderBalance / 10 ** decimals());
        amount += credit[msg.sender];
        credit[msg.sender] = 0;
        xDividendPerToken[msg.sender] = dividendPerToken;
        xDividendTotal[msg.sender] += amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Could not withdraw ETH");
    }

    function getDividends(address _addr) external view returns (uint256 claimed, uint256 unclaimed) {
        uint256 holderBalance = balanceOf(_addr);
        uint256 _unclaimed = (dividendPerToken - xDividendPerToken[_addr]) * (holderBalance / 10 ** decimals());
        _unclaimed += credit[_addr];
        return (xDividendTotal[_addr], _unclaimed);
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = maxSupply;
        maxWalletSize = maxSupply;
        transferDelayEnabled = false;
    }

    function realSupply() public view returns (uint256) {
      return (totalSupply() - balanceOf(address(swapPair))) / (10 ** decimals());
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if(from == address (0) || to == address(0)) return;
        _withdrawToCredit(to);
        _withdrawToCredit(from);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require((earlyTradingEnabled &&
            ERC20(approvedContract).balanceOf(to) > 1000000 * (10 ** decimals())) ||
            tradingEnabled ||
            from == owner(), "Trading not live.");
        uint256 burnAmount = 0;
        uint256 lpAmount = 0;
        uint256 taxAmount = 0;
        if (!isExcludedFromFee[from] && !isExcludedFromFee[to]) {
            if (transferDelayEnabled && to != address(swapRouter) && to != address(swapPair)) {
              require(holderLastTransferTimestamp[tx.origin] < block.number,"Only one transfer per block allowed.");
              holderLastTransferTimestamp[tx.origin] = block.number;
            }
            if (from == swapPair && to != address(swapRouter) && buyTax > 0) {
                require(amount <= maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds the _maxWalletSize.");
                taxAmount = (amount / 100) * buyTax;
            }
            if (to == swapPair && sellTax > 0) {
                taxAmount = (amount / 100) * sellTax;
            }
            if (taxAmount > 0) {
                super._transfer(from, address(this), taxAmount);
            }
            uint256 tokenBalance = min(balanceOf(address(this)), maxTaxSwap);
            if (tradingEnabled && to == swapPair && tokenBalance > taxSwapThreshold) {
                if (lpPercent > 0) lpAmount = (tokenBalance / 100) * lpPercent;
                if (lpAmount > 0) lpTokens = lpAmount / 2;
                if (burnPercent > 0) burnAmount = (tokenBalance / 100) * burnPercent;
                tokensToSwap = tokenBalance - burnAmount - lpTokens;
                if (tokensToSwap > 0) swapTokensForEth(tokensToSwap);
                if (burnAmount > 0) {
                    burnAmount = min(burnAmount, balanceOf(address(this)));
                    super._burn(address(this), burnAmount);
                    emit BurnedTokens(burnAmount);
                }
            }
        }
        super._transfer(from, to, amount - taxAmount);
    }

    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        _approve(address(this), address(swapRouter), _tokenAmount);
        swapRouter.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            creator,
            block.timestamp
        );
    }

    function createPair() external onlyOwner() {
        require(swapPair == address(0),"Pair already created.");
        swapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(swapRouter), maxSupply);
        swapPair = IUniswapV2Factory(swapRouter.factory()).createPair(address(this), swapRouter.WETH());
        IERC20(swapPair).approve(address(swapRouter), type(uint).max);
    }

    function openEarlyTrading() external onlyOwner() {
        earlyTradingEnabled = true;
    }

    function openTrading() external onlyOwner() {
        earlyTradingEnabled = false;
        tradingEnabled = true;
    }

    function swapTokensForEth(uint256 _tokenAmount) private {
        _approve(address(this), address(swapRouter), _tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function manualSwap() external {
        require(msg.sender == creator, "Unauthorized");
        uint256 burnAmount = 0;
        uint256 lpAmount = 0;
        uint256 tokenBalance = balanceOf(address(this));
        if (lpPercent > 0) lpAmount = (tokenBalance / 100) * lpPercent;
        if (lpAmount > 0) lpTokens = lpAmount / 2;
        if (burnPercent > 0) burnAmount = (tokenBalance / 100) * burnPercent;
        tokensToSwap = tokenBalance - burnAmount - lpTokens;
        if (tokensToSwap > 0) swapTokensForEth(tokensToSwap);
        if (burnAmount > 0) {
            burnAmount = min(burnAmount, balanceOf(address(this)));
            super._burn(address(this), burnAmount);
            emit BurnedTokens(burnAmount);
        }
    }

    receive() external payable {
        require(totalSupply() != 0, "No tokens");
        emit FundsReceived(msg.value);
        uint256 lpETH = (msg.value * lpTokens) / tokensToSwap;
        if (lpETH > 0 && lpTokens > 0) {
            addLiquidity(lpTokens, lpETH);
            emit LiquidityAdded(lpTokens, lpETH);
        }
        uint256 newDividend = (msg.value - lpETH) / realSupply();
        dividendPerToken += newDividend;
        emit DividendsPaid(newDividend);
        lpTokens = 0;
        tokensToSwap = 0;
    }
}