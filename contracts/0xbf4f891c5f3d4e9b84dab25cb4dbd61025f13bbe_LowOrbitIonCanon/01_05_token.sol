// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/*
https://twitter.com/LOICoin
https://t.me/LOICeth
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

error Zero_Address(string where);
error Amount_Zero();
error Exceeds_MaxAmount(string Amount);
error In_Cooldown();
error Already_Open();
error Withdraw_Failed();
error Sale_is_not_Safe();

contract LowOrbitIonCanon is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    mapping(address => uint) private cooldown;

    uint256 private constant _tTotal = 1e13 * 10 ** 8;
    uint256 private _buyProjectFee = 1;
    uint256 private _previousBuyProjectFee = _buyProjectFee;
    uint256 private _sellProjectFee = 1;
    uint256 private _previousSellProjectFee = _sellProjectFee;

    address payable private _projectWallet;

    string private constant _name = "Low Orbit Ion Canon";
    string private constant _symbol = "LOIC";
    uint8 private constant _decimals = 9;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    bool public tradingOpen;
    bool private swapping;
    bool private inSwap = false;
    bool private swapFeeForWethEnabled = false;
    bool private preventUnsafeSale = false;
    bool private cooldownEnabled = false;

    uint256 private _maxBuyAmount = _tTotal;
    uint256 private _maxSellAmount = _tTotal;
    uint256 private _maxWalletAmount = _tTotal;
    uint256 private swapTokensForWethAmount = 0;

    event MaxBuyAmountUpdated(uint256 _maxBuyAmount);
    event MaxSellAmountUpdated(uint256 _maxSellAmount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address _uniswapV2Router, address projectWallet) {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
        _projectWallet = payable(projectWallet);
        _rOwned[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_projectWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function setCooldownEnabled() external onlyOwner {
        cooldownEnabled = !cooldownEnabled;
    }

    function setSwapFeeForWethEnabled() external onlyOwner {
        swapFeeForWethEnabled = !swapFeeForWethEnabled;
    }

    function setPreventUnsafeSale() public onlyOwner {
        preventUnsafeSale = !preventUnsafeSale;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == address(0)) revert Zero_Address("owner");
        if (spender == address(0)) revert Zero_Address("spender");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (from == address(0)) revert Zero_Address("transfer_from");
        if (to == address(0)) revert Zero_Address("transfer_to");
        if (amount <= 0) revert Amount_Zero();
        bool takeTaxFee = false;
        bool swapForWeth = false;
        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            !swapping
        ) {
            require(!bots[from] && !bots[to]);

            takeTaxFee = true;
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to] &&
                cooldownEnabled
            ) {
                if (amount >= _maxBuyAmount) revert Exceeds_MaxAmount("Buy");

                if (balanceOf(to) + amount >= _maxWalletAmount)
                    revert Exceeds_MaxAmount("Wallet");
                if (cooldown[to] > block.timestamp) revert In_Cooldown();
                cooldown[to] = block.timestamp + (30 seconds);
            }

            if (
                to == uniswapV2Pair &&
                from != address(uniswapV2Router) &&
                !_isExcludedFromFee[from] &&
                cooldownEnabled
            ) {
                if (preventUnsafeSale) revert Sale_is_not_Safe();
                if (amount >= _maxSellAmount) revert Exceeds_MaxAmount("Sell");
                swapForWeth = true;
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeTaxFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwapWeth = (contractTokenBalance > swapTokensForWethAmount) &&
            swapForWeth;

        if (
            canSwapWeth &&
            swapFeeForWethEnabled &&
            !swapping &&
            !_isExcludedFromFee[from] &&
            !_isExcludedFromFee[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        _tokenTransfer(from, to, amount, takeTaxFee, swapForWeth);
    }

    function swapBack() private {
        uint256 tokensForProject = balanceOf(address(this));

        bool success;

        if (tokensForProject == 0) {
            return;
        }

        if (tokensForProject > swapTokensForWethAmount * 10) {
            tokensForProject = swapTokensForWethAmount * 10;
        }

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(tokensForProject);

        (success, ) = address(_projectWallet).call{
            value: address(this).balance - initialETHBalance
        }("");
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function openTrading() external onlyOwner {
        if (tradingOpen) revert Already_Open();
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp + 10 minutes
        );
        swapFeeForWethEnabled = true;
        cooldownEnabled = true;
        _maxBuyAmount = 1e11 * 10 ** 8;
        _maxSellAmount = 1e11 * 10 ** 8;
        _maxWalletAmount = 3e11 * 10 ** 8;
        swapTokensForWethAmount = 5e5 * 10 ** 8;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function setBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function setMaxBuyAmount(uint256 maxBuy) public onlyOwner {
        _maxBuyAmount = maxBuy;
    }

    function setMaxSellAmount(uint256 maxSell) public onlyOwner {
        _maxSellAmount = maxSell;
    }

    function setMaxWalletAmount(uint256 maxToken) public onlyOwner {
        _maxWalletAmount = maxToken;
    }

    function setSwapTokensForWethAmount(uint256 newAmount) public onlyOwner {
        if (newAmount <= 1e3 * 10 ** 9) revert();
        if (newAmount >= 5e6 * 10 ** 9) revert();
        swapTokensForWethAmount = newAmount;
    }

    function setProjectWallet(address projectWallet) public onlyOwner {
        if (projectWallet == address(0)) revert Zero_Address("wallet");
        _isExcludedFromFee[_projectWallet] = false;
        _projectWallet = payable(projectWallet);
        _isExcludedFromFee[_projectWallet] = true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setBuyFee(uint256 buyProjectFee) external onlyOwner {
        _buyProjectFee = buyProjectFee;
    }

    function setSellFee(uint256 sellProjectFee) external onlyOwner {
        _sellProjectFee = sellProjectFee;
    }

    function removeAllFee() private {
        if (
            _buyProjectFee == 0 &&
            _sellProjectFee == 0 &&
            _previousBuyProjectFee == 0 &&
            _previousSellProjectFee == 0
        ) return;

        _previousBuyProjectFee = _buyProjectFee;
        _previousSellProjectFee = _sellProjectFee;

        _buyProjectFee = 0;
        _sellProjectFee = 0;
    }

    function restoreAllFee() private {
        _buyProjectFee = _previousBuyProjectFee;
        _sellProjectFee = _previousSellProjectFee;
    }

    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeTaxFee,
        bool isSell
    ) private {
        if (!takeTaxFee) {
            removeAllFee();
        } else {
            amount = _takeFees(sender, amount, isSell);
        }

        _transferStandard(sender, recipient, amount);

        if (!takeTaxFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _takeFees(
        address sender,
        uint256 amount,
        bool isSell
    ) private returns (uint256) {
        uint256 pjctFee;
        if (isSell) {
            pjctFee = _sellProjectFee;
        } else {
            pjctFee = _buyProjectFee;
        }

        uint256 tokensForProject = amount.mul(pjctFee).div(100);
        if (tokensForProject > 0) {
            _transferStandard(sender, address(this), tokensForProject);
        }

        return amount -= tokensForProject;
    }

    receive() external payable {}

    function manualswap() public onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function withdrawStuckETH() external onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        if (!success) revert Withdraw_Failed();
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
}