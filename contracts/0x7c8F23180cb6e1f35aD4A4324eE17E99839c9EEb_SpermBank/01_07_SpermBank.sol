// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract SpermBank is Context, ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private _uniswapV2Router02;

    mapping (address => bool) private _excludedFees;
    mapping (address => bool) private _excludedMaxTx;

    bool public tradingEnabled = false;
    bool private _swapping = false;
    bool public swapEnabled = false;
    bool public dynamicTaxEnabled = true;

    uint256 private constant _tSupply = 1_000_000_000 ether;

    uint256 public maxBuy = 20_000_000 ether;
    uint256 public maxSell = 20_000_000 ether;
    uint256 public maxWallet = 20_000_000 ether;

    uint256 private _feeApplied;

    uint256 public buyFee = 5;
    uint256 private _previousBuyFee = buyFee;

    uint256 public sellFee = 5;
    uint256 private _previousSellFee = sellFee;

    uint256 private _tokensForFee;
    uint256 private _swapTokensAtAmount = 500_000 ether;

    uint256 public tradingEnabledBlock;

    address payable private _feeReceiver = payable(0x7f7aB9F93d35cbbb907f1280074bB243e4075DDE);

    address private _uniswapV2Pair;
    address constant private DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address constant private ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }
    
    constructor() ERC20("Sperm Bank", "SPERMB") {
        if (block.chainid == 1 || block.chainid == 5) {
            _uniswapV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        } else {
            revert("Invalid chain.");
        }

        _approve(address(this), address(_uniswapV2Router02), _tSupply);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router02.factory()).createPair(address(this), _uniswapV2Router02.WETH());
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router02), type(uint).max);

        _excludedFees[owner()] = true;
        _excludedFees[address(this)] = true;
        _excludedFees[DEAD_ADDRESS] = true;

        _excludedMaxTx[owner()] = true;
        _excludedMaxTx[address(this)] = true;
        _excludedMaxTx[DEAD_ADDRESS] = true;

        _mint(owner(), _tSupply);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != ZERO_ADDRESS, "ERC20: transfer from the zero address");
        require(to != ZERO_ADDRESS, "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;
        bool isSell = false;
        if (from != owner() && to != owner() && to != ZERO_ADDRESS && to != DEAD_ADDRESS && !_swapping) {
            if(!tradingEnabled) {
                require(_excludedFees[from] || _excludedFees[to]);
            }

            if (from == _uniswapV2Pair && to != address(_uniswapV2Router02) && !_excludedMaxTx[to]) {
                require(amount <= maxBuy);
                require(balanceOf(to) + amount <= maxWallet);
            }
            
            if (to == _uniswapV2Pair && from != address(_uniswapV2Router02) && !_excludedMaxTx[from]) {
                require(amount <= maxSell);
                isSell = true;
            }
        }

        if(_excludedFees[from] || _excludedFees[to]) {
            takeFee = false;
        }

        uint256 contractBalance = balanceOf(address(this));
        bool canSwap = (contractBalance > _swapTokensAtAmount) && isSell;

        if (canSwap && swapEnabled && !_swapping && !_excludedFees[from] && !_excludedFees[to]) {
            _getETH(contractBalance);
        }

        _tokenTransfer(from, to, amount, takeFee, isSell);
    }

    function _getETH(uint256 contractBalance) internal lockSwap {
        if (contractBalance == 0 || _tokensForFee == 0) {
            return;
        } else if (contractBalance > _swapTokensAtAmount.mul(5)) {
            contractBalance = _swapTokensAtAmount.mul(5);
        }

        _swapTokensForETH(contractBalance);
        
        _tokensForFee = 0;

        bool succeed;
        (succeed,) = address(_feeReceiver).call{value: address(this).balance}("");
    }

    function _swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router02.WETH();
        _approve(address(this), address(_uniswapV2Router02), tokenAmount);
        _uniswapV2Router02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function _shutdownFee() internal {
        if (buyFee == 0 && sellFee == 0) {
            return;
        }

        _previousBuyFee = buyFee;
        _previousSellFee = sellFee;
        
        buyFee = 0;
        sellFee = 0;
    }
    
    function _turnOnFee() internal {
        buyFee = _previousBuyFee;
        sellFee = _previousSellFee;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) internal {
        if (!takeFee) {
            _shutdownFee();
        } else {
            amount = _takeFees(sender, amount, isSell);
        }

        super._transfer(sender, recipient, amount);
        
        if (!takeFee) {
            _turnOnFee();
        }
    }

    function _takeFees(address sender, uint256 amount, bool isSell) internal returns (uint256) {
        if (isSell) {
            _feeApplied = sellFee;
        } else {
            _feeApplied = buyFee;
        }

        if (dynamicTaxEnabled) {
            bool applyDynamicTax = (block.number <= tradingEnabledBlock.add(90));
            uint256 dynamicTax = tradingEnabledBlock.add(90).sub(block.number);

            if (applyDynamicTax && dynamicTax >= _feeApplied) {
                _feeApplied = dynamicTax;
            }
        }
        
        uint256 fees;
        if (_feeApplied > 0) {
            fees = amount.mul(_feeApplied).div(100);
            _tokensForFee += fees.mul(_feeApplied).div(_feeApplied);
        }

        if (fees > 0) super._transfer(sender, address(this), fees);

        return amount -= fees;
    }
        
    function _sendETHToFee(uint256 amount) internal {
        _feeReceiver.transfer(amount);
    }

    function start() external onlyOwner {
        require(!tradingEnabled);
        swapEnabled = true;
        tradingEnabled = true;
        tradingEnabledBlock = block.number;
    }

    function updateSwapEnabled(bool booly) external onlyOwner {
        swapEnabled = booly;
    }

    function updateDynamicTaxEnabled(bool booly) external onlyOwner {
        dynamicTaxEnabled = booly;
    }

    function updateMaxBuy(uint256 _maxBuy) external onlyOwner {
        require(_maxBuy >= (totalSupply().mul(1).div(1000)));
        maxBuy = _maxBuy;
    }

    function updateMaxSell(uint256 _maxSell) external onlyOwner {
        require(_maxSell >= (totalSupply().mul(1).div(1000)));
        maxSell = _maxSell;
    }
    
    function updateMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet >= (totalSupply().mul(1).div(1000)));
        maxWallet = _maxWallet;
    }
    
    function updateSwapTokensAtAmount(uint256 swapTokensAtAmount) external onlyOwner {
        require(swapTokensAtAmount >= (totalSupply().mul(1).div(100000)));
        require(swapTokensAtAmount <= (totalSupply().mul(5).div(1000)));
        _swapTokensAtAmount = swapTokensAtAmount;
    }

    function updateFeeReceiver(address feeReceiver) external onlyOwner {
        require(feeReceiver != ZERO_ADDRESS);
        _excludedFees[_feeReceiver] = false;
        _excludedMaxTx[_feeReceiver] = false;
        _feeReceiver = payable(feeReceiver);
        _excludedFees[_feeReceiver] = true;
        _excludedMaxTx[_feeReceiver] = true;
    }

    function excludeFees(address[] memory accounts, bool booly) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _excludedFees[accounts[i]] = booly;
        }
    }
    
    function excludeMaxTx(address[] memory accounts, bool booly) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _excludedMaxTx[accounts[i]] = booly;
        }
    }

    function updateBuyFee(uint256 _buyFee) external onlyOwner {
        require(_buyFee <= 15);
        buyFee = _buyFee;
    }

    function updateSellFee(uint256 _sellFee) external onlyOwner {
        require(_sellFee <= 15);
        sellFee = _sellFee;
    }
    
    function unclog() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        _swapTokensForETH(contractBalance);
        bool succeed;
        (succeed,) = address(_feeReceiver).call{value: address(this).balance}("");
    }

    function rescueForeignTokens(address tkn) external onlyOwner {
        require(tkn != address(this));
        if (tkn == ZERO_ADDRESS) {
            bool succeed;
            (succeed, ) = address(msg.sender).call{value: address(this).balance}("");
        } else {
            require(IERC20(tkn).balanceOf(address(this)) > 0);
            uint amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
    }

    receive() external payable {}
    fallback() external payable {}

}