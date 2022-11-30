// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IController {
    function borrow(address recipient,uint amount) external;
}

interface IWaterDividend {
    function setShare(address shareholder, uint256 amount) external;
    function deposit(uint256 amount) external;
}

contract BARCv4 is Initializable, IERC20, OwnableUpgradeable {
    
    using SafeMath for uint256;
        
    string public _name;
    string public _symbol;
    uint8 public _decimals;

    address private GLDN;

    address payable public GrowthWallet;
    IController private lineManager;
    IWaterDividend private WaterDividend;
    address public liquidityReciever;

    address deadAddress;
    address zeroAddress;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping(address => bool) public isDividendExempt;

    uint256 public Max_Fee;

    uint256 public _buyLiquidityFee;
    uint256 public _buyGldnFee;
    uint256 public _buyGrowthFee;
    
    uint256 public _sellLiquidityFee;
    uint256 public _sellGldnFee;
    uint256 public _sellGrowthFee; //ETH

    uint256 public AmountForLiquidity;   
    uint256 public AmountForGLDN;     
    uint256 public AmountForGrowth;   

    uint256 denominator;

    uint256 private _totalSupply;

    uint256 public minimumTokensBeforeSwap;

    uint256 public _maxTxAmount;
    uint256 public _walletMax;

    bool public EnableTxLimit;
    bool public checkWalletLimit;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        address tokenA,
        address tokenB,
        uint256 AmounttokenA,
        uint256 AmountTokenB
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function initialize() public initializer {
        __Ownable_init();

        _name = "Blu Arctic";
        _symbol = "BARC";
        _decimals = 18;

        GLDN = 0xFeeB4D0f5463B1b04351823C246bdB84c4320CC2;   //mainnet
        GrowthWallet = payable(0x6f749aeCf132933b3928c301A34217aaC2729e5a);

        deadAddress = 0x000000000000000000000000000000000000dEaD;
        zeroAddress = 0x0000000000000000000000000000000000000000;

        _buyLiquidityFee = 0;
        _buyGldnFee = 25;
        _buyGrowthFee = 0;

        _sellLiquidityFee = 75;
        _sellGldnFee = 50;
        _sellGrowthFee = 25;

        denominator = 1000;

        Max_Fee = 200;   //20% max tax

        _totalSupply = 70_000_000 * 10**_decimals;   
        minimumTokensBeforeSwap = 10000 * 10**_decimals;

        _maxTxAmount =  _totalSupply.mul(5).div(denominator);     //0.5%
        _walletMax = _totalSupply.mul(5).div(denominator);    //0.5%

        EnableTxLimit = true;
        checkWalletLimit = true;
        swapAndLiquifyEnabled = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    
    function runInit() external onlyOwner() {
        
        //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D Mainnet
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 

        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), address(GLDN));

        uniswapV2Router = _uniswapV2Router;

        _allowances[address(this)][address(uniswapV2Router)] = ~uint256(0);
        _allowances[address(this)][address(uniswapPair)] = ~uint256(0);

        liquidityReciever = msg.sender;

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[GrowthWallet] = true;

        isDividendExempt[msg.sender] = true;
        isDividendExempt[uniswapPair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[deadAddress] = true;
        isDividendExempt[zeroAddress] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(uniswapPair)] = true;
        isWalletLimitExempt[address(this)] = true;
        
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;

        isMarketPair[address(uniswapPair)] = true;

        // IERC20(GLDN).approve(address(uniswapV2Router), ~uint256(0));
        // IERC20(GLDN).approve(address(uniswapPair), ~uint256(0));
        // IERC20(GLDN).approve(address(this), ~uint256(0));
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
       return _balances[account];     
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress)).sub(balanceOf(zeroAddress));
    }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(inSwapAndLiquify)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {  
            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && EnableTxLimit) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            } 

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            
            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender] && swapAndLiquifyEnabled) 
            {
                swapAndLiquify();
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = shouldTakeFee(sender,recipient) ? amount : takeFee(sender, recipient, amount);

            if(checkWalletLimit && !isWalletLimitExempt[recipient]) {
                require(balanceOf(recipient).add(finalAmount) <= _walletMax,"Max Wallet Limit Exceeded!!");
            }

            _balances[recipient] = _balances[recipient].add(finalAmount);

            if(!isDividendExempt[sender]){ try WaterDividend.setShare(sender, balanceOf(sender)) {} catch {} }
            if(!isDividendExempt[recipient]){ try WaterDividend.setShare(recipient, balanceOf(recipient)) {} catch {} }

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify() private lockTheSwap {  
        if(AmountForLiquidity > 0) swapAndLiquifity(AmountForLiquidity);
        if(AmountForGLDN > 0) swapForDeposit(AmountForGLDN);
        if(AmountForGrowth > 0) swapForGrowth(AmountForGrowth);
    }

    function swapAndLiquifity(uint256 tokenAmount) private {
        uint half = tokenAmount.div(2);
        uint otherhalf = tokenAmount.sub(half);
        uint initalBalance = IERC20(GLDN).balanceOf(address(lineManager));
        swapBarcIntoGldn(half);
        uint receivedBalance = (IERC20(GLDN).balanceOf(address(lineManager))).sub(initalBalance);
        lineManager.borrow(address(this),receivedBalance);
        addLiquidityGldn(receivedBalance,otherhalf);
        AmountForLiquidity = AmountForLiquidity.sub(tokenAmount);
    }   

    function swapForDeposit(uint256 tokenAmount) private {
        uint initalBalance = IERC20(GLDN).balanceOf(address(lineManager));
        swapBarcIntoGldn(tokenAmount);
        uint receivedBalance = (IERC20(GLDN).balanceOf(address(lineManager))).sub(initalBalance);
        lineManager.borrow(address(WaterDividend),receivedBalance);
        WaterDividend.deposit(receivedBalance);
        AmountForGLDN = AmountForGLDN.sub(tokenAmount);
    }

    function swapForGrowth(uint256 tokenAmount) private {
        uint initalBalance = IERC20(GLDN).balanceOf(address(lineManager));
        swapBarcIntoGldn(tokenAmount);
        uint receivedBalance = (IERC20(GLDN).balanceOf(address(lineManager))).sub(initalBalance);
        lineManager.borrow(address(GrowthWallet),receivedBalance);
        // swapGldnForEth(receivedBalance);
        AmountForGrowth = AmountForGrowth.sub(tokenAmount);
    }

    function swapBarcIntoGldn(uint tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(GLDN);

        _approve(address(this), address(uniswapV2Router), ~uint256(0));

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(lineManager),
            block.timestamp
        );
    }

    function addLiquidityGldn(uint tokenA,uint tokenB) private {

        IERC20(GLDN).approve(address(uniswapV2Router), ~uint256(0));
        _approve(address(this), address(uniswapV2Router), ~uint256(0));

        uniswapV2Router.addLiquidity(
            address(GLDN),
            address(this),
            tokenA,
            tokenB,
            0,
            0,
            liquidityReciever,
            block.timestamp
        );

        emit SwapAndLiquify(address(GLDN),address(this),tokenA,tokenB);
        
    }

    function swapGldnForEth(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(GLDN);
        path[1] = uniswapV2Router.WETH();

        IERC20(GLDN).approve(address(uniswapV2Router), ~uint256(0));

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            GrowthWallet, 
            block.timestamp
        );
        emit SwapTokensForETH(tokenAmount, path);
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            return true;
        }
        else if (isMarketPair[sender] || isMarketPair[recipient]) {
            return false;
        }
        else {
            return false;
        }
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint feeAmount;
        uint LFEE;
        uint GLDNFEE;
        uint GFEE;      

        unchecked {

            if(isMarketPair[sender]) {
                LFEE = amount.mul(_buyLiquidityFee).div(denominator);
                AmountForLiquidity += LFEE;
                GLDNFEE = amount.mul(_buyGldnFee).div(denominator);
                AmountForGLDN += GLDNFEE;
                GFEE = amount.mul(_buyGrowthFee).div(denominator);
                AmountForGrowth += GFEE;
                feeAmount = LFEE.add(GLDNFEE).add(GFEE);
            }
            else if(isMarketPair[recipient]) {
                LFEE = amount.mul(_sellLiquidityFee).div(denominator);
                AmountForLiquidity += LFEE;
                GLDNFEE = amount.mul(_sellGldnFee).div(denominator);
                AmountForGLDN += GLDNFEE;
                GFEE = amount.mul(_sellGrowthFee).div(denominator);
                AmountForGrowth += GFEE;
                feeAmount = LFEE.add(GLDNFEE).add(GFEE);
            }     

            if(feeAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }

            return amount.sub(feeAmount);
        }
        
    }

    //To Rescue Stucked Balance
    function rescueFunds() external onlyOwner { 
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os,"Transaction Failed!!");
    }

    //To Rescue Stucked Tokens
    function rescueTokens(IERC20 adr,address recipient,uint amount) external onlyOwner {
        adr.transfer(recipient,amount);
    }

    function enableTxLimit(bool _status) external onlyOwner {
        EnableTxLimit = _status;
    }

    function enableWalletLimit(bool _status) external onlyOwner {
        checkWalletLimit = _status;
    }

    function setBuyFee(uint _newLP , uint _newGldn , uint _newGrowth) external onlyOwner {     
        uint subtotal = _newLP.add(_newGldn).add(_newGrowth);
        require(subtotal <= Max_Fee,"Error: Max Limit is 20%.");
        _buyLiquidityFee = _newLP;
        _buyGldnFee = _newGldn;
        _buyGrowthFee = _newGrowth;
    }    

    function setSellFee(uint _newLP , uint _newGldn, uint _newGrowth) external onlyOwner {   
        uint subtotal = _newLP.add(_newGldn).add(_newGrowth);
        require(subtotal <= Max_Fee,"Error: Max Limit is 20%.");     
        _sellLiquidityFee = _newLP;
        _sellGldnFee = _newGldn;
        _sellGrowthFee = _newGrowth;
    }

    function setLiquidityWallets(address _liquidityRec) external onlyOwner {
        liquidityReciever = _liquidityRec;
    }

    function setGrowthWallets(address _growthWallet) external onlyOwner {
        GrowthWallet = payable(_growthWallet);
    }

    function setControllers(address _manager, address _dividend) external onlyOwner {
        lineManager = IController(_manager); 
        WaterDividend = IWaterDividend(_dividend);
    }

    function setExcludeFromFee(address _adr,bool _status) external onlyOwner {
        isExcludedFromFee[_adr] = _status;
    }

    function ExcludeWalletLimit(address _adr,bool _status) external onlyOwner {
        isWalletLimitExempt[_adr] = _status;
    }

    function ExcludeTxLimit(address _adr,bool _status) external onlyOwner {
        isTxLimitExempt[_adr] = _status;
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        minimumTokensBeforeSwap = newLimit;
    }

    function setMaxWalletLimit(uint256 newLimit) external onlyOwner() {
        _walletMax = newLimit;
    }

    function setTxLimit(uint256 newLimit) external onlyOwner() {
        _maxTxAmount = newLimit;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setAutomaticPairMarket(address _addr,bool _status) external onlyOwner {
        if(_status) {
            require(!isMarketPair[_addr],"Pair Already Set!!");
        }
        isMarketPair[_addr] = _status;
        isDividendExempt[_addr] = true;
        isWalletLimitExempt[_addr] = true;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && !isMarketPair[holder]);
        isDividendExempt[holder] = exempt;

        if (exempt) {
            WaterDividend.setShare(holder, 0);
        } else {
            WaterDividend.setShare(holder, balanceOf(holder));
        }
    }

    function initSetter() public onlyOwner {
        IERC20(GLDN).approve(address(uniswapV2Router), ~uint256(0));
        IERC20(GLDN).approve(address(uniswapPair), ~uint256(0));
        IERC20(GLDN).approve(address(this), ~uint256(0));
    }


}