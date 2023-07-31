/**
    TokiBot
    Toki Bot is a Telegram bot that was created with the aim of making contract creation accessible to everyone.

    Website: https://tokibot.xyz/
    Twitter: https://twitter.com/tokigenerator
    Telegram: t.me/tokigenerator
    Telegram Bot: t.me/tokigenerator_bot
**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract DeployedByTokiERC20F is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public maxTxAmount;
    uint256 public maxWallet;
    bool public swapEnabled = true;
    bool public inSwap;
    bool public dexInfoFilled = false;
    bool public limitsInEffect = true;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public canAddLiquidityBeforeLaunch;

    uint256 private teamFee;
    uint256 private totalFee;
    uint256 public feeDenominator = 10000;

    uint256 public teamFeeBuy;
    uint256 public totalFeeBuy;

    uint256 public teamFeeSell;
    uint256 public totalFeeSell;

    address payable private teamWallet;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;
    bool private initialized;

    IUniswapV2Router02 private router;
    IWETH public WETH;
    address public pair;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint8 _maxTxAmount,
        uint8 _maxWallet,
        uint256 _buyFee,
        uint256 _sellFee,
        address _teamWallet
    ) ERC20(_name, _symbol) {
        uint256 totalSupply = _totalSupply * 1e18;
        maxTxAmount = (totalSupply * _maxTxAmount) / 100;
        maxWallet = (totalSupply * _maxWallet) / 100;
        teamFeeBuy = _buyFee * 100;
        totalFeeBuy = teamFeeBuy;
        teamFeeSell = _sellFee * 100;
        totalFeeSell = teamFeeSell;
        teamWallet = payable(_teamWallet);
        canAddLiquidityBeforeLaunch[_msgSender()] = true;
        canAddLiquidityBeforeLaunch[address(this)] = true;
        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        _mint(_msgSender(), totalSupply);
    }

    receive() external payable {}

    function setDexInfo(address _router, address _pair) external onlyOwner {
        require(!dexInfoFilled, "Already set");
        router = IUniswapV2Router02(_router);
        pair = _pair;
        WETH = IWETH(router.WETH());
        dexInfoFilled = true;
    }

    function launch() public onlyOwner {
        require(launchedAt == 0, "Already launched");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        return _tokenTransfer(_msgSender(), to, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);
        return _tokenTransfer(sender, recipient, amount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            _transfer(sender, recipient, amount);
            return true;
        }
        if (!canAddLiquidityBeforeLaunch[sender]) {
            require(launched(), "Trading not open yet");
        }

        if (limitsInEffect) {
            checkWalletLimit(recipient, amount);
            checkTxLimit(sender, amount);
        }

        if (sender == pair) {
            buyFees();
        }
        if (recipient == pair) {
            sellFees();
        }
        if (shouldSwapBack()) {
            swapBack();
        }

        uint256 amountReceived = shouldTakeFee(sender)
            ? takeFee(sender, amount)
            : amount;
        _transfer(sender, recipient, amountReceived);

        return true;
    }

    // Internal Functions
    function shouldSwapBack() internal view returns (bool) {
        return
            !inSwap &&
        swapEnabled &&
        launched() &&
        balanceOf(address(this)) > 0 &&
        _msgSender() != pair;
    }

    function swapBack() internal swapping {
        uint256 taxAmount = balanceOf(address(this));
        _approve(address(this), address(router), taxAmount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(WETH);

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            taxAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance - balanceBefore;
        teamWallet.sendValue(amountETH);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function buyFees() internal {
        teamFee = teamFeeBuy;
        totalFee = totalFeeBuy;
    }

    function sellFees() internal {
        teamFee = teamFeeSell;
        totalFee = totalFeeSell;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender] && launched();
    }

    function takeFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = (amount * totalFee) / feeDenominator;
        _transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        if (
            recipient != owner() &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != pair
        ) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= maxWallet,
                "Total Holding is currently limited, you can not buy that much."
            );
        }
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    function rescueToken(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(
            msg.sender,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function clearStuckBalance() external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(_msgSender()).sendValue(amountETH);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply() - balanceOf(DEAD);
    }

    function setBuyFees(
        uint256 _teamFee
    ) external onlyOwner {
        teamFeeBuy = _teamFee;
        totalFeeBuy = _teamFee;
    }

    function setSellFees(
        uint256 _teamFee
    ) external onlyOwner {
        teamFeeSell = _teamFee;
        totalFeeSell = _teamFee;
    }

    function setFeeReceivers(
        address _teamWallet
    ) external onlyOwner {
        teamWallet = payable(_teamWallet);
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        require(amount >= totalSupply() / 100);
        maxWallet = amount;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= totalSupply() / 100);
        maxTxAmount = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setSwapBackSettings(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }
}