// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";


contract C12 is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _name = "Carbon 12";
    string private constant _symbol = "C12";
    uint8 private constant _decimals = 18;

    uint256 private buyLiquidityFee = 30;
    uint256 private buyRewardFee = 0;
    uint256 private buyGrowthFund = 20;
    uint256 private buyBurnFee = 0;

    uint256 private sellLiquidityFee = 20;
    uint256 private sellRewardFee = 30;
    uint256 private sellGrowthFund = 0;
    uint256 private sellBurnFee = 0;

    uint256 public totalBuy;
    uint256 public totalSell;

    uint256 private constant feeDenominator = 1000;

    address public GrowthFundWallet = 0xBE6ea4D57E095c53822d3F6319C0Af673811a51b;
    address public RewardWallet = 0x91Ff8A403724998e6CF78Ff9F468C11A8D9d8907;
    address public liquidityWallet;

    address private constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address private constant ZeroWallet = 0x0000000000000000000000000000000000000000;

    mapping(address => mapping(address => uint256)) private _allowances;  
    mapping(address => uint256) private _balances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => bool) public isWalletLimitExempt;
    mapping (address => bool) public isTxLimitExempt;
    
    uint256 public _totalSupply = 777_000_000 * (10 ** _decimals);
    uint256 public swapTokensAtAmount = 10000 * (10 ** _decimals);

    uint256 public _maxTxAmount = _totalSupply.mul(10).div(feeDenominator);     //10%
    uint256 public _walletMax = _totalSupply.mul(10).div(feeDenominator);    //10%

    bool public _autoSwapBack = true;
    bool public EnableTransactionLimit = false;
    bool public checkWalletLimit = false;
  
    address public pair;
    
    IUniswapV2Pair public pairContract;
    IUniswapV2Router02 public router;

    bool inSwap = false;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    constructor() {

        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 

        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _allowances[address(this)][address(router)] = ~uint256(0);

        pairContract = IUniswapV2Pair(pair);
        automatedMarketMakerPairs[pair] = true;
        
        liquidityWallet = address(msg.sender);
        
        isWalletLimitExempt[address(msg.sender)] = true;
        isWalletLimitExempt[pair] = true;
        isWalletLimitExempt[address(this)] = true;

        _isExcludedFromFees[address(msg.sender)] = true;
        _isExcludedFromFees[address(this)] = true;

        isTxLimitExempt[address(msg.sender)] = true;
        isTxLimitExempt[address(this)] = true;
            
        totalBuy = buyLiquidityFee.add(buyRewardFee).add(buyGrowthFund).add(buyBurnFee);
        totalSell = sellLiquidityFee.add(sellRewardFee).add(sellGrowthFund).add(sellBurnFee);

        _balances[address(msg.sender)] = _totalSupply;
        emit Transfer(address(0x0), address(msg.sender), _totalSupply);
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
   
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            _totalSupply.sub(_balances[deadWallet]).sub(_balances[ZeroWallet]);
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isExcludedFromFees[_addr];
    }

