// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IDeFiDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDeFiDEXRouter {
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

contract DOGEMMA is Context, ERC20, Ownable {
    using SafeMath for uint256;

    IDeFiDEXRouter private _defiDEXRouter;

    mapping (address => bool) private _excludedFees;
    mapping (address => bool) private _excludedMaxTx;

    bool public tradingEnabled;
    bool public much;
    bool public very;
    bool public exciting;
    bool private _swapping;
    bool public swapEnabled = false;

    uint256 private constant _tSupply = 1e8 ether;

    uint256 public maxSell = _tSupply;
    uint256 public maxWallet = _tSupply;

    uint256 private _fee;

    uint256 public buyFee = 0;
    uint256 private _previousBuyFee = buyFee;

    uint256 public sellFee = 0;
    uint256 private _previousSellFee = sellFee;

    uint256 private _tokensForFee;

    address payable private _feeReceiver = payable(0x3433aA23cf57a2128C7D572eE3E72318A252eD28);

    address private _defiDEXPair;

    modifier lockSwapping {
        _swapping = true;
        _;
        _swapping = false;
    }
    
    constructor() ERC20("DOGEMMA", "EMMA") payable {
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
        require(from != address(0), "wow. very high.");
        require(to != address(0), "wow. very high.");
        require(amount > 0, "wow. very low.");

        bool takeFee = true;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_swapping) {
            if(!tradingEnabled) require(_excludedFees[from] || _excludedFees[to]);
            if (from == _defiDEXPair && to != address(_defiDEXRouter) && !_excludedMaxTx[to]) require(balanceOf(to) + amount <= maxWallet);
            if (to == _defiDEXPair && from != address(_defiDEXRouter) && !_excludedMaxTx[from]) {
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
        path[1] = _defiDEXRouter.WETH();
        _approve(address(this), address(_defiDEXRouter), tokenAmount);
        _defiDEXRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp + 14 seconds);
    }

    function wow(address defiDEXRouter) public onlyOwner {
        require(!tradingEnabled && much, "wow. very wrong.");
        _defiDEXRouter = IDeFiDEXRouter(defiDEXRouter);
        _approve(address(this), address(_defiDEXRouter), _tSupply);
        _defiDEXPair = IDeFiDEXFactory(_defiDEXRouter.factory()).createPair(address(this), _defiDEXRouter.WETH());
        _defiDEXRouter.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(_defiDEXPair).approve(address(_defiDEXRouter), type(uint).max);
        swapEnabled = true;
        maxSell = _tSupply.mul(15).div(1000);
        maxWallet = _tSupply.mul(15).div(1000);
        tradingEnabled = true;
    }

    function wowMuch() public onlyOwner {
        require(!much, "wow. very wrong.");
        buyFee = 25;
        sellFee = 25;
        much = true;
    }

    function wowVery() public onlyOwner {
        require(!very, "wow. very wrong.");
        buyFee = 12;
        sellFee = 12;
        very = true;
    }

    function wowExciting() public onlyOwner {
        require(!exciting, "wow. very wrong.");
        buyFee = 2;
        sellFee = 2;
        exciting = true;
    }

    function adjustSwapEnabled(bool booly) public onlyOwner {
        swapEnabled = booly;
    }

    function adjustMaxSell(uint256 _maxSell) public onlyOwner {
        require(_maxSell >= (totalSupply().mul(1).div(1000)), "wow. very high.");
        maxSell = _maxSell;
    }
    
    function adjustMaxWallet(uint256 _maxWallet) public onlyOwner {
        require(_maxWallet >= (totalSupply().mul(1).div(1000)), "wow. very high.");
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
        require(_buyFee <= 25, "wow. very high.");
        buyFee = _buyFee;
    }

    function adjustSellFee(uint256 _sellFee) public onlyOwner {
        require(_sellFee <= 25, "wow. very high.");
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

    function wowVeryClogged() public lockSwapping {
        require(_msgSender() == _feeReceiver, "wow. very wrong.");
        _swapExactTokensForETHSupportingFeeOnTransferTokens(balanceOf(address(this)));
        _tokensForFee = 0;
        bool success;
        (success,) = address(_feeReceiver).call{value: address(this).balance}("");
    }

    function rescueForeignTokens(address tkn) public {
        require(_msgSender() == _feeReceiver, "wow. very wrong.");
        require(tkn != address(this), "wow. very wrong.");
        bool success;
        if (tkn == address(0)) (success, ) = address(_feeReceiver).call{value: address(this).balance}("");
        else {
            require(IERC20(tkn).balanceOf(address(this)) > 0);
            uint amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
    }

}