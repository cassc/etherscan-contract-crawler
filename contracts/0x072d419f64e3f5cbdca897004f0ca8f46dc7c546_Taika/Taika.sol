/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// TG: https://t.me/OfficialTaika

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

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

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
        
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

contract Taika is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping (address => uint) private cooldown;
    uint256 private time;
    uint256 private _tax;

    uint256 private constant _tTotal = 1 * 10**9 * 10**9;
    uint256 private fee1=40;
    uint256 private fee2=60;
    string private constant _name = "Yokoso Taika";
    string private constant _symbol = "Taika";
    uint256 private _maxTxAmount = _tTotal.div(100);
    uint256 private _maxWalletAmount = _tTotal.div(50);
    uint256 private minBalance = _tTotal.div(1000);


    uint8 private constant _decimals = 9;
    address payable private _deployer;
    address payable private _feeWallet;
    address[6] shillers = [
        0xB8A7A62C1162600233f1E842E7E9969A88EA2B12,
        0xd0D613F34d190488506452FDE666763959d83930,
        0x470E3A08a40990563212B383866Cb3cB862FE6C7,
        0x911F6179BAa9c413b76A0417902781E05F5b7539,
        0x40B5b5273253908Da3ce71C730017fCB2CDbF467,
        0xA5E1731517178CfAf396746cf055ff2229633632
    ];
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor () payable {
        _deployer = payable(msg.sender);
        _feeWallet = payable(0xA425AB4e241B9e4cD63688C9F33EFCf3CeBBfaCd);
        _tOwned[address(this)] = _tTotal;
        _tOwned[address(0xA425AB4e241B9e4cD63688C9F33EFCf3CeBBfaCd)] = _tTotal.div(50);
        _tOwned[address(0xa8a4038c96C5a4541859E5dE555A8646e9424053)] = _tTotal.div(50);
        _tOwned[address(0x6906e343bA9F73E72E47885860CF8BA8375d9525)] = _tTotal.div(50);
        _tOwned[address(0x2455Ca6E5F4EBae1a04135C58a6638327c9d2358)] = _tTotal.div(50);
        for (uint i=0;i < 6; i++) {
            _tOwned[shillers[i]] = _tTotal.div(200);
        }
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_deployer] = true;
        _isExcludedFromFee[uniswapV2Pair] = true;
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        emit Transfer(address(0),address(this),_tTotal);
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
        return _tOwned[account];
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
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
   

    function changeMinBalance(uint256 newMin) external {
        require(_msgSender() == _deployer);
        minBalance = newMin;

    }

    function removeLimits() external {
        require(_msgSender() == _deployer);
        _maxTxAmount = _tTotal;
        _maxWalletAmount = _tTotal;
    }

    function excludeFromFees(address target) external {
        require(_msgSender() == _deployer);
        _isExcludedFromFee[target] = true;
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

        _tax = fee1;
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] && (block.timestamp < time)){
                // Cooldown
                require((_tOwned[to] + amount) <= _maxWalletAmount,"not a chance bub");
                require(amount <= _maxTxAmount);
                require(cooldown[to] < block.timestamp);
                cooldown[to] = block.timestamp + (30 seconds);
            }
            
            
            if (!inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from]) {
                require(block.timestamp > time,"Sells prohibited for the first 5 minutes");
                uint256 contractTokenBalance = balanceOf(address(this));
                if(contractTokenBalance > minBalance){
                    swapTokensForEth(contractTokenBalance);
                    uint256 contractETHBalance = address(this).balance;
                    if(contractETHBalance > 0) {
                        sendETHToFee(address(this).balance);
                    }
                }
            }
        }
        if (to == uniswapV2Pair && from != address(uniswapV2Router) && ! _isExcludedFromFee[from]) {
            _tax = fee2;
        }		
        _transferStandard(from,to,amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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
    

    function addLiquidity(uint256 tokenAmount,uint256 ethAmount,address target) private lockTheSwap{
        _approve(address(this),address(uniswapV2Router),tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this),tokenAmount,0,0,target,block.timestamp);
    }

    
    function sendETHToFee(uint256 amount) private {
        _deployer.transfer(amount.div(5).mul(3));
        _feeWallet.transfer(amount.div(5).mul(2));
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        addLiquidity(balanceOf(address(this)),address(this).balance,owner());
        swapEnabled = true;
        tradingOpen = true;
        time = block.timestamp + (3 minutes);
    }
    
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
    
    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 transferAmount,uint256 tfee) = _getTValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(transferAmount); 
        _tOwned[address(this)] = _tOwned[address(this)].add(tfee);
        emit Transfer(sender, recipient, transferAmount);
    }

    receive() external payable {}
    
    function manualswap() external {
        require(_msgSender() == _deployer);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external {
        require(_msgSender() == _deployer);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
   
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = tAmount.mul(_tax).div(1000);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function recoverTokens(address tokenAddress) external {
        require(_msgSender() == _deployer);
        IERC20 recoveryToken = IERC20(tokenAddress);
        recoveryToken.transfer(_deployer,recoveryToken.balanceOf(address(this)));
    }
}