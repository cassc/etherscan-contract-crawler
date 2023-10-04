//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Tucker is IERC20, Ownable {
    string constant _name = "TUCKER CARLSON";
    string constant _symbol = "$TUCKER";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 100000000000 * (10 ** _decimals); // One hundred billions

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isAuthorized;

    address public taxWallet;

    uint256 public buyTotalFee = 1;

    uint256 public sellTotalFee = 1;

    IUniswapV2Router02 public router;
    address public pair;

    bool public getTransferFees = true;

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

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

    constructor() {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;

        taxWallet = 0xF5573A61D442fd1AABbBB8064EB8F78F6C6BE5a9;

        address newOwner = 0x8Bec0Da68F6476BF8A25897be751A670774CF4A3;

        isFeeExempt[newOwner] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[taxWallet] = true;

        isAuthorized[newOwner] = true;
        isAuthorized[address(this)] = true;
        isAuthorized[taxWallet] = true;

        _balances[newOwner] = _totalSupply;
        emit Transfer(address(0), newOwner, _totalSupply);

        transferOwnership(newOwner);
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

    function shouldDoContractSwap() internal view returns (bool) {
        return (msg.sender != pair &&
            !inContractSwap &&
            contractSwapEnabled &&
            sellTotalFee > 0 &&
            _balances[address(this)] >= swapThreshold);
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeToken;

        if (recipient == pair) feeToken = (amount * sellTotalFee) / 100;
        else feeToken = (amount * buyTotalFee) / 100;

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

    function isFeeExcluded(address _wallet) public view returns (bool) {
        return isFeeExempt[_wallet];
    }

    function doContractSwap() internal swapping {
        uint256 contractTokenBalance = _balances[address(this)];

        swapTokensForEth(contractTokenBalance);

        uint256 swappedTokens = address(this).balance;

        if (swappedTokens > 0) payable(taxWallet).transfer(swappedTokens);
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

    function changeTaxWallet(address _wallet) external onlyOwner {
        taxWallet = _wallet;
    }

    function changeFees(
        uint256 _sellFees,
        uint256 _buyFees
    ) external onlyOwner {
        buyTotalFee = _buyFees;
        sellTotalFee = _sellFees;

        require(
            buyTotalFee <= 10 && sellTotalFee <= 10,
            "Total fees can not greater than 10%"
        );
    }

    function enableTrading() external onlyOwner {
        isTradeEnabled = true;
    }

    function setAuthorizedWallets(
        address _wallet,
        bool _status
    ) external onlyOwner {
        isAuthorized[_wallet] = _status;
    }

    function rescueEth() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No enough ETH to transfer");

        payable(msg.sender).transfer(balance);
    }

    function changeGetFeesOnTransfer(bool _status) external onlyOwner {
        getTransferFees = _status;
    }
}