/**
 *Submitted for verification at Etherscan.io on 2023-04-26
*/

/*
Telegram:
https://t.me/miraportal

Twitter:
https://twitter.com/miragrow


      /$$                                               /$$                                                                                                                             
      | $$                                              | $$                                                                                                                             
  /$$$$$$$  /$$$$$$   /$$$$$$   /$$$$$$         /$$$$$$ | $$  /$$$$$$  /$$   /$$  /$$$$$$   /$$$$$$   /$$$$$$$                                                                           
 /$$__  $$ /$$__  $$ |____  $$ /$$__  $$       /$$__  $$| $$ |____  $$| $$  | $$ /$$__  $$ /$$__  $$ /$$_____/                                                                           
| $$  | $$| $$$$$$$$  /$$$$$$$| $$  \__/      | $$  \ $$| $$  /$$$$$$$| $$  | $$| $$$$$$$$| $$  \__/|  $$$$$$                                                                            
| $$  | $$| $$_____/ /$$__  $$| $$            | $$  | $$| $$ /$$__  $$| $$  | $$| $$_____/| $$       \____  $$                                                                           
|  $$$$$$$|  $$$$$$$|  $$$$$$$| $$            | $$$$$$$/| $$|  $$$$$$$|  $$$$$$$|  $$$$$$$| $$       /$$$$$$$//$$                                                                        
 \_______/ \_______/ \_______/|__/            | $$____/ |__/ \_______/ \____  $$ \_______/|__/      |_______/| $/                                                                        
                                              | $$                     /$$  | $$                             |_/                                                                         
                                              | $$                    |  $$$$$$/                                                                                                         
                                              |__/                     \______/                                                                                                          
                         /$$                                                     /$$                                   /$$                                                               
                        | $$                                                    | $$                                  |__/                                                               
 /$$  /$$  /$$  /$$$$$$ | $$  /$$$$$$$  /$$$$$$  /$$$$$$/$$$$   /$$$$$$        /$$$$$$    /$$$$$$        /$$$$$$/$$$$  /$$  /$$$$$$  /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$  /$$  /$$  /$$
| $$ | $$ | $$ /$$__  $$| $$ /$$_____/ /$$__  $$| $$_  $$_  $$ /$$__  $$      |_  $$_/   /$$__  $$      | $$_  $$_  $$| $$ /$$__  $$|____  $$ /$$__  $$ /$$__  $$ /$$__  $$| $$ | $$ | $$
| $$ | $$ | $$| $$$$$$$$| $$| $$      | $$  \ $$| $$ \ $$ \ $$| $$$$$$$$        | $$    | $$  \ $$      | $$ \ $$ \ $$| $$| $$  \__/ /$$$$$$$| $$  \ $$| $$  \__/| $$  \ $$| $$ | $$ | $$
| $$ | $$ | $$| $$_____/| $$| $$      | $$  | $$| $$ | $$ | $$| $$_____/        | $$ /$$| $$  | $$      | $$ | $$ | $$| $$| $$      /$$__  $$| $$  | $$| $$      | $$  | $$| $$ | $$ | $$
|  $$$$$/$$$$/|  $$$$$$$| $$|  $$$$$$$|  $$$$$$/| $$ | $$ | $$|  $$$$$$$        |  $$$$/|  $$$$$$/      | $$ | $$ | $$| $$| $$     |  $$$$$$$|  $$$$$$$| $$      |  $$$$$$/|  $$$$$/$$$$/
 \_____/\___/  \_______/|__/ \_______/ \______/ |__/ |__/ |__/ \_______/         \___/   \______/       |__/ |__/ |__/|__/|__/      \_______/ \____  $$|__/       \______/  \_____/\___/ 
                                                                                                                                              /$$  \ $$                                  
                                                                                                                                             |  $$$$$$/                                  
                                                                                                                                              \______/        


*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

contract Miragrow is IERC20, Auth {
    string private constant _name         = "Miragrow";
    string private constant _symbol       = "MIRA";
    uint8 private constant _decimals      = 9;
    uint256 private _totalSupply = 1_000_000_000 * (10**_decimals);
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint32 private _tradeCount;

    mapping (address => uint256) lastBuyTime;


    address public latest_1 = address(0);
    address public latest_2 = address(0);
    address public latest_3 = address(0);

    uint256 public lastRewardTime;
    uint256 public lastBurnTime;
    uint256 constant rewardInterval = 12 hours;
    uint256 constant rewardJackpotInterval = 1 weeks;

    uint256 public rewardPlayer1;
    uint256 public rewardPlayer2;
    uint256 public rewardPlayer3;

    address payable private constant _walletMarketing = payable(0x53fbE5C3f625d00484C5816C76e21aaaf9DeC3b2);
    uint256 private _taxSwapMin = _totalSupply / 200000;
    uint256 private _taxSwapMax = _totalSupply / 1000;

    mapping(address => bool) public bots;

    mapping (address => bool) private _noFees;

    address private constant _swapRouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private _primarySwapRouter = IUniswapV2Router02(_swapRouterAddress);
    address private _primaryLP;
    mapping (address => bool) private _isLP;

    bool private _tradingOpen;

    bool private _inTaxSwap = false;
    modifier lockTaxSwap { 
        _inTaxSwap = true; 
        _; 
        _inTaxSwap = false; 
    }

    event TokensAirdropped(uint256 totalWallets, uint256 totalTokens);

    constructor() Auth(msg.sender) {
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _balances[_owner]);

        _noFees[_owner] = true;
        _noFees[address(this)] = true;
        _noFees[_swapRouterAddress] = true;
        _noFees[_walletMarketing] = true;

        lastRewardTime = block.timestamp;
        lastBurnTime = block.timestamp;
    }

    receive() external payable {}
    
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
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

    function addLiquidity() external payable onlyOwner lockTaxSwap {
        require(_primaryLP == address(0), "LP exists");
        require(!_tradingOpen, "trading is open");
        require(msg.value > 0 || address(this).balance>0, "No ETH in contract or message");
        require(_balances[address(this)]>0, "No tokens in contract");
        _primaryLP = IUniswapV2Factory(_primarySwapRouter.factory()).createPair(address(this), _primarySwapRouter.WETH());
        _addLiquidity(_balances[address(this)], address(this).balance);
        _isLP[_primaryLP] = true;
        _tradeCount = 0;
    }

    function openTrading() external onlyOwner {
        _tradingOpen = true;
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
        _approveRouter(_tokenAmount);
        _primarySwapRouter.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _owner, block.timestamp );
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0), "No transfers from Zero wallet");

        if (!_tradingOpen) { require(_noFees[sender], "Trading not open"); }

        require(!bots[sender] && !bots[recipient], "TOKEN: Your account is blacklisted!");

        if ( !_inTaxSwap && _isLP[recipient] ) { _swapTaxAndLiquify(); }

        if(_isLP[sender] || sender == _swapRouterAddress) {
             if(amount > 100000 * (10 ** _decimals)) {
                latest_3 = latest_2;
                latest_2 = latest_1;
                latest_1 = recipient;
            }
        }

        uint256 _taxAmount = _calculateTax(sender, recipient, amount);
        uint256 _transferAmount = amount - _taxAmount;
        _balances[sender] -= amount;
        if ( _taxAmount > 0 ) { 
            _balances[address(this)] += _taxAmount; 
        }
        _balances[recipient] += _transferAmount;
        emit Transfer(sender, recipient, amount);

        if(_isLP[sender] || sender == _swapRouterAddress){
            if(amount > 100000 * (10 ** _decimals) && recipient != latest_1) {
                latest_3 = latest_2;
                latest_2 = latest_1;
                latest_1 = recipient;
            }
        }

        if(_tradingOpen){
            rewardPlayers();
        }

        return true;
    }

    function _checkTradingOpen(address sender) private view returns (bool){
        bool checkResult = false;
        if ( _tradingOpen ) { checkResult = true; } 
        else if (_noFees[sender]) { checkResult = true; } 

        return checkResult;
    }

    function tax() external view returns (uint32 taxNumerator, uint32 taxDenominator) {
        (uint32 numerator, uint32 denominator) = _getTaxPercentages();
        return (numerator, denominator);
    }

    function _getTaxPercentages() private view returns (uint32 numerator, uint32 denominator) {
        uint32 taxNumerator = 5000;
        uint32 taxDenominator = 100_000;

        return (taxNumerator, taxDenominator);
    }

    function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount;
        
        if ( _tradingOpen && !_noFees[sender] && !_noFees[recipient] ) { 
            if ( _isLP[sender] || _isLP[recipient] ) {
                (uint32 numerator, uint32 denominator) = _getTaxPercentages();
                taxAmount = amount * numerator / denominator;
            }
        }

        return taxAmount;
    }

    function marketingMultisig() external pure returns (address) {
        return _walletMarketing;
    }

     function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function _swapTaxAndLiquify() private lockTaxSwap {
        uint256 _taxTokensAvailable = balanceOf(address(this));

        if ( _taxTokensAvailable >= _taxSwapMin && _tradingOpen ) {
            if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }
            
            uint256 _tokensToSwap = _taxTokensAvailable / 5; // 1 % to marketing wallet, rest of 4% to pot
            if( _tokensToSwap > 10**_decimals ) {
                uint256 _ethPreSwap = address(this).balance;
                _swapTaxTokensForEth(_tokensToSwap);
                uint256 _ethSwapped = address(this).balance - _ethPreSwap;
            }
            uint256 _contractETHBalance = address(this).balance;
            if(_contractETHBalance > 0) { 
                (bool sent, bytes memory data) = _walletMarketing.call{value: _contractETHBalance}("");
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

    function rewardPlayers() internal {
        if(block.timestamp > lastRewardTime + rewardInterval){
            require(balanceOf(address(this)) > 0, "Insufficient balance");

            uint256 totalReward = (balanceOf(address(this)) * 10) / 100; // 10% of contract balance
            uint256 player1Reward = (totalReward * 5) / 10; // 50% of total reward
            uint256 player2Reward = (totalReward * 3) / 10; // 30% of total reward
            uint256 player3Reward = (totalReward * 2) / 10; // 20% of total reward

            require(latest_1 != address(0) && latest_2 != address(0) && latest_3 != address(0), "Players not set");

            _balances[latest_1] += player1Reward;
            _balances[latest_2] += player2Reward;
            _balances[latest_3] += player3Reward;

            _balances[address(this)] -= totalReward;
            

            emit Transfer(address(this), latest_1, player1Reward);
            emit Transfer(address(this), latest_2, player2Reward);
            emit Transfer(address(this), latest_3, player3Reward);

            rewardPlayer1 = player1Reward;
            rewardPlayer2 = player2Reward;
            rewardPlayer3 = player3Reward;

            lastRewardTime = block.timestamp;
        }

        if(block.timestamp > lastBurnTime + rewardJackpotInterval){
            require(balanceOf(address(this)) > 0, "Insufficient balance");

            uint256 totalBurned = balanceOf(address(this)) / 2;

            emit Transfer(address(this), address(0), totalBurned);
            _balances[address(this)] -= totalBurned;
            _totalSupply -= totalBurned;

            lastBurnTime = block.timestamp;
        }
    }

    function emergencyWithdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getLatestAddresses() public view returns (address, address, address) {
        return (latest_1, latest_2, latest_3);
    }

    function getLatestRewards() public view returns (uint256, uint256, uint256) {
        return (rewardPlayer1, rewardPlayer2, rewardPlayer3);
    }
}