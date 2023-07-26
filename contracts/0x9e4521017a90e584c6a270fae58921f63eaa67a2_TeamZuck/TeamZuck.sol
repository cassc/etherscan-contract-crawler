/**
 *Submitted for verification at Etherscan.io on 2023-07-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
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
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

abstract contract Auth {
    address internal _owner;
    event OwnershipTransferred(address _owner);
    constructor(address creatorOwner) { _owner = creatorOwner; }
    modifier onlyOwner() { require(msg.sender == _owner, "Only owner can call this"); _; }
    function owner() public view returns (address) { return _owner; }
    function renounceOwnership() external onlyOwner { 
        _owner = address(0); 
        emit OwnershipTransferred(address(0)); 
    }
}

contract TeamZuck is IERC20, Auth {
    string private constant _name         = "Team Zuck";
    string private constant _symbol       = "ZUCK";
    uint8 private constant _decimals      = 18;
    uint256 private constant _totalSupply = 1_000_000_000_000 * (10**_decimals);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isBlackListed;
    mapping (address => bool) private _noFees;

    address payable private _walletMarketing;
    address payable private _walletPrizePool;
    address payable private _walletBuyBack;
    uint256 private constant _taxSwapMin = _totalSupply / 200000;
    uint256 private constant _taxSwapMax = _totalSupply / 500;
  
    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    address private _primaryLP;
    mapping (address => bool) private _isLP;
    uint256 private _tax = 500;
    uint256 private _epochForBoostedPrizePool;

    bool public limited = true;
    uint256 public maxHoldingAmount = 10_000_000_001 * (10**_decimals); // 1%
    uint256 public minHoldingAmount = 100_000_000 * (10**_decimals); // 0.01%;
    
    bool private _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap { 
        _inTaxSwap = true; 
        _; 
        _inTaxSwap = false; 
    }

    constructor(address cexWallet, address marketingWallet, address buyBackWallet, address prizePoolWallet) Auth(msg.sender) { 

        _balances[address(cexWallet)] = (_totalSupply / 100 ) * 5;
        _balances[address(marketingWallet)] = (_totalSupply / 100 ) * 5;
        _balances[address(this)] = (_totalSupply / 100 ) * 90;

        emit Transfer(address(0), address(cexWallet), _balances[address(cexWallet)]);
        emit Transfer(address(0), address(marketingWallet), _balances[address(marketingWallet)]);
        emit Transfer(address(0), address(this), _balances[address(this)]);
        
        setMarketingWallet(marketingWallet);
        setBuyBackWallet(buyBackWallet);
        setPrizePoolWallet(prizePoolWallet);

        _noFees[cexWallet] = true;
        _noFees[_walletMarketing] = true;
        _noFees[buyBackWallet] = true;
        _noFees[prizePoolWallet] = true;
        _noFees[_owner] = true;
        _noFees[address(this)] = true;
  
        _epochForBoostedPrizePool = block.timestamp + 12 * 7 * 24 * 3600; // 12 weeks after deployment
    }

    receive() external payable {}
    
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function tax() external view returns (uint256) { return _tax / 100; }
    function prizePoolBoostStart() external view returns (uint256) { return _epochForBoostedPrizePool; }
    function marketingMultisig() external view returns (address) { return _walletMarketing; }
    function BuyBackMultisig() external view returns (address) { return _walletBuyBack; }
    function PrizePoolMultisig() external view returns (address) { return _walletPrizePool; }
    function getPrizePoolBalance() external view returns (uint256){ return address(_walletPrizePool).balance; }
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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");
        require(!isBlackListed[sender], "Sender Blacklisted");
        require(!isBlackListed[recipient], "Receiver Blacklisted");

        if (!_tradingOpen) { require(_noFees[sender], "Trading not open"); }
        if ( !_inTaxSwap && _isLP[recipient] ) { _swapTaxAndLiquify(); }

        if (limited && sender == _primaryLP) {
            require(balanceOf(recipient) + amount <= maxHoldingAmount && balanceOf(recipient) + amount >= minHoldingAmount, "Forbid");
        }

        uint256 _taxAmount = _calculateTax(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] -= amount;
        if ( _taxAmount > 0 ) { 
            _balances[address(this)] += _taxAmount; 
        }
        _balances[recipient] += _transferAmount;
        emit Transfer(sender, recipient, amount);
        return true;
    }    

    function _approveRouter(uint256 _tokenAmount) internal {
        if ( _allowances[address(this)][_swapRouterAddress] < _tokenAmount ) {
            _allowances[address(this)][_swapRouterAddress] = type(uint256).max;
            emit Approval(address(this), _swapRouterAddress, type(uint256).max);
        }
    }

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_primaryLP == address(0), "LP exists");
        require(!_tradingOpen, "trading is open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");
        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(address(this), _primarySwapRouter.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isLP[_primaryLP] = true;
        _tradingOpen = true;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _checkTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_noFees[sender]) { checkResult = true; } 

        return checkResult;
    }

    function setMarketingWallet(address newMarketingWallet) public onlyOwner {
        _walletMarketing = payable(newMarketingWallet);
    }

    function setPrizePoolWallet(address newPrizePoolWallet) public onlyOwner {
        _walletPrizePool = payable(newPrizePoolWallet);
    }

    function setBuyBackWallet(address newBuyBackWallet) public onlyOwner {
        _walletBuyBack = payable(newBuyBackWallet);
    }
 
    function setBlackList(address[] memory _users, bool set) public onlyOwner {
        for(uint256 i = 0; i < _users.length; i++){
            isBlackListed[_users[i]] = set;
        }
    }

    function setRule(bool _limited, uint256 _maxHoldingAmount, uint256 _minHoldingAmount) external onlyOwner {
        limited = _limited;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
    }

    function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {

        uint256 taxAmount;
        if ( _tradingOpen && !_noFees[sender] && !_noFees[recipient] ) { 
            if ( _isLP[sender] || _isLP[recipient] ) {
                taxAmount = amount * _tax / 10000;
            }
        }

        return taxAmount;
    }

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if ( _taxTokensAvailable >= _taxSwapMin && _tradingOpen ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }

            _swapTaxTokensForEth(_taxTokensAvailable);
            uint256 _contractETHBalance = address(this).balance;

            if(_contractETHBalance > 0) { 

                if(block.timestamp < _epochForBoostedPrizePool){
                    // first 12 weeks 

                    // 50% marketing
                    // 50% prize pool
            
                    bool success;
                    (success,) = _walletMarketing.call{value: (_contractETHBalance / 2)}("");
                    require(success);

                    (success,) = _walletPrizePool.call{value: (_contractETHBalance / 2)}("");
                    require(success);

                } else {
                    // after 12 weeks

                    // 20% marketing
                    // 5% buy back
                    // 75% prize pool

                    bool success;
                    (success,) = _walletMarketing.call{value: 20 * (_contractETHBalance / 100)}("");
                    require(success);
                    (success,) = _walletBuyBack.call{value: 5 * (_contractETHBalance / 100)}("");
                    require(success);
                    (success,) = _walletPrizePool.call{value: 75 * (_contractETHBalance / 100)}("");
                    require(success);
                }
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
}