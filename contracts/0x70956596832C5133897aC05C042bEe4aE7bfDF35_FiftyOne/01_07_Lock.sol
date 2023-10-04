//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract FiftyOne is IERC20, Ownable {
    string constant _name = "51";
    string constant _symbol = "51";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 51e9 * (10 ** _decimals);

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isAuthorized;

    address public marketingWallet;
    address private deadAddress = 0x000000000000000000000000000000000000dEaD;

    // Fees

    uint256 public buyMarketingFee = 149;
    uint256 public buyBurnFee = 51;
    uint256 public buyTotalFee = 200;

    uint256 public sellMarketingFee = 149;
    uint256 public sellBurnFee = 51;
    uint256 public sellTotalFee = 200;

    uint256 constant DEVIDEND_FACTOR = 10000;

    IUniswapV2Router02 public router;
    address public pair;

    bool public getTransferFees = false;

    uint256 public swapThreshold = (_totalSupply * 1) / 10000; // 0.001% of supply
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

        marketingWallet = 0xeA7a883B425CA0Ebf213951Ab3cEa0FDe7B4C3A7;

        address deployer = 0xF05015B8fB1eC76Af7c763c4E48f01E56928C0c0;

        isFeeExempt[deployer] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[marketingWallet] = true;

        isAuthorized[deployer] = true;
        isAuthorized[address(this)] = true;

        isAuthorized[marketingWallet] = true;

        _balances[deployer] = _totalSupply;

        transferOwnership(deployer);
        emit Transfer(address(0), deployer, _totalSupply);
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
        uint256 _burnTokens;

        if (recipient == pair) {
            feeToken = (amount * sellTotalFee) / DEVIDEND_FACTOR;
            if (sellBurnFee > 0) {
                _burnTokens = (feeToken * sellBurnFee) / sellTotalFee;
                _balances[deadAddress] = _balances[deadAddress] + _burnTokens;
                emit Transfer(sender, deadAddress, _burnTokens);
            }
            _balances[address(this)] =
                _balances[address(this)] +
                (feeToken - _burnTokens);
            emit Transfer(sender, address(this), (feeToken - _burnTokens));
        } else {
            feeToken = (amount * buyTotalFee) / DEVIDEND_FACTOR;
            if (buyBurnFee > 0) {
                _burnTokens = (feeToken * buyBurnFee) / buyTotalFee;
                _balances[deadAddress] = _balances[deadAddress] + _burnTokens;
                emit Transfer(sender, deadAddress, _burnTokens);
            }
            _balances[address(this)] =
                _balances[address(this)] +
                (feeToken - _burnTokens);
            emit Transfer(sender, address(this), (feeToken - _burnTokens));
        }

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
            sellTotalFee != 0 &&
            _balances[address(this)] >= swapThreshold);
    }

    function isFeeExcluded(address _wallet) public view returns (bool) {
        return isFeeExempt[_wallet];
    }

    function doContractSwap() internal swapping {
        uint256 contractTokenBalance = _balances[address(this)];

        if (contractTokenBalance > 0) {
            swapTokensForEth(contractTokenBalance);

            uint256 swappedTokens = address(this).balance;

            if (swappedTokens > 0)
                payable(marketingWallet).transfer(swappedTokens);
        }
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

    function changeBuyFees(
        uint256 _buyMarketingFee,
        uint256 _buyBurnFee
    ) external onlyOwner {
        buyMarketingFee = _buyMarketingFee;
        buyBurnFee = _buyBurnFee;

        buyTotalFee = _buyMarketingFee + _buyBurnFee;

        require(buyTotalFee <= 1000, "Total fees can not greater than 10%");
    }

    function changeSellFees(
        uint256 _sellMarketingFee,
        uint256 _sellBurnFee
    ) external onlyOwner {
        sellMarketingFee = _sellMarketingFee;
        sellBurnFee = _sellBurnFee;

        sellTotalFee = _sellMarketingFee + _sellBurnFee;

        require(sellTotalFee <= 1000, "Total fees can not greater than 10%");
    }

    function enableTrading() external onlyOwner {
        require(!isTradeEnabled, "Trading already enabled");
        isTradeEnabled = true;
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
}