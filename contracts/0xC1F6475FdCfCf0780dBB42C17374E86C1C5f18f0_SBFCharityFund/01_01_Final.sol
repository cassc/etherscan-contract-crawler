/**
 *Submitted for verification at Etherscan.io on 2023-08-26
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

interface IDexSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexSwapPair {
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

interface IDexSwapRouter {
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

contract SBFCharityFund is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private _name = "SBF Charity Fund";
    string private _symbol = "SAMCF";
    uint8 private _decimals = 18; 

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public immutable zeroAddress = 0x0000000000000000000000000000000000000000;

    uint _buyMarketingTax = 1;
    uint _buyLpTax = 1;
    uint _buyCharityTax = 1;

    uint _sellMarketingTax = 1;
    uint _sellLpTax = 1;
    uint _sellCharityTax = 1;

    uint256 public _totalbuyFee = _buyMarketingTax.add(_buyLpTax).add(_buyCharityTax);
    uint256 public _totalSellFee = _sellMarketingTax.add(_sellLpTax).add(_sellCharityTax);

    address public MarketingWallet = address(0x89C1948DD8356c619E937CCeB7b8b5189c747889);
    address public lpReceiverWallet;
    address public CharityWallet = address(0x45DB13C65017Fe2920F8202c359c7BdA6F6a5a4d);

    address teamWallet = 0x0BDC9902F0B5DfbB5eB8605CCAD7D06Ad192Dd2A;
    address cexWallet = 0x37995edc8b82b483bDfcbd22a39B53e48e2c1C8D;
    
    uint256 feedenominator = 100;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;

    uint256 private _totalSupply = 26_000_000_000 * 10**_decimals;

    uint256 public _maxTxAmount =  _totalSupply.mul(2).div(100);     // 2%
    uint256 public _walletMax = _totalSupply.mul(2).div(100);        // 2%

    uint256 public swapThreshold = 520_000_000 * 10**_decimals;     // 2%

    uint256 public launchedAt;
    bool public normalizeTrade;

    bool tradingActive;

    bool public swapEnabled = true;
    bool public swapbylimit = true;
    bool public EnableTxLimit = false;
    bool public checkWalletLimit = false;

    IDexSwapRouter public dexRouter;
    address public dexPair;

    bool inSwap;

    modifier onlyGuard() {
        require(msg.sender == lpReceiverWallet,"Invalid Caller");
        _;
    }

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    constructor()  {

        IDexSwapRouter _dexRouter = IDexSwapRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        dexRouter = _dexRouter;
        
        lpReceiverWallet = msg.sender;

        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(dexRouter)] = true;

        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[address(dexRouter)] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[deadAddress] = true;
        isWalletLimitExempt[zeroAddress] = true;
        
        isTxLimitExempt[deadAddress] = true;
        isTxLimitExempt[zeroAddress] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(dexRouter)] = true;

        isMarketPair[address(dexPair)] = true;

        _allowances[address(this)][address(dexRouter)] = ~uint256(0);
    
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        transfer(teamWallet, _totalSupply.mul(5).div(100));
        transfer(cexWallet,_totalSupply.mul(5).div(100));
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: Exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0));
        require(recipient != address(0));
        require(amount > 0);
    
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        else {

            if (!tradingActive) {
                require(isExcludedFromFee[sender] || isExcludedFromFee[recipient],"Trading is not active.");
            }

            if (launchedAt != 0 && !normalizeTrade) {
                dynamicTaxSetter();
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= swapThreshold;

            if (
                overMinimumTokenBalance && 
                !inSwap && 
                !isMarketPair[sender] && 
                swapEnabled &&
                !isExcludedFromFee[sender] &&
                !isExcludedFromFee[recipient]
                ) {
                swapBack(contractTokenBalance);
            }

            if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && EnableTxLimit) {
                require(amount <= _maxTxAmount, "Exceeds maxTxAmount");
            } 
            
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = shouldNotTakeFee(sender,recipient) ? amount : takeFee(sender, recipient, amount);

            if(checkWalletLimit && !isWalletLimitExempt[recipient]) {
                require(balanceOf(recipient).add(finalAmount) <= _walletMax,"Exceeds Wallet");
            }

            _balances[recipient] = _balances[recipient].add(finalAmount);

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

            if(isMarketPair[sender]) { 
                feeAmount = amount.mul(_totalbuyFee).div(feedenominator);
            } 
            else if(isMarketPair[recipient]) { 
                feeAmount = amount.mul(_totalSellFee).div(feedenominator);
            }

            if(feeAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }

            return amount.sub(feeAmount);
        }
        
    }

    function launch() public payable onlyOwner {
        require(launchedAt == 0, "Already launched!");
        launchedAt = block.number;
        tradingActive = true;

        uint tokenForLp = _balances[address(this)];

        _buyMarketingTax = 1;
        _buyLpTax = 0;
        _buyCharityTax = 0;

        _sellMarketingTax = 1;
        _sellLpTax = 0;
        _sellCharityTax = 0;

        dexRouter.addLiquidityETH{ value: msg.value }(
            address(this),
            tokenForLp,
            0,
            0,
            owner(),
            block.timestamp
        );

        IDexSwapFactory factory = IDexSwapFactory(dexRouter.factory());

        IDexSwapPair pair = IDexSwapPair(factory.getPair(address(this), dexRouter.WETH()));

        dexPair = address(pair);

        isMarketPair[address(dexPair)] = true;
        isWalletLimitExempt[address(dexPair)] = true;
        _allowances[address(this)][address(dexPair)] = ~uint256(0);

        swapEnabled = true;
        EnableTxLimit = true;
        checkWalletLimit =  true;
    }

    function dynamicTaxSetter() internal {
        if (block.number <= launchedAt + 3) {
            dynamicSetter(99,99);
        }
        if (block.number > launchedAt + 3 && block.number <= launchedAt + 22) {
            dynamicSetter(45,45);
        }
        if (block.number > launchedAt + 22) {
            dynamicSetter(3,3);
            normalizeTrade = true;
        }
            
    }

    function dynamicSetter(uint _buy, uint _Sell) internal {
        _totalbuyFee = _buy;
        _totalSellFee = _Sell;
    }


    function swapBack(uint contractBalance) internal swapping {

        if(swapbylimit) contractBalance = swapThreshold;

        uint256 totalShares = _totalbuyFee.add(_totalSellFee);

        uint256 _liquidityShare = _buyLpTax.add(_sellLpTax);
        // uint256 _MarketingShare = _buyMarketingTax.add(_sellMarketingTax);
        uint256 _CharityShare = _buyCharityTax.add(_sellCharityTax);

        uint256 tokensForLP = contractBalance.mul(_liquidityShare).div(totalShares).div(2);
        uint256 tokensForSwap = contractBalance.sub(tokensForLP);

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance.sub(initialBalance);

        uint256 totalETHFee = totalShares.sub(_liquidityShare.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(_liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHCharity = amountReceived.mul(_CharityShare).div(totalETHFee);
        uint256 amountETHMarketing = amountReceived.sub(amountETHLiquidity).sub(amountETHCharity);

       if(amountETHCharity > 0)
            payable(CharityWallet).transfer(amountETHCharity);

        if(amountETHMarketing > 0)
            payable(MarketingWallet).transfer(amountETHMarketing);

        if(amountETHLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountETHLiquidity);

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpReceiverWallet,
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function rescueFunds() external onlyGuard { 
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os,"Transaction Failed!!");
    }

    function rescueTokens(address _token,address recipient,uint _amount) external onlyGuard {
        (bool success, ) = address(_token).call(abi.encodeWithSignature('transfer(address,uint256)',  recipient, _amount));
        require(success, 'Token payment failed');
    }

    function setBuyFee(uint _MarketingFee, uint _lpFee, uint _CharityFee) external onlyOwner {    
        _buyMarketingTax = _MarketingFee;
        _buyLpTax = _lpFee;
        _buyCharityTax = _CharityFee;

        _totalbuyFee = _buyMarketingTax.add(_buyLpTax).add(_buyCharityTax);
    }

    function setSellFee(uint _MarketingFee, uint _lpFee, uint _CharityFee) external onlyOwner {
        _sellMarketingTax = _MarketingFee;
        _sellLpTax = _lpFee;
        _sellCharityTax = _CharityFee;
        _totalSellFee = _sellMarketingTax.add(_sellLpTax).add(_sellCharityTax);
    }

    function removeLimits() external onlyGuard {
        EnableTxLimit = false;
        checkWalletLimit =  false;
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
    
    function setMarketingWallet(address _newWallet) external onlyOwner {
        MarketingWallet = _newWallet;
    }

    function setLpWallet(address _newWallet) external onlyOwner {
        lpReceiverWallet = _newWallet;
    }

    function setCharityWallet(address _newWallet) external onlyOwner {
        CharityWallet = _newWallet;
    }

    function setMarketPair(address _pair, bool _status) external onlyOwner {
        isMarketPair[_pair] = _status;
        if(_status) {
            isWalletLimitExempt[_pair] = _status;
        }
    }

    function setSwapBackSettings(uint _threshold, bool _enabled, bool _limited)
        external
        onlyGuard
    {
        swapEnabled = _enabled;
        swapbylimit = _limited;
        swapThreshold = _threshold;
    }

    function setManualRouter(address _router) external onlyOwner {
        dexRouter = IDexSwapRouter(_router);
    }

    function setManualPair(address _pair) external onlyOwner {
        dexPair = _pair;
    }


}