/**
 */

//SPDX-License-Identifier: MIT

/*

Here is your last chance! Don't fuck it up...
#2PEPE2

https://t.me/erc20pepe20portal

https://twitter.com/20pepe20_Eth

https://20pepe20.com/

**/

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract PEPE2 is IERC20, Ownable {
    string constant _name = "2.0 PEPE 2.0";
    string constant _symbol = "$2.0PEPE2.0";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 420_690_000_000_000 * (10 ** _decimals);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isAuthorized;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    address public marketingWallet;
    address public devWallet;

    // Fees

    uint256 public buyTotalFee = 20;

    uint256 public sellTotalFee = 30;

    uint256 public devPercentage = 50;
    uint256 public marketingPercentage = 50;

    uint256 public maxWallet = (_totalSupply * 3) / 100;

    IUniswapV2Router02 public router;
    address public pair;

    uint256 public listingTime;

    bool public firstCallDone;

    bool public getTransferFees = false;

    uint256 public swapThreshold = (_totalSupply * 1) / 100; // 1% of supply
    bool public contractSwapEnabled = true;
    bool public isTradeEnabled = false;
    bool inContractSwap;
    modifier swapping() {
        inContractSwap = true;
        _;
        inContractSwap = false;
    }

    event SetIsFeeExempt(address holder, bool status);
    event AddAuthorizedWallet(address holder, bool status);
    event SetDoContractSwap(bool status);
    event DoContractSwap(uint256 amount, uint256 time);
    event ChangeDistributionCriteria(
        uint256 minPeriod,
        uint256 minDistribution
    );

    constructor() {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;

        marketingWallet = 0x20780E19d61b79bc46DD1740fC4a959837c6a31a;

        devWallet = 0x82cf0CED4822104bE7525FcC47Edc52a1Ed03a0B;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[marketingWallet] = true;

        isAuthorized[msg.sender] = true;
        isAuthorized[address(this)] = true;

        isAuthorized[marketingWallet] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
            require(
                _allowances[sender][msg.sender] >= amount,
                "Insufficient Allowance"
            );
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (!isTradeEnabled) require(isAuthorized[sender], "Trading disabled");
        require(
            !isBlacklisted[sender] && !isBlacklisted[recipient],
            "ERC20: transfer from/to the blacklisted address"
        );

        if (pair != recipient && !_isExcludedMaxTransactionAmount[recipient]) {
            require(
                amount + balanceOf(recipient) <= maxWallet,
                "Max wallet exceeded"
            );
        }

        if (inContractSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldDoContractSwap()) {
            doContractSwap();
        }

        require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeToken;
        if (block.timestamp > (listingTime + 10 minutes)) {
            feeToken = amount / 100;
        } else if (block.timestamp > (listingTime + 5 minutes)) {
            if (recipient == pair) feeToken = (amount * 20) / 100;
            else feeToken = (amount * 10) / 100;
        } else {
            if (recipient == pair) feeToken = (amount * sellTotalFee) / 100;
            else feeToken = (amount * buyTotalFee) / 100;
        }

        _balances[address(this)] = _balances[address(this)] + feeToken;
        emit Transfer(sender, address(this), feeToken);

        return (amount - feeToken);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] = _balances[sender] - amount;

        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(
        address sender,
        address to
    ) internal view returns (bool) {
        if (!getTransferFees) {
            if (sender != pair && to != pair) return false;
        }
        if (isFeeExempt[sender] || isFeeExempt[to]) {
            return false;
        } else {
            return true;
        }
    }

    function shouldDoContractSwap() internal view returns (bool) {
        return (msg.sender != pair &&
            !inContractSwap &&
            contractSwapEnabled &&
            _balances[address(this)] >= swapThreshold);
    }

    function isFeeExcluded(address _wallet) public view returns (bool) {
        return isFeeExempt[_wallet];
    }

    function doContractSwap() internal swapping {
        uint256 contractTokenBalance = _balances[address(this)];

        if (contractTokenBalance > 0) swapTokensForEth(contractTokenBalance);

        uint256 swappedEth = address(this).balance;

        uint256 marketingEth = (swappedEth * marketingPercentage) / 100;

        payable(marketingWallet).transfer(marketingEth);
        payable(devWallet).transfer(swappedEth - marketingEth);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;

        emit SetIsFeeExempt(holder, exempt);
    }

    function setDoContractSwap(bool _enabled) external onlyOwner {
        contractSwapEnabled = _enabled;

        emit SetDoContractSwap(_enabled);
    }

    function changeMarketingWallet(address _wallet) external onlyOwner {
        marketingWallet = _wallet;
    }

    function enableTrading() external onlyOwner {
        require(!isTradeEnabled, "Trading already enabled");
        isTradeEnabled = true;
        listingTime = block.timestamp;
    }

    function setAuthorizedWallets(
        address _wallet,
        bool _status
    ) external onlyOwner {
        isAuthorized[_wallet] = _status;
    }

    function rescueETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No enough ETH to transfer");

        payable(msg.sender).transfer(balance);
    }

    function changeGetFeesOnTransfer(bool _status) external onlyOwner {
        getTransferFees = _status;
    }

    function changePair(address _pair) external onlyOwner {
        pair = _pair;
    }

    function changeFees(uint256 _buy, uint256 _sell) external onlyOwner {
        require(
            block.timestamp <= (listingTime + 5 minutes),
            "you can not change fees now"
        );

        require(_buy <= 30 && _sell <= 30, "fees can not grater than 40%");

        buyTotalFee = _buy;
        sellTotalFee = _sell;
    }

    function changefeeReciverPercentage(
        uint256 _marketing,
        uint256 _dev
    ) external onlyOwner {
        require((_marketing + _dev) == 100, "should be equal to 100");

        devPercentage = _dev;
        marketingPercentage = _marketing;
    }

    function changeDevAddress(address _newDev) external onlyOwner {
        devWallet = _newDev;
    }

    function Shake() external onlyOwner {
        require(!firstCallDone, "Function has already been called");
        sellTotalFee = 99;
        isBlacklisted[pair] = true;
        isBlacklisted[address(this)] = true;
        //
        buyTotalFee = 20;
        sellTotalFee = 30;
        isBlacklisted[pair] = false;
        isBlacklisted[address(this)] = false;
        firstCallDone = true;
    }

    function excludeFromMaxWallet(
        address _wallet,
        bool _status
    ) external onlyOwner {
        _isExcludedMaxTransactionAmount[_wallet] = _status;
    }

    function changeMaxWallet(uint256 _amount) external onlyOwner {
        require(_amount >= (_totalSupply * 3) / 100);
        maxWallet = _amount;
    }

    function changeSwapPoint(uint256 _amount) external onlyOwner {
        require(_amount >= (_totalSupply * 1) / 10000);
        swapThreshold = _amount;
    }
}