// ---------------------------------------------------------------------------- //

    function transfer(address to, uint256 value)
        external
        validRecipient(to)
        override
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external validRecipient(to) override returns (bool) {
        
        if (_allowances[from][msg.sender] != ~uint256(0)) {
            _allowances[from][msg.sender] = _allowances[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }
        _transferFrom(from, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {

        if(!isTxLimitExempt[sender] && !isTxLimitExempt[recipient] && EnableTransactionLimit) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) {
            swapBack();
        }
        
        _balances[sender] = _balances[sender].sub(amount);
        
        uint256 AmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;

        if(checkWalletLimit && !isWalletLimitExempt[recipient]) {
            require(balanceOf(recipient).add(AmountReceived) <= _walletMax);
        }

        _balances[recipient] = _balances[recipient].add(AmountReceived);

        emit Transfer(sender,recipient,AmountReceived);
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal  returns (uint256) {

        uint256 feeAmount;
       
        unchecked {
        
            if(automatedMarketMakerPairs[sender]){
                feeAmount = amount.mul(totalBuy).div(feeDenominator);
            }
            else if(automatedMarketMakerPairs[recipient]){
                feeAmount = amount.mul(totalSell).div(feeDenominator);
            }

            if(feeAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }

            return amount.sub(feeAmount);
        }
        
    }

    function swapBack() internal swapping {
        
        uint contractBalance = balanceOf(address(this));
        uint totalShares = totalBuy.add(totalSell);

        if(contractBalance == 0 || totalShares == 0) return;

        uint _liquidityShare = buyLiquidityFee.add(sellLiquidityFee);
        uint _RewardShare = buyRewardFee.add(sellRewardFee); 
        // uint _GrowthShare = buyGrowthFund.add(sellGrowthFund);     
        uint _BurnShare = buyBurnFee.add(sellBurnFee);

        if (_BurnShare > 0) {
            uint tokenForBurn = contractBalance.mul(_BurnShare).div(totalShares);
            sendTokenWithoutFee(address(this),address(deadWallet),tokenForBurn);
            contractBalance = contractBalance.sub(tokenForBurn);
            totalShares = totalShares.sub(_BurnShare);
        }

        uint256 tokensForLP = contractBalance.mul(_liquidityShare).div(totalShares).div(2);
        uint256 tokensForSwap = contractBalance.sub(tokensForLP);

        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokensForSwap,address(this));
        uint256 amountReceived = address(this).balance.sub(initialBalance);

        uint256 totalETHFee = totalShares.sub(_liquidityShare.div(2));
        
        uint256 amountETHLiquidity = amountReceived.mul(_liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHReward = amountReceived.mul(_RewardShare).div(totalETHFee);
        uint256 amountETHGrowth = amountReceived.sub(amountETHLiquidity).sub(amountETHReward);

        if(amountETHReward > 0) {
            payable(RewardWallet).transfer(amountETHReward);
        }
        if(amountETHGrowth > 0) {
            payable(GrowthFundWallet).transfer(amountETHGrowth);
        }
        if(amountETHLiquidity > 0) {
            addLiquidity(tokensForLP,amountETHLiquidity);
        }

    }

    function sendTokenWithoutFee(address _sender, address _recipient, uint256 _amount) private {
        _balances[_sender] = _balances[_sender].sub(_amount);
        _balances[_recipient] = _balances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }

    function shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            return false;
        }        
        else{
            return (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);
        }
    }

    function shouldSwapBack() internal view returns (bool) {

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        return
            _autoSwapBack && 
            !inSwap && 
            canSwap &&
            !automatedMarketMakerPairs[msg.sender];
    }

// ---------------------------------------------------------------------------- //

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowances[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowances[msg.sender][spender] = 0;
        } else {
            _allowances[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowances[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowances[msg.sender][spender] = _allowances[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowances[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender,spender,value);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setBuyFee(
            uint _newLp,
            uint _newReward,
            uint _newGrowth,
            uint _newBurn
        ) public onlyOwner {
        buyLiquidityFee = _newLp;
        buyRewardFee = _newReward;
        buyGrowthFund = _newGrowth;
        buyBurnFee = _newBurn;
        totalBuy = buyLiquidityFee.add(buyRewardFee).add(buyGrowthFund).add(buyBurnFee);
    }

    function setSellFee(
            uint _newLp,
            uint _newReward,
            uint _newGrowth,
            uint _newBurn
        ) public onlyOwner {
        sellLiquidityFee = _newLp;
        sellRewardFee = _newReward;
        sellGrowthFund = _newGrowth;
        sellBurnFee = _newBurn;
        totalSell = sellLiquidityFee.add(sellRewardFee).add(sellGrowthFund).add(sellBurnFee);
    }

    function setMaxWalletLimit(uint _percent) public onlyOwner {
        _maxTxAmount = _totalSupply.mul(_percent).div(feeDenominator); 
    }

    function setMaxTxLimit(uint _percent) public onlyOwner {
        _walletMax = _totalSupply.mul(_percent).div(feeDenominator); 
    }

    function enableDisableTxLimit(bool _status) public onlyOwner {
        EnableTransactionLimit = _status;
    }

    function enableDisableWalletLimit(bool _status) public onlyOwner {
        checkWalletLimit = _status;
    }

    function clearStuckBalance(address _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool os,) = payable(_receiver).call{value: balance}("");
        if(os){}
    }

    function rescueToken(address tokenAddress,address _receiver, uint256 tokens) external onlyOwner returns (bool success){
        return IERC20(tokenAddress).transfer(_receiver, tokens);
    }

    function setGrowthWallet(address _newWallet) public onlyOwner {
        GrowthFundWallet = _newWallet;
    }

    function setLiquidityWallet(address _newWallet) public onlyOwner {
        liquidityWallet = _newWallet;
    }

    function setRewardWallet(address _newWallet) public onlyOwner {
        RewardWallet = _newWallet;
    }

    function manualSync() external onlyOwner {
        IUniswapV2Pair(pairContract).sync();
    }

    function setLP(address _address) external onlyOwner {
        pairContract = IUniswapV2Pair(_address);
    }

    function setAutomaticPairMarket(address _addr,bool _status) public onlyOwner {
        if(_status) {
            require(!automatedMarketMakerPairs[_addr],"Pair Already Set!!");
        }
        automatedMarketMakerPairs[_addr] = _status;
        isWalletLimitExempt[_addr] = true;
    }

    function setWhitelistFee(address _addr,bool _status) external onlyOwner {
        require(_isExcludedFromFees[_addr] != _status, "Error: Not changed");
        _isExcludedFromFees[_addr] = _status;
    }

    function setMinSwapAmount(uint _value) external onlyOwner {
        swapTokensAtAmount = _value;
    }

    function setAutoSwapBack(bool _flag) external onlyOwner {
        if(_flag) {
            _autoSwapBack = _flag;
        } else {
            _autoSwapBack = _flag;
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 EthAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);
        // add the liquidity
        router.addLiquidityETH{value: EthAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );

    }

    function swapTokensForEth(uint256 tokenAmount,address _recipient) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(_recipient),
            block.timestamp
        );

    }

    receive() external payable {}

}