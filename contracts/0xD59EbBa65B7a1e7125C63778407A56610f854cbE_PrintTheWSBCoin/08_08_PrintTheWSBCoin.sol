// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.13;

/**
 * 
 * 
 /$$      /$$  /$$$$$$  /$$$$$$$  /$$$$$$$ 
| $$  /$ | $$ /$$__  $$| $$__  $$| $$__  $$
| $$ /$$$| $$| $$  \__/| $$  \ $$| $$  \ $$
| $$/$$ $$ $$|  $$$$$$ | $$$$$$$ | $$$$$$$/
| $$$$_  $$$$ \____  $$| $$__  $$| $$____/ 
| $$$/ \  $$$ /$$  \ $$| $$  \ $$| $$      
| $$/   \  $$|  $$$$$$/| $$$$$$$/| $$      
|__/     \__/ \______/ |_______/ |__/      
 * 
 * https://twitter.com/PrintTheWSBCoin
 * https://t.me/wallstreetprinter
 * https://www.reddit.com/r/wallstreetbets/
 * 
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IDividendDistributor {
    function setShare(address shareholder, uint256 amount) external;

    function deposit(uint256 amount) external;

    function claimDividend(address shareholder) external;

    function getDividendsClaimedOf(
        address shareholder
    ) external returns (uint256);
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address public _token;
    address public _owner;
    address public immutable WSB =
        address(0x0414D8C87b271266a5864329fb4932bBE19c0c49);

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalClaimed;
    }

    address[] private shareholders;
    mapping(address => uint256) private shareholderIndexes;

    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalClaimed;
    uint256 public dividendsPerShare;
    uint256 private dividendsPerShareAccuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(address owner) {
        _token = msg.sender;
        _owner = owner;
    }

    receive() external payable {}

    function setShare(
        address shareholder,
        uint256 amount
    ) external override onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit(uint256 amount) external override onlyToken {
        if (amount > 0) {
            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(
                dividendsPerShareAccuracyFactor.mul(amount).div(totalShares)
            );
        }
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }
        uint256 amount = getClaimableDividendOf(shareholder);
        if (amount > 0) {
            totalClaimed = totalClaimed.add(amount);
            shares[shareholder].totalClaimed = shares[shareholder]
                .totalClaimed
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
            IERC20(WSB).transfer(shareholder, amount);
        }
    }

    function claimDividend(address shareholder) external override onlyToken {
        distributeDividend(shareholder);
    }

    function getClaimableDividendOf(
        address shareholder
    ) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(
        uint256 share
    ) internal view returns (uint256) {
        return
            share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function manualSend(uint256 amount, address holder) external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(holder).transfer(amount > 0 ? amount : contractETHBalance);
    }

    function getDividendsClaimedOf(
        address shareholder
    ) external view returns (uint256) {
        require(
            shares[shareholder].amount > 0,
            "Go buy some tokens!"
        );
        return shares[shareholder].totalClaimed;
    }
}


contract PrintTheWSBCoin is IERC20Metadata, Ownable {
    using SafeMath for uint256;

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public immutable WSB =
        address(0x0414D8C87b271266a5864329fb4932bBE19c0c49);

    string private constant _name = "Print The WSB Coin";
    string private constant _symbol = "WSBP";
    uint8 private constant _decimals = 18;

    uint256 private _totalSupply = 69420000000 * (10 ** _decimals);
    uint256 private _maxTxAmountBuy = _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private isFeeExempt;
    mapping(address => bool) private isDividendExempt;

    uint256 private constant PRINTER_FEE = 9;
    uint256 private feeDenominator = 100;

    address payable public marketingWallet;

    IUniswapV2Router02 public uniswapV2Router;
    address public pair;

    uint256 public launchedAt;
    bool private tradingOpen;
    bool private buyLimit = true;
    uint256 private maxBuy = 2082600000 * (10 ** _decimals); // 3%
    uint256 public swapThreshold = 277680000 * 10 ** _decimals;

    DividendDistributor private distributor;

    bool private inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _marketingAddr) {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _allowances[address(this)][address(uniswapV2Router)] = type(uint256).max;

        distributor = new DividendDistributor(msg.sender);
        
        marketingWallet = payable(_marketingAddr);

        isFeeExempt[msg.sender] = true;
        isFeeExempt[marketingWallet] = true;

        
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function setUniswapV2Pair(address _pair) external onlyOwner {
      pair = _pair;
      isDividendExempt[_pair] = true;
    }
    function setRouter(address _router) external onlyOwner {
      uniswapV2Router = IUniswapV2Router02(_router);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (sender != owner() && recipient != owner())
            require(tradingOpen, "Trading has not started");
        if (buyLimit) {
            if (sender != owner() && recipient != owner())
                require(amount <= maxBuy, "Easy let some for others");
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >=
            swapThreshold;

        bool shouldSwapBack = (overMinTokenBalance &&
            recipient == pair &&
            balanceOf(address(this)) > 0);
        if (shouldSwapBack) {
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Get more money"
        );

        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, amount)
            : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (sender != pair && !isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if (recipient != pair && !isDividendExempt[recipient]) {
            try
                distributor.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Get more money"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(
        address sender,
        address recipient
    ) internal view returns (bool) {
        return (!(isFeeExempt[sender] || isFeeExempt[recipient]) &&
            (sender == pair || recipient == pair));
    }

    function takeFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount;
        feeAmount = amount.mul(PRINTER_FEE).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = balanceOf(address(this));
        
        swapTokensForEth(amountToSwap.div(2));
        swapTokensForWSB(amountToSwap.div(2));

        uint256 dividends = IERC20(WSB).balanceOf(address(this));

        bool success = IERC20(WSB).transfer(address(distributor), dividends);

        if (success) {
            distributor.deposit(dividends);
        }
        payable(marketingWallet).transfer(address(this).balance);
    }

    function swapTokensForWSB(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = WETH;
        path[2] = WSB;

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function openTrading() external onlyOwner {
        launchedAt = block.number;
        tradingOpen = true;
    }

    function _setIsDividendExempt(address holder, bool exempt) internal {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsDividendExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        _setIsDividendExempt(holder, exempt);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function manualSend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        payable(marketingWallet).transfer(contractETHBalance);
    }

    function claimDividend() external {
        distributor.claimDividend(msg.sender);
    }

    function claimDividend(address holder) external onlyOwner {
        distributor.claimDividend(holder);
    }

    function getClaimableDividendOf(
        address shareholder
    ) public view returns (uint256) {
        return distributor.getClaimableDividendOf(shareholder);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = payable(_marketingWallet);
    }

    function getTotalDividends() external view returns (uint256) {
        return distributor.totalDividends();
    }

    function getTotalClaimed() external view returns (uint256) {
        return distributor.totalClaimed();
    }

    function getDividendsClaimedOf(
        address shareholder
    ) external view returns (uint256) {
        return distributor.getDividendsClaimedOf(shareholder);
    }

    function removeBuyLimit() external onlyOwner {
        buyLimit = false;
    }

    function setSwapThresholdAmount(uint256 amount) external onlyOwner {
        swapThreshold = amount;
    }
}