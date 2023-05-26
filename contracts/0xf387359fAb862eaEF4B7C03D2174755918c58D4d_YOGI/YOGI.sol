/**
 *Submitted for verification at Etherscan.io on 2023-03-31
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-26
*/

// SPDX-License-Identifier:MIT

pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface S_IERC20 {
    function transfer(address recipient, uint256 amount) external;
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any _account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface ISushiSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISushiSwapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface ISushiSwapRouter {
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
        uint deadline
    ) external;

}

interface IREWARD {
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
}

contract YOGI is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private _name = "YOGI"; // token name
    string private _symbol = "YOGI"; // token ticker
    uint8 private _decimals = 9; // token decimals

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public immutable zeroAddress = 0x0000000000000000000000000000000000000000;

    uint256 _buyLiquidityFee = 20;
    uint256 _buyRewardFee = 30;

    uint256 _sellLiquidityFee = 20;
    uint256 _sellRewardFee = 30;

    uint256 public totalBuyFee;
    uint256 public totalSellFee;

    address liquidityReciever;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isBot;

    uint256 private _totalSupply = 100_000_000 * 10**_decimals;

    uint256 feedenominator = 1000;

    uint256 public _maxTxAmount =  _totalSupply.mul(5).div(1000);     //0.5%
    uint256 public _walletMax = _totalSupply.mul(5).div(1000);    //0.5%
    uint256 public swapThreshold = 20_000 * 10**_decimals;

    bool public transferFeeEnabled = true;
    uint256 public initalTransferFee = 99; // 99% max fees limit on inital transfer
    uint256 public launchedAt; 
    uint256 public snipingTime = 50 seconds; //1 min snipping time
    bool public trading; 

    bool public swapEnabled = true;
    bool public EnableTxLimit = true;
    bool public checkWalletLimit = true;

    mapping (address => bool) public isYogiWL;

    modifier onlyGuard() {
        require(msg.sender == liquidityReciever,"Error: Guarded!");
        _;
    }

    IREWARD public rewardDividend;

    ISushiSwapRouter public sushiRouter;
    address public sushiPair;

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

        //Shiba Swap
        ISushiSwapRouter _dexRouter = ISushiSwapRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        sushiPair = ISushiSwapFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        sushiRouter = _dexRouter;

        _allowances[address(this)][address(sushiRouter)] = ~uint256(0);

        liquidityReciever = msg.sender;

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(sushiRouter)] = true;

        isDividendExempt[sushiPair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[deadAddress] = true;
        isDividendExempt[zeroAddress] = true;
        isDividendExempt[address(sushiRouter)] = true;

        isYogiWL[address(msg.sender)] = true;
        isYogiWL[address(this)] = true;
        isYogiWL[address(sushiRouter)] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(sushiPair)] = true;
        isWalletLimitExempt[address(sushiRouter)] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[deadAddress] = true;
        isWalletLimitExempt[zeroAddress] = true;
        
        isTxLimitExempt[deadAddress] = true;
        isTxLimitExempt[zeroAddress] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(sushiRouter)] = true;

        isMarketPair[address(sushiPair)] = true;

        _allowances[address(this)][address(sushiRouter)] = ~uint256(0);
        _allowances[address(this)][address(sushiPair)] = ~uint256(0);

        totalBuyFee = _buyLiquidityFee.add(_buyRewardFee);
        totalSellFee = _sellLiquidityFee.add(_sellRewardFee);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress)).sub(balanceOf(zeroAddress));
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

     //to recieve ETH from Router when swaping
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
        
        require(!isBot[sender], "ERC20: Bot detected");
        require(!isBot[msg.sender], "ERC20: Bot detected");
        require(!isBot[tx.origin], "ERC20: Bot detected");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        else {

            if (!isYogiWL[sender] && !isYogiWL[recipient]) {
                require(trading, "ERC20: trading not enable yet");

                if (
                    block.timestamp < launchedAt + snipingTime &&
                    sender != address(sushiRouter)
                ) {
                    if (sushiPair == sender) {
                        isBot[recipient] = true;
                    } else if (sushiPair == recipient) {
                        isBot[sender] = true;
                    }
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= swapThreshold;

            if (overMinimumTokenBalance && !inSwap && !isMarketPair[sender] && swapEnabled) {
                swapBack(contractTokenBalance);
            }
            
            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && EnableTxLimit) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            } 
            
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = shouldNotTakeFee(sender,recipient) ? amount : takeFee(sender, recipient, amount);

            if(checkWalletLimit && !isWalletLimitExempt[recipient]) {
                require(balanceOf(recipient).add(finalAmount) <= _walletMax,"Max Wallet Limit Exceeded!!");
            }

            _balances[recipient] = _balances[recipient].add(finalAmount);

            if(!isDividendExempt[sender]){ try rewardDividend.setShare(sender, balanceOf(sender)) {} catch {} }
            if(!isDividendExempt[recipient]){ try rewardDividend.setShare(recipient, balanceOf(recipient)) {} catch {} }

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
    
    function shouldNotTakeFee(address sender, address recipient) internal view returns (bool) {
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

        unchecked {

            if(isMarketPair[sender]) { //buy
                feeAmount = amount.mul(totalBuyFee).div(feedenominator);
            } 
            else if(isMarketPair[recipient]) { //sell
                feeAmount = amount.mul(totalSellFee).div(feedenominator);
            }
            else {
                if(transferFeeEnabled) {
                    feeAmount = amount.mul(initalTransferFee).div(100);
                }
            }

            if(feeAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }

            return amount.sub(feeAmount);
        }
        
    }

    function swapBack(uint contractBalance) internal swapping {

        uint256 totalShares = totalBuyFee.add(totalSellFee);

        if(totalShares == 0) return;

        uint256 _liquidityShare = _buyLiquidityFee.add(_sellLiquidityFee);
        // uint256 _RewardShare = _buyRewardFee.add(_sellRewardFee);

        uint256 tokensForLP = contractBalance.mul(_liquidityShare).div(totalShares).div(2);
        uint256 tokensForSwap = contractBalance.sub(tokensForLP);

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance.sub(initialBalance);

        uint256 totalETHFee = totalShares.sub(_liquidityShare.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(_liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHReward = amountReceived.sub(amountETHLiquidity);

        if(amountETHLiquidity > 0 && tokensForLP > 0) addLiquidity(tokensForLP, amountETHLiquidity);
        if(amountETHReward > 0) {
            try rewardDividend.deposit { value: amountETHReward } () {} catch {}
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = sushiRouter.WETH();

        _approve(address(this), address(sushiRouter), tokenAmount);

        // make the swap
        sushiRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(sushiRouter), tokenAmount);

        // add the liquidity
        sushiRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityReciever,
            block.timestamp
        );
    }

    function startTrading() external onlyOwner {
        require(!trading, "ERC20: Already Enabled");
        trading = true;
        launchedAt = block.timestamp;
    }

    //To Rescue Stucked Balance
    function rescueFunds() external onlyGuard { 
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os,"Transaction Failed!!");
    }

    //To Rescue Stucked Tokens
    function rescueTokens(S_IERC20 adr,address recipient,uint amount) external onlyGuard {
        adr.transfer(recipient,amount);
    }

    function updateSetting(address[] calldata _adr, bool _status) external onlyOwner {
        for(uint i = 0; i < _adr.length; i++){
            isYogiWL[_adr[i]] = _status;
        }
    }

    function addOrRemoveBots(address[] calldata accounts, bool value)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            isBot[accounts[i]] = value;
        }
    }

    function disableTransferFee(bool _status) external onlyOwner {
        transferFeeEnabled = _status;
    }

    function setItransferFee(uint _newFee) external onlyOwner {
        initalTransferFee = _newFee;
    }

    function setBuyFee(uint _newLiq, uint _newReward) external onlyOwner {
        _buyLiquidityFee = _newLiq;
        _buyRewardFee = _newReward;
        totalBuyFee = _buyLiquidityFee.add(_buyRewardFee);
    }

    function setSellFee(uint _newLiq, uint _newReward) external onlyOwner {
        _sellLiquidityFee = _newLiq;
        _sellRewardFee = _newReward;
        totalSellFee = _sellLiquidityFee.add(_sellRewardFee);
    }

    function enableTxLimit(bool _status) external onlyOwner {
        EnableTxLimit = _status;
    }

    function enableWalletLimit(bool _status) external onlyOwner {
        checkWalletLimit = _status;
    }

    function excludeFromFee(address _adr,bool _status) external onlyOwner {
        isExcludedFromFee[_adr] = _status;
    }

    function excludeWalletLimit(address _adr,bool _status) external onlyOwner {
        isWalletLimitExempt[_adr] = _status;
    }

    function excludeTxLimit(address _adr,bool _status) external onlyOwner {
        isTxLimitExempt[_adr] = _status;
    }

    function setMaxWalletLimit(uint256 newLimit) external onlyOwner() {
        _walletMax = newLimit;
    }

    function setTxLimit(uint256 newLimit) external onlyOwner() {
        _maxTxAmount = newLimit;
    }
    
    function setLiquidityWallet(address _newWallet) external onlyOwner {
        liquidityReciever = _newWallet;
    }

    function setIsDividendExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        if(exempt) {
            rewardDividend.setShare(holder,0);
        }
        else {
            rewardDividend.setShare(holder,balanceOf(holder));
        }
        isDividendExempt[holder] = exempt;
    }

    function setRewardDividend(address _dividend) external onlyGuard {
        rewardDividend = IREWARD(_dividend); 
    }

    function setMarketPair(address _pair, bool _status) external onlyOwner {
        isMarketPair[_pair] = _status;
        if(_status) {
            isDividendExempt[_pair] = _status;
            isWalletLimitExempt[_pair] = _status;
        }
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        onlyOwner
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setManualRouter(address _router) external onlyOwner {
        sushiRouter = ISushiSwapRouter(_router);
    }

    function setManualPair(address _pair) external onlyOwner {
        sushiPair = _pair;
    }


}