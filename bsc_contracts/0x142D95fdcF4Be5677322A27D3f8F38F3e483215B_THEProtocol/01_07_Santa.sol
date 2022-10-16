//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/**
 * $THE Token.
 * https://twitter.com/VitalikButerin/status/1580981360499757056?s=20&t=g1dHPPcLmo8PLzJn8MJOOA
 * A Web3 Community Project Shilled by Anyone Endlessly.
 */
contract THEProtocol is IERC20, Ownable {
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;

    address private constant REWARD =
        0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD

    string private constant NAME = "THE Protocol";
    string private constant SYMBOL = "THE";
    uint8 private constant DECIMALS = 18;

    uint256 private constant ONE_BILLION = 1000000000; // One billion
    uint256 private constant TOTAL_SUPPLY = ONE_BILLION * (10**DECIMALS);

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) isFeeExempt;

    address public marketingWalletAddress;

    // Fees
    uint256 public marketingFee = 1; // 1%
    uint256 public totalFee = 1; // 1%

    IUniswapV2Router02 public router;
    address public pair;

    uint256 public initialContractSwapTime;
    uint256 public lastContractSwapTime;
    uint256 public swapThreshold = (TOTAL_SUPPLY * 1) / 10000; // 0.001% of supply
    bool public contractSwapEnabled = false;
    bool inContractSwap;
    modifier swapping() {
        inContractSwap = true;
        _;
        inContractSwap = false;
    }

    event SetIsFeeExempt(address holder, bool status);
    event SetDoContractSwap(bool status);
    event SwapTokensForBUSD(uint256 tokenAmount, uint256 swappedBUSDAmount);
    event DoContractSwap(uint256 amount, uint256 time);
    event RemoveTax();

    constructor() {
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // mainnet
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        allowances[address(this)][address(router)] = type(uint256).max;

        marketingWalletAddress = 0x77931B200Bfd12bA6b7C8c94d79E044f80AC451F;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[marketingWalletAddress] = true;

        initialContractSwapTime = block.timestamp;
        lastContractSwapTime = block.timestamp;

        balances[msg.sender] = TOTAL_SUPPLY;
        emit Transfer(address(0), msg.sender, TOTAL_SUPPLY);
    }

    receive() external payable {}

    function totalSupply() public pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        allowances[msg.sender][spender] = amount;
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

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (allowances[sender][msg.sender] != type(uint256).max) {
            require(
                allowances[sender][msg.sender] >= amount,
                "Insufficient Allowance"
            );
            allowances[sender][msg.sender] =
                allowances[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function removeTax() internal returns (bool) {
        marketingFee = 0;
        totalFee = 0;

        emit RemoveTax();
        return true;
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
            // We want to remove the tax a year after the token launch.
            bool shouldRemoveTax = ((block.timestamp -
                initialContractSwapTime) > 365 days);
            if (shouldRemoveTax) {
                contractSwapEnabled = false;
                removeTax();
            }
        }

        require(balances[sender] >= amount, "Insufficient Balance");
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
        require(balances[sender] >= amount, "Insufficient Balance");
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
                (block.timestamp >= (lastContractSwapTime + 4 hours)));
    }

    function isFeeExcluded(address wallet) public view returns (bool) {
        return isFeeExempt[wallet];
    }

    function doContractSwap() internal swapping {
        uint256 contractTokenBalance = balances[address(this)];

        swapTokensForBUSD(contractTokenBalance);

        uint256 swappedBUSDAmount = IERC20(REWARD).balanceOf(address(this));

        if (swappedBUSDAmount > 0) {
            IERC20(REWARD).transfer(marketingWalletAddress, swappedBUSDAmount);
        }

        lastContractSwapTime = block.timestamp;

        emit DoContractSwap(swappedBUSDAmount, lastContractSwapTime);
    }

    function swapTokensForBUSD(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WETH();
        path[2] = REWARD;
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of tokens
            path,
            address(this),
            block.timestamp
        );

        emit SwapTokensForBUSD(
            tokenAmount,
            IERC20(REWARD).balanceOf(address(this))
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
}