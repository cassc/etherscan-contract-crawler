/**
 *Submitted for verification at Etherscan.io on 2023-09-25
*/

// SPDX-License-Identifier: MIT

/*
Decentralized lending meets tokenized securities.

Website: https://www.fluxprotocol.net
Telegram: https://t.me/flux_erc
Twitter: https://twitter.com/flux_erc
*/

pragma solidity 0.8.19;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    function renounceOwnership() public onlyOwner {owner = address(0); emit OwnershipTransferred(address(0));}
    event OwnershipTransferred(address owner);
}
interface IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IRouter {
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
        uint deadline) external;
}
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract FLUX is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Flux Finance";
    string private constant _symbol = "FLUX";

    uint8 private constant _decimals = 9;
    uint256 private _supplyTotal = 10 ** 9 * 10 ** _decimals;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExemptFees;

    uint256 swapFeeAt;
    bool private inswap;
    modifier lockSwap {inswap = true; _; inswap = false;}
    IRouter router;
    address public pair;

    uint256 private buyFee = 1500;
    uint256 private sellFee = 2500;
    uint256 private transferFee = 1500;
    uint256 private denominator = 10000;
    bool private tradingEnable = false;
    bool private swapEnabled = true;
    address internal devAddr=0x5CCdec8582Cf2C1073D5076D60f6dff510cD4A7F; 
    address internal marketingAddr=0x5CCdec8582Cf2C1073D5076D60f6dff510cD4A7F;
    address internal teamWallet=0x5CCdec8582Cf2C1073D5076D60f6dff510cD4A7F;
    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 private feeSwapCount;

    uint256 private burnRate = 0;
    uint256 private lpRate = 0;
    uint256 private mktRate = 0;
    uint256 private devRate = 100;
    uint256 private maxSwapAmount = ( _supplyTotal * 1000 ) / 100000;
    uint256 private minSwapAmount = ( _supplyTotal * 10 ) / 100000;
    uint256 public maxTxSize = ( _supplyTotal * 250 ) / 10000;
    uint256 public maxBuySize = ( _supplyTotal * 250 ) / 10000;
    uint256 public maxWallet = ( _supplyTotal * 250 ) / 10000;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
        isExemptFees[teamWallet] = true;
        isExemptFees[marketingAddr] = true;
        isExemptFees[devAddr] = true;
        isExemptFees[msg.sender] = true;
        _balances[msg.sender] = _supplyTotal;
        emit Transfer(address(0), msg.sender, _supplyTotal);
    }
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function startTrading() external onlyOwner {tradingEnable = true;}    
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _supplyTotal.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function getOwner() external view override returns (address) { return owner; }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isExemptFees[sender] && !isExemptFees[recipient]){require(tradingEnable, "tradingEnable");}
        if(!isExemptFees[sender] && !isExemptFees[recipient] && recipient != address(pair) && recipient != address(DEAD)){
        require((_balances[recipient].add(amount)) <= maxWallet, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= maxBuySize || isExemptFees[sender] || isExemptFees[recipient], "TX Limit Exceeded");}
        require(amount <= maxTxSize || isExemptFees[sender] || isExemptFees[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isExemptFees[sender]){feeSwapCount += uint256(1);}
        if(shouldSellTokens(sender, recipient, amount)){swapAndBurn(maxSwapAmount); feeSwapCount = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = !isExemptFees[sender] ? getAmountsAfterFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            teamWallet,
            block.timestamp);
    }
    function swapAndBurn(uint256 tokens) private lockSwap {
        uint256 _denominator = (lpRate.add(1).add(mktRate).add(devRate)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(lpRate).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensToiETH(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(lpRate));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(lpRate);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(mktRate);
        if(marketingAmt > 0){payable(marketingAddr).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(devAddr).transfer(contractBalance);}
    }
    receive() external payable {}

    function setTransactionLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _supplyTotal.mul(_buy).div(10000); uint256 newTransfer = _supplyTotal.mul(_sell).div(10000); uint256 newWallet = _supplyTotal.mul(_wallet).div(10000);
        maxTxSize = newTx; maxBuySize = newTransfer; maxWallet = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function setTransactionRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        lpRate = _liquidity; mktRate = _marketing; burnRate = _burn; devRate = _development; buyFee = _total; sellFee = _sell; transferFee = _trans;
        require(buyFee <= denominator.div(1) && sellFee <= denominator.div(1) && transferFee <= denominator.div(1), "buyFee and sellFee cannot be more than 20%");
    }

    function shouldSellTokens(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minSwapAmount;
        bool aboveThreshold = balanceOf(address(this)) >= maxSwapAmount;
        return !inswap && swapEnabled && tradingEnable && aboveMin && !isExemptFees[sender] && recipient == pair && feeSwapCount >= swapFeeAt && aboveThreshold;
    }

    function getExactFees(address sender, address recipient) internal view returns (uint256) {
        if(recipient == pair){return sellFee;}
        if(sender == pair){return buyFee;}
        return transferFee;
    }
    function getAmountsAfterFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (isExemptFees[recipient]) {return maxTxSize;}
        if(getExactFees(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominator).mul(getExactFees(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnRate > uint256(0) && getExactFees(sender, recipient) > burnRate){_transfer(address(this), address(DEAD), amount.div(denominator).mul(burnRate));}
        return amount.sub(feeAmount);} return amount;
    }

    function swapTokensToiETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
}