//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Rabbit is IERC20, Ownable {
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;

    address private constant BUSD_CONTRACT_ADDRESS =
        0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    string private constant NAME = "Rabbit";
    string private constant SYMBOL = "RABBIT";
    uint8 private constant DECIMALS = 18;

    uint256 private constant ONE_BILLION = 1000000000; // One billion
    uint256 private constant TOTAL_SUPPLY = ONE_BILLION * (10**DECIMALS);

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) isFeeExempt;

    address public marketingWalletAddress;

    // This fee will be removed in 2024
    uint256 public marketingFee = 2; // 2%
    uint256 public totalFee = 2; // 2%

    IERC20 public busd;
    IUniswapV2Router02 public router;
    address public pair;

    uint256 public contractCreatedAt;
    uint256 public lastContractSwapTime;
    uint256 private constant SWAP_THRESHOLD_DENOMINATOR = 10000;
    uint256 public swapThreshold =
        (TOTAL_SUPPLY * 1) / SWAP_THRESHOLD_DENOMINATOR;
    bool public contractSwapEnabled = false;
    bool inContractSwap;

    modifier swapping() {
        inContractSwap = true;
        _;
        inContractSwap = false;
    }

    event SetIsFeeExempt(address holder, bool status);
    event EnableContractSwap(bool status);
    event SwapTokensForBusd(uint256 tokenAmount, uint256 busdForMarketing);
    event DoContractSwap(uint256 amount, uint256 time);
    event RemoveTax(uint256 time);

    constructor() {
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        busd = IERC20(BUSD_CONTRACT_ADDRESS);
        allowances[address(this)][address(router)] = type(uint256).max;

        marketingWalletAddress = 0x0d5501aBf378E59A1d3b0a058D5CAe6266f8DaEE;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[marketingWalletAddress] = true;

        contractCreatedAt = block.timestamp;
        lastContractSwapTime = block.timestamp;

        balances[msg.sender] = TOTAL_SUPPLY;
        emit Transfer(address(0), msg.sender, TOTAL_SUPPLY);
    }

    receive() external payable {}

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function totalSupply() external pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function name() external pure returns (string memory) {
        return NAME;
    }

    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return balances[account];
    }

    function isFeeExcluded(address wallet) external view returns (bool) {
        return isFeeExempt[wallet];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowances[holder][spender];
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;

        emit SetIsFeeExempt(holder, exempt);
    }

    function enableContractSwap(bool enable) external onlyOwner {
        contractSwapEnabled = enable;

        emit EnableContractSwap(enable);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Approve: approve from the zero address");
        require(spender != address(0), "Approve: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (allowances[sender][msg.sender] != type(uint256).max) {
            require(
                allowances[sender][msg.sender] >= amount,
                "Transfer: insufficient allowance"
            );
            allowances[sender][msg.sender] =
                allowances[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(
            recipient != ZERO,
            "Transfer: the receiver cannot be ZERO address."
        );

        if (inContractSwap) {
            return basicTransfer(sender, recipient, amount);
        }

        if (shouldDoContractSwap()) {
            doContractSwap();
            // Remove the tax in 2024
            bool shouldRemoveTax = ((block.timestamp - contractCreatedAt) >
                376 days);
            if (shouldRemoveTax) {
                contractSwapEnabled = false;
                removeTax();
            }
        }

        require(balances[sender] >= amount, "Transfer: insufficient balance");
        balances[sender] = balances[sender] - amount;

        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, amount)
            : amount;
        balances[recipient] = balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function takeFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 feeAmount = (amount * totalFee) / 100;

        balances[address(this)] = balances[address(this)] + feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return (amount - feeAmount);
    }

    function basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(balances[sender] >= amount, "Transfer: insufficient balance");
        balances[sender] = balances[sender] - amount;

        balances[recipient] = balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender, address to)
        internal
        view
        returns (bool)
    {
        if (isFeeExempt[sender] || isFeeExempt[to] || totalFee == 0) {
            return false;
        } else {
            return true;
        }
    }

    function shouldDoContractSwap() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inContractSwap &&
            contractSwapEnabled &&
            ((balances[address(this)] >= swapThreshold) ||
                (block.timestamp >= (lastContractSwapTime + 1 hours)));
    }

    function removeTax() internal returns (bool) {
        marketingFee = 0;
        totalFee = 0;

        emit RemoveTax(block.timestamp);
        return true;
    }

    function swapTokensForBusd(uint256 tokenAmount) internal {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WETH();
        path[2] = BUSD_CONTRACT_ADDRESS;
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of tokens
            path,
            address(this),
            block.timestamp
        );

        emit SwapTokensForBusd(tokenAmount, busd.balanceOf(address(this)));
    }

    function doContractSwap() internal swapping {
        uint256 contractTokenBalance = balances[address(this)];

        swapTokensForBusd(contractTokenBalance);

        uint256 busdForMarketing = busd.balanceOf(address(this));

        if (busdForMarketing > 0) {
            busd.transfer(marketingWalletAddress, busdForMarketing);
        }

        lastContractSwapTime = block.timestamp;

        emit DoContractSwap(busdForMarketing, lastContractSwapTime);
    }
}