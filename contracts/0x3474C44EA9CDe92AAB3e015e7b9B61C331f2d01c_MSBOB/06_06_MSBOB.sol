// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@rari-capital/solmate/src/auth/Owned.sol";

import "./interface/IDEXFactory.sol";
import "./interface/IDEXRouter.sol";
import "./interface/IWETH.sol";

contract DividendDistributor {
    address public _token;
    address public immutable dividendToken;

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
    uint256 private accuracyFactor = 10 ** 36;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _dividendToken) {
        _token = msg.sender;
        dividendToken = _dividendToken;
    }

    function setShare(address shareholder, uint256 amount) external onlyToken {
        if (shares[shareholder].amount != 0) {
            distributeDividend(shareholder);
        }

        if (amount != 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount != 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(amount);
    }

    function deposit(uint256 amount) external onlyToken {
        if (amount != 0) {
            totalDividends += amount;
            dividendsPerShare += (accuracyFactor * amount) / totalShares;
        }
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getClaimableDividendOf(shareholder);
        if (amount != 0) {
            totalClaimed += amount;
            shares[shareholder].totalClaimed += amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
            IERC20(dividendToken).transfer(shareholder, amount);
        }
    }

    function claimDividend(address shareholder) external onlyToken {
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

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(
        uint256 share
    ) internal view returns (uint256) {
        return (share * dividendsPerShare) / accuracyFactor;
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

    function getDividendsClaimedOf(
        address shareholder
    ) external view returns (uint256) {
        require(shares[shareholder].amount != 0, "Not a shareholder!");
        return shares[shareholder].totalClaimed;
    }
}

contract MSBOB is IERC20, Owned {
    IDEXRouter private constant router =
        IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap Router
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = address(0);
    address private immutable WETH;
    address public immutable dividendToken; 

    string private constant _name = "MSBOB";
    string private constant _symbol = "MSBOB";
    uint8 private constant _decimals = 9;

    uint256 private _totalSupply = 1_000_000_000 * (10 ** _decimals);
    uint256 public numTokensSell = 5_000 * 10 ** _decimals;
    uint256 public totalFee = 9;
    uint256 public swapRewardPercent = 100;
    address public marketingWallet;

    bool public buyLimit = true;
    uint256 public maxBuy = 10_000_000 * 10 ** _decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public isBot;

    DividendDistributor public distributor;
    address public pair;

    bool public tradingOpen;
    bool public blacklistEnabled;
    bool private inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address _owner,
        address _marketingWallet,
        address _dividendToken
    ) Owned(_owner) {
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _allowances[address(this)][address(router)] = type(uint256).max;

        dividendToken = _dividendToken;
        distributor = new DividendDistributor(_dividendToken);
        marketingWallet = _marketingWallet;

        isFeeExempt[_owner] = true;
        isFeeExempt[_marketingWallet] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
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
    ) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
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
            uint256 currentAllowance = _allowances[sender][msg.sender];
            require(currentAllowance >= amount, "Insufficient allowance");
            _allowances[sender][msg.sender] = currentAllowance - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(
            tradingOpen || sender == owner || recipient == owner,
            "Trading not yet enabled"
        ); //transfers disabled before openTrading

        if (blacklistEnabled) {
            require(!isBot[sender] && !isBot[recipient], "Bot");
        }

        if (buyLimit) {
            if (sender != owner && recipient != owner)
                require(amount <= maxBuy, "Too much sir");
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 contractTokenBal = balanceOf(address(this));
        bool overMinTokenBal = contractTokenBal >= numTokensSell;

        if (
            overMinTokenBal &&
            recipient == pair &&
            balanceOf(address(this)) != 0
        ) {
            swapBack();
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Insufficient Balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, amount)
            : amount;

        _balances[recipient] += amountReceived;

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
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Insufficient Balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
            _balances[recipient] += amount;
        }
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
        uint256 feeAmount = (amount * totalFee) / 100;
        _balances[address(this)] += feeAmount;

        emit Transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }

    function swapBack() internal swapping {
        uint256 tokenBal = balanceOf(address(this));
        uint256 tokenForDividends = (tokenBal * swapRewardPercent) / 100;

        if (tokenForDividends != 0) {
            uint256 balBefore = IERC20(dividendToken).balanceOf(address(distributor));
            swapTokensForDividend(tokenForDividends, address(distributor));
            uint256 balAfter = IERC20(dividendToken).balanceOf(address(distributor));
            distributor.deposit(balAfter - balBefore);
        }

        if (tokenBal - tokenForDividends != 0) {
            swapTokensForETH(tokenBal - tokenForDividends, marketingWallet);
        }
    }

    function swapTokensForDividend(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = WETH;
        path[2] = dividendToken;

        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function swapTokensForETH(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
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

    function claimDividend() external {
        distributor.claimDividend(msg.sender);
    }

    function getClaimableDividendOf(
        address shareholder
    ) public view returns (uint256) {
        return distributor.getClaimableDividendOf(shareholder);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
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

    function checkBot(address account) external view returns (bool) {
        return isBot[account];
    }

    function openTrading() external onlyOwner {
        tradingOpen = true;
    }

    function setBot(address _address, bool toggle) external onlyOwner {
        isBot[_address] = toggle;
        _setIsDividendExempt(_address, toggle);
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

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee <= 14, "Fee cannot exceed 14%");
        totalFee = _fee;
    }

    function manualSend() external onlyOwner {
        payable(marketingWallet).transfer(address(this).balance);
    }

    function claimDividendOf(address holder) external onlyOwner {
        distributor.claimDividend(holder);
    }

    function manualBurn(uint256 amount) external onlyOwner returns (bool) {
        return _basicTransfer(address(this), DEAD, amount);
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function removeBuyLimit() external onlyOwner {
        buyLimit = false;
    }

    function updateBuyLimit(uint256 newLimit) external onlyOwner {
        maxBuy = newLimit;
    }

    function setBlacklistEnabled() external onlyOwner {
        require(blacklistEnabled == false, "can only be called once");
        blacklistEnabled = true;
    }

    function setSwapRewardPercent(uint256 percent) external onlyOwner {
        require(percent <= 100, "Can not exceed 100%");
        swapRewardPercent = percent;
    }

    function setSwapThresholdAmount(uint256 amount) external onlyOwner {
        numTokensSell = amount;
    }
}