/**
 *Submitted for verification at Etherscan.io on 2023-08-23
*/

/**
    Website- https://apedeth.vip/
    Twitter- https://twitter.com/Apederc_20
    Telegram- https://t.me/AWITAT

*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

       function transferOwnership(address newOwner) public virtual onlyOwner() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
      
       function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

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

contract APED is Context, IERC20, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee;
    mapping(address => bool) private isBots;
    address payable private MarketingWallet;

    uint256 public swapTaxes = 10;
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals; 
    string private constant _name = "A Wallet I Track Aped This So It Must Be Good";
    string private constant _symbol = "APED";
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    uint256 private _taxSwap = 5000000 * 10**_decimals;
    uint256 public maxTxAmount = 5000000 * 10**_decimals;
    
    uint256 private  genesis_block;
    uint256 private deadline = 0;
    uint256 private launchtax = 99;
    
    IUniswapV2Router02 public uniswapV2Router;
    address private uniswapV2Pair;
    bool public tradingOpen = false;
    bool private inSwap = false;
    bool public swapEnabled = false;
   
    // Events
    event FeesUpdated(uint256 indexed _feeAmount);
    event ExcludeFromFeeUpdated(address indexed account);
    event includeFromFeeUpdated(address indexed account);
    event FeesRecieverUpdated(address indexed _newWallet);
    event SwapThreshouldUpdated(uint256 indexed tokenAmount);
    event SwapBackSettingUpdated(bool indexed state);
    event ERC20TokensRecovered(uint256 indexed _amount);
    event TradingOpenUpdated();
    event ETHBalanceRecovered();
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () {
           if (block.chainid == 56){
     uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PCS BSC Mainnet Router
     }
      else if(block.chainid == 1 || block.chainid == 5){
          uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap ETH Mainnet Router
      }
      else if(block.chainid == 42161){
           uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // Sushi Arbitrum Mainnet Router
      }
     else  if (block.chainid == 97){
     uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // PCS BSC Testnet Router
     }
    else  if (block.chainid == 8453){
     uniswapV2Router = IUniswapV2Router02(0x4cf76043B3f97ba06917cBd90F9e3A2AAC1B306e); // BaseChian rocketSwap Router
     }
    else {
         revert("Wrong Chain Id");
        }
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        
         MarketingWallet = payable(0x3401F189bBBB9F905BFCC9D5BfEBcb011D3F5E99);
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[MarketingWallet] = true;
        _isExcludedFromFee[deadWallet] = true;
        
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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
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
        require(!isBots[from] && !isBots[to], "You can't transfer tokens");
         
         uint256 taxAmount;
         uint256 feeswap;

         if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
              require(tradingOpen,"wait for trading to open");
            }
         
         if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && block.number < genesis_block + deadline){
              feeswap = launchtax;
          }
           
         if (from == uniswapV2Pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
             require(amount <= maxTxAmount, "Max TxAmount is 2%");
          } 
        
          if (from != uniswapV2Pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
             require(amount <= maxTxAmount, "Max TxAmount is 2%");
          }
          
          if(to != uniswapV2Pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
              require(balanceOf(to) + amount <= maxTxAmount, "Max TxAmount is 2%");
          }
  
            taxAmount = amount * (swapTaxes) / (100);
            feeswap = taxAmount;
           
            if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                  feeswap = 0;
         }
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled && contractTokenBalance >= _taxSwap) {
                swapTokensForEth(_taxSwap);
                
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        _balances[from] = _balances[from] - (amount);
        _balances[to] = _balances[to] + (amount - (feeswap));
        emit Transfer(from, to, amount - (feeswap));
        
        if(feeswap > 0){
          _balances[address(this)] = _balances[address(this)] + (feeswap);
          emit Transfer(from, address(this),feeswap);
        }
    } 
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        require(tokenAmount > 0, "amount must be greeter than 0");
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

    function sendETHToFee(uint256 amount) private {
       require(amount > 0, "amount must be greeter than 0");
        MarketingWallet.transfer(amount);
    }

   function excludeFromFee(address account) external onlyOwner {
      require(_isExcludedFromFee[account] != true,"Account is already excluded");
       _isExcludedFromFee[account] = true;
    emit ExcludeFromFeeUpdated(account);
   }
   
    function includeFromFee(address account) external onlyOwner {
         require(_isExcludedFromFee[account] != false, "Account is already included");
        _isExcludedFromFee[account] = false;
     emit includeFromFeeUpdated(account);
    }
   
    function SetFee(uint256 _feeAmount) external onlyOwner {
       require(_feeAmount <= 50, "Must keep fees at 50% or less");
        swapTaxes = _feeAmount;
      emit FeesUpdated(_feeAmount);
   }
    
    function setMarketingWallet(address payable _newWallet) external onlyOwner {
       require(_newWallet != address(this), "CA will not be the Fee Reciever");
       require(_newWallet != address(0), "0 addy will not be the fee Reciever");
       MarketingWallet = _newWallet;
      _isExcludedFromFee[_newWallet] = true;
    emit FeesRecieverUpdated(_newWallet);
    }
    
    function setSwapThreshould(uint256 tokenAmount) external onlyOwner {
        require(tokenAmount <= 1e7, "amount must be less than or equal to 1% of the supply");
        require(tokenAmount >= 1e6, "amount must be greater than or equal to 0.1% of the supply");
        _taxSwap = tokenAmount * 10**_decimals;
    emit SwapThreshouldUpdated(tokenAmount);
    }

   function addBlacklist(address account) external onlyOwner {
        isBots[account] = true;
    }

   function removeBlacklist(address account) external onlyOwner {
        isBots[account] = false;
    }
   
    function removeTxLimits() external onlyOwner {
        maxTxAmount = _tTotal;
    }

   function setMaxTxLimits(uint256 amount) external onlyOwner {
       require(amount >= 1e6, "amount must be greater than or equal to 0.1% of the supply");
        maxTxAmount = amount * 10**_decimals;
    }
   
   function setSwapBackSetting(bool state) external onlyOwner {
        swapEnabled = state;
     emit SwapBackSettingUpdated(state);
    }

  function addLPO() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
  
   function enableTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        swapEnabled = true;
        tradingOpen = true;
       genesis_block = block.number;
            deadline = 3;
      emit TradingOpenUpdated();
    }
    
    receive() external payable {}
   
    function ClearERC20Tokens(address _tokenAddy, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount should be greater than zero");
        require(_amount <= IERC20(_tokenAddy).balanceOf(address(this)), "Insufficient Amount");
        IERC20(_tokenAddy).transfer(MarketingWallet, _amount);
      emit ERC20TokensRecovered(_amount); 
    }
 
 function ClearETHBalance() external {
        uint256 contractETHBalance = address(this).balance;
        require(contractETHBalance > 0, "Amount should be greater than zero");
        require(contractETHBalance <= address(this).balance, "Insufficient Amount");
        payable(address(MarketingWallet)).transfer(contractETHBalance);
      emit ETHBalanceRecovered();
    }
}