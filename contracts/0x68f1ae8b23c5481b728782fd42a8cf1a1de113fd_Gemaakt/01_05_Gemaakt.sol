// SPDX-License-Identifier: MIT

//telegram: https://t.me/Gemaaktoken

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

contract Gemaakt is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;

    struct TokenHolder {
        address holder;
        uint256 balance;
    }

    TokenHolder[] tokenHolders;

    uint256 firstBlock;
    uint256 tokenHoldersCount;
    address private uniswapV2Pair;
    address public adminWallet;
    address payable public taxWallet;

    string private constant _name = "\u05d1\u05e0\u05e7 \u05e6\u05d9\u05d5\u05df";
    string private constant _symbol = "Gemaakt";

    uint256 public buyTax = 3; 
    uint256 public sellTax = 3;
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1089 * 10 ** _decimals; // 1089
    uint256 public maxTxAmount = _tTotal.div(100); // 1% of total supply
    uint256 public maxWalletSize = _tTotal.mul(2).div(100); // 2% of total supply
    uint256 public initialTokenAmountForLp = _tTotal; // 100% of total supply
    uint256 public taxSwapThreshold = _tTotal.div(1000); // 0.1% of total supply
    uint256 public maxTaxSwap = _tTotal.div(1000); // 0.1% of total supply

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = false;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExitHolder;
    mapping(address => uint256) private _tokenHolderIndex;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    event MaxTxAmountUpdated(uint maxTxAmount);

    constructor() {
        adminWallet = _msgSender();
        taxWallet = payable(0xb3Ce086ba3c8f45BCD0fcCC1027A0c9F2046Ad41); 

        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[taxWallet] = true;

        setTokenHolders(_msgSender());
        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                require(amount <= maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to) + amount <= maxWalletSize,
                    "Exceeds the maxWalletSize."
                );

                if (firstBlock + 1 > block.number) {
                    require(!isContract(to));
                }
            }

            if (to != uniswapV2Pair && !_isExcludedFromFee[to]) {
                require(
                    balanceOf(to) + amount <= maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > taxSwapThreshold
            ) {
                swapTokensForEth(
                    min(amount, min(contractTokenBalance, maxTaxSwap))
                );
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        uint256 taxAmount = 0;
        if (
            (_isExcludedFromFee[from] || _isExcludedFromFee[to]) ||
            (from != uniswapV2Pair && to != uniswapV2Pair)
        ) {
            taxAmount = 0;
        } else {
            //Set Fee for Buys
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                taxAmount = amount
                    .mul(buyTax)
                    .div(100);
            }

            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                taxAmount = amount
                    .mul(sellTax)
                    .div(100);
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            setTokenHolders(address(this));
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));

        setTokenHolders(from);
        setTokenHolders(to);
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function swapTokensForEth(uint256 _tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function manualswap(uint256 _tokenAmount) external {
        require(
            (msg.sender == adminWallet) || (msg.sender == owner()),
            "Only admin can call this method."
        );
        
        require(
            _tokenAmount <= balanceOf(address(this)),
            "Exceeds the maxWalletSize."
        );
        swapTokensForEth(_tokenAmount);
    }

    function withdrawFees() external {
        require(
            (msg.sender == adminWallet) || (msg.sender == owner()),
            "Only admin can call this method."
        );

        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function setBuyTax(uint256 _buyTax) external onlyOwner {
        buyTax = _buyTax;
    }

    function setSellTax(uint256 _sellTax) external onlyOwner {
        sellTax = _sellTax;
    }

    function setMaxTxAmount(uint256 _maxTxAmount) external onlyOwner {
        maxTxAmount = _maxTxAmount;
    }

    function setMaxWalletSize(uint256 _maxWalletSize) external onlyOwner {
        maxWalletSize = _maxWalletSize;
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _tTotal;
        maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function setMaxTaxSwap(uint256 _maxTaxSwap) external onlyOwner {
        maxTaxSwap = _maxTaxSwap;
    }

    function setTaxSwapThreshold(uint256 _taxSwapThreshold) external onlyOwner {
        taxSwapThreshold = _taxSwapThreshold;
    }

    function toggleSwap(bool _swapEnabled) external onlyOwner {
        swapEnabled = _swapEnabled;
    }

    function sendETHToFee(uint256 _amount) private {
        taxWallet.transfer(_amount);
    }

    function setTokenHolders(address _holder) private {
        if (_isExitHolder[_holder]) {
            uint256 tokenHolderId = _tokenHolderIndex[_holder];
            TokenHolder storage tokenHolder = tokenHolders[tokenHolderId];
            
            tokenHolder.balance = _balances[_holder];
        } else {
            _tokenHolderIndex[_holder] = tokenHoldersCount;
            tokenHolders.push(TokenHolder(_holder, _balances[_holder]));

            _isExitHolder[_holder] = true;
            tokenHoldersCount ++;
        }
    }

    function getHolders() public view returns (TokenHolder[] memory) {
        return tokenHolders;
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        require(balanceOf(address(this)) >= initialTokenAmountForLp, "insufficient token balance");

        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            initialTokenAmountForLp,
            0,
            0,
            address(0),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
        firstBlock = block.number;
    }

      function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    receive() external payable {}
}