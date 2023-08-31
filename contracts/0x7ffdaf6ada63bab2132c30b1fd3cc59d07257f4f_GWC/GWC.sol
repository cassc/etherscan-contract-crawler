/**
 *Submitted for verification at Etherscan.io on 2023-07-06
*/

/*

 

       $$$$$$\  $$\      $$\  $$$$$$\  
      $$  __$$\ $$ | $\  $$ |$$  __$$\ 
      $$ /  \__|$$ |$$$\ $$ |$$ /  \__|
      $$ |$$$$\ $$ $$ $$\$$ |$$ |      
      $$ |\_$$ |$$$$  _$$$$ |$$ |      
      $$ |  $$ |$$$  / \$$$ |$$ |  $$\ 
      \$$$$$$  |$$  /   \$$ |\$$$$$$  |
       \______/ \__/     \__| \______/ 
                                              

* Telegram: https://t.me/greenwhalechallenge
* Website: https://greenwhalechallenge.com
* Discord: https://discord.gg/greenwhalechallenge
* Twitter: https://twitter.com/gwctoken

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

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
    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract GWC is Context, IERC20, Ownable {

    using SafeMath for uint256;
    
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _walletExcluded;
    
    uint256 private constant MAX = ~uint256(0);
    
    uint8 private constant _decimals = 18;

    uint256 private constant _totalSupply = 1000000000 * 10**_decimals;
    //Swap Threshold (0.04%)
    uint256 private constant minSwap = 4000 * 10**_decimals;
    //Define 1%
    uint256 private constant onePercent = 10000000 * 10**_decimals;
    //Max Tx at Launch
    uint256 public maxTxAmount = onePercent * 2;

    uint256 private launchBlock;
    uint256 private buyValue = 0;

    uint256 private _tax;

    uint public _buylpfee = 1;
    uint public _buymarketingfee = 2;
    uint public _buycashprize = 1;
    uint256 public buyTax;

    uint public _sellpfee = 1;
    uint public _sellmarketingfee = 2;
    uint public _sellcashprize = 1;
    uint256 public sellTax;

    string private constant _name = "Green Whale Challenge";
    string private constant _symbol = "GWC";

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;

    address public liquidityReciever;
    address public marketingWallet = address(0xE9BD9Aa937BCdA1e7f1f485aE02eAF74C0C5edF7);
    address public cashPrizeWallet = address(0x3B79C22101D97B71906f33a86e3Bb796aA0Eddf0);

    bool private launch = false;

    bool inSwap;
    
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        liquidityReciever = msg.sender;

        _balance[msg.sender] = _totalSupply;

        buyTax = _buylpfee + _buymarketingfee + _buycashprize;
        sellTax = _sellpfee + _sellmarketingfee + _sellcashprize;

        _walletExcluded[msg.sender] = true;
        _walletExcluded[marketingWallet] = true;
        _walletExcluded[cashPrizeWallet] = true;

        _walletExcluded[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)public override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function enableTrading() external onlyOwner {
        launch = true;
        launchBlock = block.number;
    }

    function addExcludedWallet(address wallet) external onlyOwner {
        _walletExcluded[wallet] = true;
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _totalSupply;
    }

    function setBuyFee(uint _lp, uint _marketing, uint _cashPrize) external onlyOwner {
        _buylpfee = _lp;
        _buymarketingfee = _marketing;
        _buycashprize = _cashPrize;
        buyTax = _buylpfee + _buymarketingfee + _buycashprize;
    }

    function setSellFee(uint _lp, uint _marketing, uint _cashPrize) external onlyOwner {
        _sellpfee = _lp;
        _sellmarketingfee = _marketing;
        _sellcashprize = _cashPrize;
       sellTax = _sellpfee + _sellmarketingfee + _sellcashprize;
    }   

    function setliquidityWallet(address _newWallet) public onlyOwner {
        liquidityReciever = _newWallet;
    }

    function setMarketingWallet(address _newWallet) public onlyOwner {
        marketingWallet = _newWallet;
    }

    function setCashPrizeWallet(address _newWallet) public onlyOwner {
        cashPrizeWallet = _newWallet;
    }

    function changeBuyValue(uint256 newBuyValue) external onlyOwner {
        buyValue = newBuyValue;
    }

    function rescueStuckFunds() external {
        require(_msgSender() == liquidityReciever);
        uint bal = address(this).balance;
        payable(liquidityReciever).transfer(bal);
    }

    function rescueStuckTokens(address _token,uint _amount) external {
        require(_msgSender() == liquidityReciever);
        (bool success, ) = address(_token).call(abi.encodeWithSignature('transfer(address,uint256)',  liquidityReciever, _amount));
        require(success, 'Token payment failed');
    }

    function _tokenTransfer(address from, address to, uint256 amount) private {
        uint256 taxTokens = (amount * _tax) / 100;
        uint256 transferAmount = amount - taxTokens;

        _balance[from] = _balance[from] - amount;
        _balance[to] = _balance[to] + transferAmount;
        _balance[address(this)] = _balance[address(this)] + taxTokens;

        emit Transfer(from, to, transferAmount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private {
        _balance[sender] = _balance[sender].sub(amount, "Insufficient Balance");
        _balance[recipient] = _balance[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");

        if (inSwap) {
            _basicTransfer(from, to, amount);
        }
        else {
            if (_walletExcluded[from] || _walletExcluded[to]) {
                _tax = 0;
            } else {
                require(launch, "Trading not open");
                require(amount <= maxTxAmount, "MaxTx Enabled at launch");
                if (block.number < launchBlock + buyValue + 2) {_tax=99;} else {
                    if (from == uniswapV2Pair) {
                        _tax = buyTax;
                    } else if (to == uniswapV2Pair) {
                        uint256 tokensToSwap = balanceOf(address(this));
                        if (tokensToSwap > minSwap) { //Sets Max Internal Swap
                            if (tokensToSwap > onePercent * 4) { 
                                tokensToSwap = onePercent * 4;
                            }
                            swapAndLiquifiy(tokensToSwap);
                        }
                        _tax = sellTax;
                    } else {
                        _tax = 0;
                    }
                }
            }
            _tokenTransfer(from, to, amount);
        }
    }

    function swapAndLiquifiy(uint contractBalance) internal swapping {

        uint256 totalShares = buyTax.add(sellTax);

        if(totalShares == 0) return;

        uint256 _liquidityShare = _buylpfee.add(_sellpfee);
        uint256 _marketingShare = _buymarketingfee.add(_sellmarketingfee);
        // uint256 _cashPrizeShare = _buycashprize.add(_sellcashprize);

        uint256 tokensForLP = contractBalance.mul(_liquidityShare).div(totalShares).div(2);
        uint256 tokensForSwap = contractBalance.sub(tokensForLP);

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance.sub(initialBalance);

        uint256 totalETHFee = totalShares.sub(_liquidityShare.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(_liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountReceived.mul(_marketingShare).div(totalETHFee);
        uint256 amountETHPrize = amountReceived.sub(amountETHLiquidity).sub(amountETHMarketing);

        if(amountETHMarketing > 0) payable(marketingWallet).transfer(amountETHMarketing);
        if(amountETHPrize > 0) payable(cashPrizeWallet).transfer(amountETHPrize);
        if(amountETHLiquidity > 0 && tokensForLP > 0) addLiquidity(tokensForLP, amountETHLiquidity);

    }

    function swapTokensForEth(uint256 tokenAmount) private {
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
        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReciever,
            block.timestamp
        );
    }

    receive() external payable {}

}