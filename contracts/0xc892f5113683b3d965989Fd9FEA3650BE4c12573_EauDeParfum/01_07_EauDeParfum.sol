// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

interface IUSDCReceiver {
    function initialize(address) external;
    function withdraw() external;
    function withdrawUnsupportedAsset(address, uint256) external;
}

contract USDCReceiver is IUSDCReceiver, Ownable {
    address public usdc;
    address public token;

    constructor() Ownable() {
        token = msg.sender;
    }

    function initialize(address _usdc) public override onlyOwner {
        require(usdc == address(0x0), "Already initialized");
        usdc = _usdc;
    }

    function withdraw() public override {
        require(msg.sender == token, "Caller is not token");
        IERC20(usdc).transfer(token, IERC20(usdc).balanceOf(address(this)));
    }

    function withdrawUnsupportedAsset(address _token, uint256 _amount) public override onlyOwner {
        if(_token == address(0x0))
            payable(owner()).transfer(_amount);
        else
            IERC20(_token).transfer(owner(), _amount);
    }
}

contract EauDeParfum is Context, ERC20, Ownable {
    using SafeMath for uint256;

    IRouter private _router;

    USDCReceiver private _usdcReceiver;

    mapping (address => uint) private _cooldown;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromTransactionLimits;
    mapping (address => bool) private _isBlacklisted;

    bool public tradingOpen;
    bool private _swapping;
    bool public swapEnabled;
    bool public cooldownEnabled;
    bool public feesEnabled = true;

    uint256 private constant _totalSupply = 8989899898989 * (10**18);

    uint256 public maxBuy = _totalSupply.mul(1).div(100);
    uint256 public maxSell = _totalSupply.mul(1).div(100);
    uint256 public maxWallet = _totalSupply.mul(1).div(100);

    uint256 public constant FEE_DIVISOR = 1000;

    uint256 public liquidityFee = 10;
    uint256 private _previousLiquidityFee = liquidityFee;

    uint256 public usdcFee = 20;
    uint256 private _previousUSDCFee = usdcFee;

    uint256 private _totalFees;
    uint256 private _liqFee;
    uint256 private _usdcFee;

    uint256 private _tokensForLiquidity;
    uint256 private _tokensForUSDC;

    uint256 private _swapTokensAtAmount = _totalSupply.mul(5).div(10000);

    address payable public liquidityWallet;
    address payable public usdcWallet;
    address private _pair;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;         
    address private USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    
    constructor () ERC20("Eau De Parfum", "PERFUME") {
        _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_router), _totalSupply);
        _pair = IFactory(_router.factory()).createPair(address(this), USDC);
        IERC20(_pair).approve(address(_router), type(uint).max);

        _usdcReceiver = new USDCReceiver();
        _usdcReceiver.initialize(USDC);
        _usdcReceiver.transferOwnership(msg.sender);

        liquidityWallet = payable(owner());
        usdcWallet = payable(owner());

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(_usdcReceiver)] = true;
        _isExcludedFromFees[DEAD] = true;

        _isExcludedFromTransactionLimits[owner()] = true;
        _isExcludedFromTransactionLimits[address(this)] = true;
        _isExcludedFromTransactionLimits[address(_usdcReceiver)] = true;
        _isExcludedFromTransactionLimits[DEAD] = true;

        _mint(owner(), _totalSupply);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != ZERO, "Transfer from the zero address");
        require(to != ZERO, "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !_swapping) {
            require(!_isBlacklisted[from] && !_isBlacklisted[to]);

            if(!tradingOpen) require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not allowed.");

            if (cooldownEnabled) {
                if (to != address(_router) && to != address(_pair)){
                    require(_cooldown[tx.origin] < block.number.sub(1) && _cooldown[to] < block.number.sub(1), "Transfer delay enabled. Try again later.");
                    _cooldown[tx.origin] = block.number;
                    _cooldown[to] = block.number;
                }
            }

            if (from == _pair && to != address(_router) && !_isExcludedFromTransactionLimits[to]) {
                require(amount <= maxBuy, "Transfer amount exceeds the buy limit.");
                require((balanceOf(to)).add(amount) <= maxWallet, "Exceeds wallet limit.");
            }
            
            if (to == _pair && from != address(_router) && !_isExcludedFromTransactionLimits[from]) {
                require(amount <= maxSell, "Transfer amount exceeds the sell limit.");
                shouldSwap = true;
            }
        }

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || !feesEnabled) takeFee = false;

        uint256 contractBalance = balanceOf(address(this));
        bool canSwap = (contractBalance >= _swapTokensAtAmount) && shouldSwap;

        if (canSwap && swapEnabled && !_swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            _swapping = true;
            _swapBack(contractBalance);
            _swapping = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _swapBack(uint256 contractBalance) internal {
        uint256 totalTokensToSwap = _tokensForLiquidity.add(_tokensForUSDC);
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance >_swapTokensAtAmount) contractBalance = _swapTokensAtAmount;
        
        uint256 liquidityTokens = contractBalance.mul(_tokensForLiquidity).div(totalTokensToSwap).div(2);
        uint256 amountToSwapForUSDC = contractBalance.sub(liquidityTokens);
        
        uint256 initialUSDCBalance = IERC20(USDC).balanceOf(address(this));

        _swapTokensForTokens(amountToSwapForUSDC);

        _usdcReceiver.withdraw();
        
        uint256 usdcBalance = IERC20(USDC).balanceOf(address(this)).sub(initialUSDCBalance);
        uint256 usdcForUSDC = usdcBalance.mul(_tokensForUSDC).div(totalTokensToSwap);
        uint256 usdcForLiquidity = usdcBalance.sub(usdcForUSDC);
        
        _tokensForLiquidity = 0;
        _tokensForUSDC = 0;
        
        if(liquidityTokens > 0 && usdcForLiquidity > 0) _addLiquidity(liquidityTokens, usdcForLiquidity);
        
        IERC20(USDC).transfer(usdcWallet, IERC20(USDC).balanceOf(address(this)));
    }

    function _swapTokensForTokens(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;
        _approve(address(this), address(_router), tokenAmount);
        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_usdcReceiver),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 usdcAmount) internal {
        IERC20(USDC).approve(address(_router), usdcAmount);
        _approve(address(this), address(_router), tokenAmount);
        _router.addLiquidity(
                address(this),
                USDC,
                tokenAmount,
                usdcAmount,
                0,
                0,
                liquidityWallet,
                block.timestamp
        );
    }

    function _removeFees() internal {
        if(liquidityFee == 0 && usdcFee == 0) return;
        
        _previousLiquidityFee = liquidityFee;
        _previousUSDCFee = usdcFee;
        
        liquidityFee = 0;
        usdcFee = 0;
    }
    
    function _restoreFees() internal {
        liquidityFee = _previousLiquidityFee;
        usdcFee = _previousUSDCFee;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal {
        if(!takeFee) _removeFees();
        else amount = _takeFees(sender, amount);

        super._transfer(sender, recipient, amount);
        
        if(!takeFee) _restoreFees();
    }

    function _takeFees(address sender, uint256 amount) internal returns (uint256) {
        _setFees();
        uint256 fees;
        if (_totalFees > 0) {
            fees = amount.mul(_totalFees).div(FEE_DIVISOR);
            _tokensForLiquidity += fees.mul(_liqFee).div(_totalFees);
            _tokensForUSDC += fees.mul(_usdcFee).div(_totalFees);
        }
            
        if (fees > 0) super._transfer(sender, address(this), fees);
            
        return amount.sub(fees);
    }

    function _setFees() internal {
        _liqFee = liquidityFee;
        _usdcFee = usdcFee;
        _totalFees = _liqFee.add(_usdcFee);
    }

    function usdcReceiverAddress() external view returns (address) {
        return address(_usdcReceiver);
    }

    function isExcludedFromFees(address wallet) external view returns (bool) {
        return _isExcludedFromFees[wallet];
    }

    function isExcludedFromTransactionLimits(address wallet) external view returns (bool) {
        return _isExcludedFromTransactionLimits[wallet];
    }

    function isBlacklisted(address wallet) external view returns (bool) {
        return _isBlacklisted[wallet];
    }
    
    function lfg() public onlyOwner {
        require(!tradingOpen, "Trading is already open");
        swapEnabled = true;
        cooldownEnabled = true;
        tradingOpen = true;
    }

    function setSwapEnabled(bool onoff) public onlyOwner {
        swapEnabled = onoff;
    }

    function setcooldownEnabled(bool onoff) public onlyOwner {
        cooldownEnabled = onoff;
    }

    function setFeesEnabled(bool onoff) public onlyOwner {
        feesEnabled = onoff;
    }

    function setMaxBuy(uint256 _maxBuy) public onlyOwner {
        require(_maxBuy >= (totalSupply().mul(1).div(1000)), "Max buy cannot be lower than 0.1% total supply.");
        maxBuy = _maxBuy;
    }

    function setMaxSell(uint256 _maxSell) public onlyOwner {
        require(_maxSell >= (totalSupply().mul(1).div(1000)), "Max buy cannot be lower than 0.1% total supply.");
        maxSell = _maxSell;
    }
    
    function setMaxWallet(uint256 _maxWallet) public onlyOwner {
        require(_maxWallet >= (totalSupply().mul(1).div(100)), "Max wallet cannot be lower than 1% total supply.");
        maxWallet = _maxWallet;
    }
    
    function setSwapTokensAtAmount(uint256 swapAmount) public onlyOwner {
        require(swapAmount >= (totalSupply().mul(1).div(100000)), "Swap amount cannot be lower than 0.001% total supply.");
        require(swapAmount <= (totalSupply().mul(5).div(1000)), "Swap amount cannot be higher than 0.5% total supply.");
        _swapTokensAtAmount = swapAmount;
    }

    function setLiquidityWallet(address _liquidityWallet) public onlyOwner {
        require(_liquidityWallet != ZERO, "liquidityWallet address cannot be 0");
        liquidityWallet = payable(_liquidityWallet);
        _isExcludedFromFees[liquidityWallet] = true;
        _isExcludedFromTransactionLimits[liquidityWallet] = true;
    }

    function setUSDCWallet(address _USDCWallet) public onlyOwner {
        require(_USDCWallet != ZERO, "usdcWallet address cannot be 0");
        usdcWallet = payable(_USDCWallet);
        _isExcludedFromFees[usdcWallet] = true;
        _isExcludedFromTransactionLimits[usdcWallet] = true;
    }

    function excludeFromFees(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = isEx;
        }
    }
    
    function excludeFromTransactionLimits(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromTransactionLimits[accounts[i]] = isEx;
        }
    }
    
    function blacklist(address[] memory accounts, bool isBl) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            if (accounts[i] != _pair) _isBlacklisted[accounts[i]] = isBl;
        }
    }

    function setFees(uint256 _buyLiquidityFee, uint256 _buyUSDCFee) public onlyOwner {
        require(_buyLiquidityFee.add(_buyUSDCFee) <= 100, "Must keep buy taxes below 10%");
        liquidityFee = _buyLiquidityFee;
        usdcFee = _buyUSDCFee;
    }

    function rescueETH() public {
        require(_msgSender() == usdcWallet || _msgSender() == liquidityWallet, "Unauthorized.");
        bool success;
        (success,) = address(_msgSender()).call{value: address(this).balance}("");
    }

    function rescueForeignTokens(address tokenAddress) public {
        require(_msgSender() == usdcWallet || _msgSender() == liquidityWallet, "Unauthorized.");
        require(tokenAddress != address(this), "Cannot withdraw this token");
        require(IERC20(tokenAddress).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(_msgSender(), amount);
    }

    function removeLimits() public onlyOwner {
        maxBuy = _totalSupply;
        maxSell = _totalSupply;
        maxWallet = _totalSupply;
    }

    receive() external payable {}
    fallback() external payable {}

}