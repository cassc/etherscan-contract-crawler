// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract THEBARD is Context, ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router private _uniswapV2Router;

    mapping (address => bool) private _excludedFees;
    mapping (address => bool) private _excludedMaxTx;

    bool public tradingEnabled;
    bool public prepareStep;
    bool public firstStep;
    bool public finish;
    bool private _swapping;
    bool public swapEnabled = false;

    uint256 private constant _tSupply = 1e12 ether;

    uint256 public maxSell = _tSupply;
    uint256 public maxWallet = _tSupply;

    uint256 private _fee;

    uint256 public buyFee = 0;
    uint256 private _previousBuyFee = buyFee;

    uint256 public sellFee = 0;
    uint256 private _previousSellFee = sellFee;

    uint256 private _tokensForFee;

    address payable private _feeReceiver;

    address private _uniswapV2Pair;

    modifier lockSwapping {
        _swapping = true;
        _;
        _swapping = false;
    }
    
    constructor() ERC20("The BARD", "BARD") payable {
        _feeReceiver = payable(owner());
        _excludedFees[owner()] = true;
        _excludedFees[address(this)] = true;
        _excludedFees[address(0)] = true;
        _excludedFees[address(0xdead)] = true;

        _excludedMaxTx[owner()] = true;
        _excludedMaxTx[address(this)] = true;
        _excludedMaxTx[address(0)] = true;
        _excludedMaxTx[address(0xdead)] = true;

        _mint(address(this), _tSupply.mul(88).div(100));
        _mint(owner(), _tSupply.mul(12).div(100));
    }

    receive() external payable {}
    fallback() external payable {}

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "BARD: From 0.");
        require(to != address(0), "BARD: To 0.");
        require(amount > 0, "BARD: Amount 0.");

        bool takeFee = true;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_swapping) {
            if(!tradingEnabled) require(_excludedFees[from] || _excludedFees[to]);
            if (from == _uniswapV2Pair && to != address(_uniswapV2Router) && !_excludedMaxTx[to]) require(balanceOf(to) + amount <= maxWallet);
            if (to == _uniswapV2Pair && from != address(_uniswapV2Router) && !_excludedMaxTx[from]) {
                require(amount <= maxSell);
                shouldSwap = true;
            }
        }

        if(_excludedFees[from] || _excludedFees[to]) takeFee = false;

        uint256 contractBalance = balanceOf(address(this));

        if (shouldSwap && swapEnabled && !_swapping && !_excludedFees[from] && !_excludedFees[to]) _swapBack(contractBalance);

        _tokenTransfer(from, to, amount, takeFee, shouldSwap);
    }

    function _swapBack(uint256 contractBalance) internal lockSwapping {
        if (contractBalance == 0 || _tokensForFee == 0) return;
        _swapExactTokensForETHSupportingFeeOnTransferTokens(contractBalance);
        _tokensForFee = 0;
        bool success;
        (success,) = address(_feeReceiver).call{value: address(this).balance}("");
    }

    function _swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp + 14 seconds);
    }

    function go(address defiDEXRouter) public onlyOwner {
        require(!tradingEnabled && prepareStep, "BARD: Trading open.");
        _uniswapV2Router = IUniswapV2Router(defiDEXRouter);
        _approve(address(this), address(_uniswapV2Router), _tSupply);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
        swapEnabled = true;
        maxSell = _tSupply.mul(15).div(1000);
        maxWallet = _tSupply.mul(15).div(1000);
        tradingEnabled = true;
    }

    function prepare() public onlyOwner {
        require(!prepareStep, "BARD: Already used.");
        buyFee = 25;
        sellFee = 25;
        prepareStep = true;
    }

    function decreaseABit() public onlyOwner {
        require(!firstStep, "BARD: Already used.");
        buyFee = 12;
        sellFee = 12;
        firstStep = true;
    }

    function finalStep() public onlyOwner {
        require(!finish, "BARD: Already used.");
        buyFee = 3;
        sellFee = 3;
        finish = true;
    }

    function adjustSwapEnabled(bool booly) public onlyOwner {
        swapEnabled = booly;
    }

    function adjustMaxSell(uint256 _maxSell) public onlyOwner {
        require(_maxSell >= (totalSupply().mul(1).div(1000)), "BARD: No.");
        maxSell = _maxSell;
    }
    
    function adjustMaxWallet(uint256 _maxWallet) public onlyOwner {
        require(_maxWallet >= (totalSupply().mul(1).div(1000)), "BARD: No.");
        maxWallet = _maxWallet;
    }

    function adjustFeeReceiver(address feeReceiver) public onlyOwner {
        require(feeReceiver != address(0));
        _feeReceiver = payable(feeReceiver);
        _excludedFees[_feeReceiver] = true;
        _excludedMaxTx[_feeReceiver] = true;
    }

    function excludeFees(address[] memory accounts, bool booly) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _excludedFees[accounts[i]] = booly;
    }
    
    function excludeMaxTx(address[] memory accounts, bool booly) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _excludedMaxTx[accounts[i]] = booly;
    }

    function adjustBuyFee(uint256 _buyFee) public onlyOwner {
        require(_buyFee <= 25, "BARD: No.");
        buyFee = _buyFee;
    }

    function adjustSellFee(uint256 _sellFee) public onlyOwner {
        require(_sellFee <= 25, "BARD: No.");
        sellFee = _sellFee;
    }

    function _withoutFee() internal {
        if (buyFee == 0 && sellFee == 0) return;
        _previousBuyFee = buyFee;
        _previousSellFee = sellFee;
        buyFee = 0;
        sellFee = 0;
    }
    
    function _withFee() internal {
        buyFee = _previousBuyFee;
        sellFee = _previousSellFee;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) internal {
        if (!takeFee) _withoutFee();
        else amount = _grabFees(sender, amount, isSell);
        super._transfer(sender, recipient, amount);
        if (!takeFee) _withFee();
    }

    function _grabFees(address sender, uint256 amount, bool isSell) internal returns (uint256) {
        if (isSell) _fee = sellFee;
        else _fee = buyFee;
        
        uint256 fees;
        if (_fee > 0) {
            fees = amount.mul(_fee).div(100);
            _tokensForFee += fees * _fee / _fee;
        }

        if (fees > 0) super._transfer(sender, address(this), fees);
        return amount -= fees;
    }

    function unclog() public lockSwapping {
        require(_msgSender() == _feeReceiver, "BARD: No.");
        _swapExactTokensForETHSupportingFeeOnTransferTokens(balanceOf(address(this)));
        _tokensForFee = 0;
        bool success;
        (success,) = address(_feeReceiver).call{value: address(this).balance}("");
    }

    function rescueForeignTokens(address tkn) public {
        require(_msgSender() == _feeReceiver, "BARD: Forbidden.");
        require(tkn != address(this), "BARD: No.");
        bool success;
        if (tkn == address(0)) (success, ) = address(_feeReceiver).call{value: address(this).balance}("");
        else {
            require(IERC20(tkn).balanceOf(address(this)) > 0);
            uint amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
    }

}