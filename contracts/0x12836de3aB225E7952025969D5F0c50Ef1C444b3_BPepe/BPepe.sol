/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

//SPDX-License-Identifier: MIT

/*
https://mrburns.vip
https://t.me/MrBurnsProtocol
The one and only true burn token that automatically buys and burns pepe with every buy and sell on Mr.Burns
*/

pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address __owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair); 
}
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

abstract contract Auth {
    address internal _owner;
    constructor(address creatorOwner) { 
        _owner = creatorOwner; 
    }
    modifier onlyOwner() { 
        require(msg.sender == _owner, "Only owner can call this"); 
        _; 
    }
    function owner() public view returns (address) { 
        return _owner; 
    }
    function transferOwnership(address payable newOwner) external onlyOwner { 
        _owner = newOwner; 
        emit OwnershipTransferred(newOwner); 
    }
    function renounceOwnership() external onlyOwner { 
        _owner = address(0); 
        emit OwnershipTransferred(address(0)); 
    }
    event OwnershipTransferred(address _owner);
}

contract BPepe is IERC20, Auth {
    uint8 private constant _decimals      = 9;
    uint256 private constant _totalSupply = 420_690_000 * (10**_decimals);
    string private constant _name         = "Mr Burns";
    string private constant _symbol       = "BPEPE";

    address payable private _walletMarketing = payable(0xE57d4292ec1A8c1dAaD0d52f801735b9eB375864);

    address private _burnToken = address(0x6982508145454Ce325dDbE47a25d4ec3d2311933); 
    address private _burnTokenRouterCA = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 

    IUniswapV2Router02 private _burnSwapRouter = IUniswapV2Router02(_burnTokenRouterCA);
    uint256 private _burnCount;
    uint256 private _totalBurnedTokens;
    uint256 private _totalBurnedEthValue;

    uint8 private antiSnipeTax1 = 90;
    uint8 private antiSnipeTax2 = 33;
    uint8 private antiSnipeBlocks1 = 2;
    uint8 private antiSnipeBlocks2 = 4;

    uint8 private _buyTaxRate  = 4;
    uint8 private _sellTaxRate = 4;

    uint16 private _taxSharesMarketing = 50;
    uint16 private _taxSharesBurn      = 50;
    uint16 private _totalTaxShares = _taxSharesMarketing + _taxSharesBurn;

    address private _walletBurn = address(0x000000000000000000000000000000000000dEaD); 
    address private WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); 

    uint256 private _launchBlock;
    uint256 private _maxTxAmount     = _totalSupply; 
    uint256 private _maxWalletAmount = _totalSupply;
    uint256 private _taxSwapMin = _totalSupply * 10 / 100000;
    uint256 private _taxSwapMax = _totalSupply * 125 / 100000;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _noFees;
    mapping (address => bool) private _noLimits;

    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    address private _primaryLP;
    mapping (address => bool) private _isLP;

    bool private _tradingOpen;

    bool private _locked = false;
    modifier lock { 
        _locked = true; 
        _; 
        _locked = false; 
    }

    event TargetTokensBurned(address indexed tokenCa, uint256 tokenAmount, uint256 ethValue, uint256 totalTokens, uint256 totalEth);

    constructor() Auth(msg.sender) {        
        _balances[address(this)] =  _totalSupply;
        emit Transfer(address(0), address(this), _balances[address(this)]);

        if (_swapRouterAddress.code.length > 0) { WETH = _primarySwapRouter.WETH(); }

        _noFees[_owner] = true;
        _noFees[address(this)] = true;
        _noFees[_swapRouterAddress] = true;
        _noFees[_walletMarketing] = true;
        _noLimits[_owner] = true;
        _noLimits[address(this)] = true;
        _noLimits[_swapRouterAddress] = true;
        _noLimits[_walletMarketing] = true;
    }

    receive() external payable {}
    
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(msg.sender), "Trading not open");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(sender), "Trading not open");
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][_swapRouterAddress] < _tokenAmount ) {
            _allowances[address(this)][_swapRouterAddress] = type(uint256).max;
            emit Approval(address(this), _swapRouterAddress, type(uint256).max);
        }
    }

    function addLiquidity() external payable onlyOwner lock {
        require(_primaryLP == address(0), "LP exists");
        require(!_tradingOpen, "trading is open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");
        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(address(this), _primarySwapRouter.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance, false);
        _isLP[_primaryLP] = true;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn) internal {
        address lpTokenRecipient = _owner;
        if ( autoburn ) { lpTokenRecipient = address(0); }
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lpTokenRecipient, block.timestamp );
    }

    function enableTrading() external onlyOwner {
        _openTrading();
    }

    function _openTrading() internal {
        require(!_tradingOpen, "trading is open");
        require(_primaryLP != address(0), "Must init LP first");
        _maxTxAmount     = _totalSupply * 1 / 100; 
        _maxWalletAmount = _totalSupply * 1 / 100;
        _tradingOpen = true;
        _launchBlock = block.number;
    }


    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        if (!_tradingOpen) { require(_noFees[sender] && _noLimits[sender], "Trading not open"); }
        if ( !_locked && _isLP[recipient] ) { _swapAndProcess(); }
        
        if ( sender != address(this) && recipient != address(this) && sender != _owner ) { require(_checkLimits(sender, recipient, amount), "TX exceeds limits"); }
        uint256 _taxAmount = _calculateTax(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] = _balances[sender] - amount;
        if ( _taxAmount > 0 ) { _balances[address(this)] = _balances[address(this)] + _taxAmount; }
        _balances[recipient] = _balances[recipient] + _transferAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _checkLimits(address sender, address recipient, uint256 transferAmount) internal view returns (bool) {
        bool limitCheckPassed = true;
        if ( _tradingOpen && !_noLimits[sender] && !_noLimits[recipient] ) {
            if ( transferAmount > _maxTxAmount ) { limitCheckPassed = false; }
            else if ( !_isLP[recipient] && (_balances[recipient] + transferAmount > _maxWalletAmount) ) { limitCheckPassed = false; }
        }
        return limitCheckPassed;
    }

    function _checkTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_noFees[sender] && _noLimits[sender]) { checkResult = true; } 

        return checkResult;
    }

    function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        
        if ( !_tradingOpen || _noFees[sender] || _noFees[recipient] ) { 
            taxAmount = 0; 
        } else if ( _isLP[sender] ) { 
            if ( block.number >= _launchBlock + antiSnipeBlocks1 + antiSnipeBlocks2 ) {
                taxAmount = amount * _buyTaxRate / 100; 
            } else if ( block.number >= _launchBlock + antiSnipeBlocks1 ) {
                taxAmount = amount * antiSnipeTax2 / 100;
            } else if ( block.number >= _launchBlock) {
                taxAmount = amount * antiSnipeTax1 / 100;
            }
        } else if ( _isLP[recipient] ) { 
            taxAmount = amount * _sellTaxRate / 100; 
        }

        return taxAmount;
    }


    function exemptFromFees(address wallet) external view returns (bool) {
        return _noFees[wallet];
    } 
    function exemptFromLimits(address wallet) external view returns (bool) {
        return _noLimits[wallet];
    } 
    function setExempt(address wallet, bool noFees, bool noLimits) external onlyOwner {
        if (noLimits || noFees) { require(!_isLP[wallet], "Cannot exempt LP"); }
        _noFees[ wallet ] = noFees;
        _noLimits[ wallet ] = noLimits;
    }

    function buyFee() external view returns(uint8) {
        return _buyTaxRate;
    }
    function sellFee() external view returns(uint8) {
        return _sellTaxRate;
    }

    function feeSplit() external view returns (uint16 marketing, uint16 burns ) {
        return ( _taxSharesMarketing, _taxSharesBurn);
    }
    function setFees(uint8 buy, uint8 sell) external onlyOwner {
        require(buy + sell <= 20, "Roundtrip too high");
        _buyTaxRate = buy;
        _sellTaxRate = sell;
    }  
    function setFeeSplit(uint16 sharesBurn, uint16 sharesMarketing) external onlyOwner {
        _taxSharesBurn = sharesBurn;
        _taxSharesMarketing = sharesMarketing;
        _totalTaxShares = _taxSharesBurn + _taxSharesMarketing;
    }

    function marketingWallet() external view returns (address) {
        return _walletMarketing;
    }

    function setMarketingWallet(address marketing) external onlyOwner {
        require(!_isLP[marketing], "LP cannot be tax wallet");
        
        _walletMarketing = payable(marketing);
        
        _noFees[marketing] = true;
        _noLimits[marketing] = true;
    }

    function maxWallet() external view returns (uint256) {
        return _maxWalletAmount;
    }
    function maxTransaction() external view returns (uint256) {
        return _maxTxAmount;
    }

    function swapAtMin() external view returns (uint256) {
        return _taxSwapMin;
    }
    function swapAtMax() external view returns (uint256) {
        return _taxSwapMax;
    }

    function setLimits(uint16 maxTransactionPermille, uint16 maxWalletPermille) external onlyOwner {
        uint256 newTxAmt = _totalSupply * maxTransactionPermille / 1000 + 1;
        require(newTxAmt >= _maxTxAmount, "tx too low");
        if (newTxAmt > _totalSupply) { newTxAmt = _totalSupply; }
        _maxTxAmount = newTxAmt;
        uint256 newWalletAmt = _totalSupply * maxWalletPermille / 1000 + 1;
        require(newWalletAmt >= _maxWalletAmount, "wallet too low");
        if (newWalletAmt > _totalSupply) { newWalletAmt = _totalSupply; }
        _maxWalletAmount = newWalletAmt;
    }

    function setTaxSwap(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
        _taxSwapMin = _totalSupply * minValue / minDivider;
        _taxSwapMax = _totalSupply * maxValue / maxDivider;
        require(_taxSwapMin>=10**_decimals, "Min too low");
        require(_taxSwapMax>=_taxSwapMin, "Min/Max error");
        require(_taxSwapMax>=_totalSupply / 100000, "Max too low");
        require(_taxSwapMax<=_totalSupply / 50, "Max too high");
    }

    function _burnTokens(address fromWallet, uint256 amount) private {
        if ( amount > 0 ) {
            _balances[fromWallet] -= amount;
            _balances[address(0)] += amount;
            emit Transfer(fromWallet, address(0), amount);
        }
    }

    function _swapAndProcess() private lock {
        uint256 _taxTokensAvailable = balanceOf(address(this));
        if (_tradingOpen) {
            if (_taxTokensAvailable >= _taxSwapMin) {
                if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }
                _swapTaxTokensForEth(_taxTokensAvailable);
            }
            _distributeTaxEth();
        }
    }

    function _distributeTaxEth() private {
        uint256 amount = address(this).balance;
        if ( amount > 10**16 ) { //only distribute if the ETH balance is >0.01
            if (_taxSharesBurn > 0) {
                uint256 ethToSwapAndBurn = amount * _taxSharesBurn / _totalTaxShares;
                _swapAndBurn(ethToSwapAndBurn); 
            }
            if (_taxSharesMarketing > 0) {
                uint256 marketingAmount = amount * _taxSharesMarketing / _totalTaxShares;
                _walletMarketing.transfer(marketingAmount);
            }
        }
    }

    function _swapTaxTokensForEth(uint256 tokenAmount) private {
        _approveRouter(tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _primarySwapRouter.WETH();
        _primarySwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }

    function _swapAndBurn(uint256 ethAmount) private {     
        uint256 balanceBefore = IERC20(_burnToken).balanceOf(_walletBurn);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _burnToken;
        _burnSwapRouter.swapExactETHForTokens{value:ethAmount}(
            0,
            path,
            _walletBurn,
            block.timestamp
        );

        uint256 balanceAfter = IERC20(_burnToken).balanceOf(_walletBurn);
        uint256 burnedTokens = (balanceAfter - balanceBefore);

        _burnCount += 1;
        _totalBurnedTokens += burnedTokens;
        _totalBurnedEthValue += ethAmount;
        emit TargetTokensBurned(_burnToken, burnedTokens, ethAmount, _totalBurnedTokens, _totalBurnedEthValue);
    }

    function burnInfo() external view returns (string memory token, address ca, uint256 burns, uint256 tokensBurned, uint256 ethValue) {
        return ( IERC20(_burnToken).name(), _burnToken, _burnCount, _totalBurnedTokens, _totalBurnedEthValue );
    }

    function manualTaxSwapAndSend(uint8 swapTokenPercent, bool sendEth) external onlyOwner lock {
        require(swapTokenPercent <= 100, "Cannot swap more than 100%");
        uint256 tokensToSwap = balanceOf(address(this)) * swapTokenPercent / 100;
        if (tokensToSwap > 10 ** _decimals) {
            _swapTaxTokensForEth(tokensToSwap);
        }
        if (sendEth) { 
            _distributeTaxEth(); 
        }
    }

}