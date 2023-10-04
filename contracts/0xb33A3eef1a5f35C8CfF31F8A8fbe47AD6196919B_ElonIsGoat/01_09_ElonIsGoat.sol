// SPDX-License-Identifier: MIT
//TG: https://t.me/ElonIsTyping_Portal
//Twitter: https://twitter.com/ElonMusk
//Website: I dont give a fk about this, noone will check it
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
contract ElonIsGoat is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public maxTxAmount;
    uint256 public maxWallet;
    bool private swapEnabled = false;
    bool public inSwap;
    bool public limitsInEffect = true;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isWalletLimitExempt;

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

    IUniswapV2Router02 private uniswapV2Router;
    address public pair;
    bool private tradingOpen;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 tTotalSupply;
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint8 _maxTxAmount,
        uint8 _maxWallet,
        uint256 _teamBuyFee,
        uint256 _teamSellFee,
        address _teamWallet
    ) ERC20(_name, _symbol) {
        tTotalSupply = _totalSupply * 1e18;
        maxTxAmount = (tTotalSupply * _maxTxAmount) / 100;
        maxWallet = (tTotalSupply * _maxWallet) / 100;

        teamFeeBuy = _teamBuyFee * 100;
        totalFeeBuy = teamFeeBuy;

        teamFeeSell = _teamSellFee * 100;
        totalFeeSell = teamFeeSell;

        teamWallet = payable(_teamWallet);

        canAddLiquidityBeforeLaunch[_msgSender()] = true;
        canAddLiquidityBeforeLaunch[address(this)] = true;
        isFeeExempt[msg.sender] = true;
        isWalletLimitExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        isWalletLimitExempt[address(this)] = true;
        _mint(_msgSender(), tTotalSupply);
    }

    receive() external payable {}

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        require(launchedAt == 0, "Already launched");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), tTotalSupply);
        pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
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
        if (shouldSwapBack(sender,recipient)) {
            swapBack();
        }
        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, amount)
            : amount;
        _transfer(sender, recipient, amountReceived);

        return true;
    }

    // Internal Functions
    function shouldSwapBack(address sender, address recipient) internal view returns (bool) {
        return
        !inSwap &&
        swapEnabled &&
        (!isFeeExempt[sender] || !isFeeExempt[recipient]) &&
        launched() &&
        balanceOf(address(this)) > 0 &&
        _msgSender() != pair;

    }

    function swapBack() internal swapping {
        uint256 taxAmount = balanceOf(address(this));
        _approve(address(this), address(uniswapV2Router), taxAmount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(uniswapV2Router.WETH());

        uint256 balanceBefore = address(this).balance;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            taxAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance - balanceBefore;

        teamWallet.sendValue(amountETH); // Send the entire amount to the teamWallet
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

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return (!isFeeExempt[sender] || !isFeeExempt[recipient]) && launched();
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
            recipient != pair &&
            !isWalletLimitExempt[recipient]
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

    function setBuyFees(uint256 _teamFee) external onlyOwner {
        teamFeeBuy = _teamFee;
        totalFeeBuy = _teamFee ;
    }

    function setSellFees(uint256 _teamFee) external onlyOwner {
        teamFeeSell = _teamFee;
        totalFeeSell = _teamFee ;
    }


    function setFeeReceivers(address _teamWallet) external onlyOwner {
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

    function setIsFeeExempt(address[] memory holders, bool[] memory exemptions) external onlyOwner {
        require(holders.length == exemptions.length, "Arrays must have the same length");
        for (uint256 i = 0; i < holders.length; i++) {
            isFeeExempt[holders[i]] = exemptions[i];
        }
    }
    function setIsTxLimitExempt(address[] memory holders, bool[] memory exemptions) external onlyOwner {
        require(holders.length == exemptions.length, "Arrays must have the same length");
        for (uint256 i = 0; i < holders.length; i++) {
            isTxLimitExempt[holders[i]] = exemptions[i];
        }
    }
    function setIsWalletLimitExempt(address[] memory holders, bool[] memory exemptions) external onlyOwner {
        require(holders.length == exemptions.length, "Arrays must have the same length");
        for (uint256 i = 0; i < holders.length; i++) {
            isWalletLimitExempt[holders[i]] = exemptions[i];
        }
    }

    function setSwapBackSettings(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }
}