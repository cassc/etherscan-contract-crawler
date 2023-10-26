/**
 *Submitted for verification at Etherscan.io on 2023-07-29
*/

/**
Welcome to $SAURON - The One Token to Rule Them All!

Hail, wanderer of Middle-Earth! As you venture forth into the world of cryptocurrencies, we are delighted to introduce you to SAURON Token, a token inspired by the infamous Dark Lord himself from the realm of Lord of the Rings.

Within the depths of Mordor, we have crafted a token that brings together the strength of staking, the generosity of weekly community giveaways, and the boundless creativity of community-inspired dApps. SAURON Token aims to unite the crypto community under a single banner, forging an alliance like no other.

Prepare yourself to wield the power of staking, where you can lock your tokens and let them grow, just as the Dark Lord forged the One Ring to control all others. Your staked tokens will strengthen the network and earn you handsome rewards, empowering you in your quest for financial prosperity.

But the journey doesn't end there! As part of our commitment to fostering a vibrant community, we will host thrilling weekly giveaways that bring forth precious rewards for our loyal supporters. Each week, the spirit of giving shall flow like the Anduin river, bestowing blessings upon those who stand steadfast with us.

Beyond the mere limits of traditional tokens, we invite our community to partake in shaping the future of SAURON Token. Together, we shall harness the power of the community's creativity to forge dApps that reflect the diverse and ingenious spirit that resides in each of you. Let your ideas flow freely like the winds of Rohan, and together, we will build dApps that transcend the bounds of imagination.

SAURON Token is not just a token; it is a fellowship. We pledge to protect and nurture the community like the White Tree of Gondor, upholding transparency, security, and fairness at every step of the way. Together, we will march boldly into the uncharted territory of DeFi, facing the challenges ahead with unwavering determination.

As the Dark Lord sought dominion over Middle-Earth, we seek to empower individuals in the realm of cryptocurrencies. 

Join us now, and together, we shall forge a new legend in the annals of blockchain history.

One token to rule them all - SAURON Token awaits your presence.

Telegram: t.me/Sauron_eth
Twitter: twitter.com/LordSauron_eth

*/

// SPDX-License-Identifier: MIT

/*


*/

pragma solidity ^0.8.17;

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
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

contract SAURON is Context, IERC20, Ownable {

    using Address for address payable;

    IRouter public router;
    address public pair;
    
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromMaxBalance;
    mapping (address => bool) public _isBlacklisted;
    mapping (address => uint256) public _dogSellTime;

    uint256 private _dogSellTimeOffset = 3;
    bool public watchdogMode = true;
    uint256 public _caughtDogs;

    uint8 private constant _decimals = 9; 
    uint256 private _tTotal = 1_000_000_000 * (10**_decimals);
    uint256 public swapThreshold = 10_000 * (10**_decimals); 
    uint256 public maxTxAmount = 10_000_000 * (10**_decimals);
    uint256 public maxWallet =  10_000_000 * (10**_decimals);

    string private constant _name = "SAURON"; 
    string private constant _symbol = "SAURON";

    struct Tax{
        uint8 marketingTax;
        uint8 lpTax;
    }

    struct TokensFromTax{
        uint marketingTokens;
        uint lpTokens;
    }
    TokensFromTax public totalTokensFromTax;

    Tax public buyTax = Tax(15,10);
    Tax public sellTax = Tax(60,15);
    
    address public marketingWallet = 0x31EF2E70bdB83fBC57AdB0856EC92bD21840a174;
    
    bool private swapping;
    uint private _swapCooldown = 5; 
    uint private _lastSwap;
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _tOwned[_msgSender()] = _tTotal;
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
        _approve(owner(), address(router), ~uint256(0));
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;

        _isExcludedFromMaxBalance[owner()] = true;
        _isExcludedFromMaxBalance[address(this)] = true;
        _isExcludedFromMaxBalance[pair] = true;
        _isExcludedFromMaxBalance[marketingWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

// ================= ERC20 =============== //
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    receive() external payable {}
// ========================================== //

//============== Owner Functions ===========//
   
    function owner_setBlacklisted(address account, bool isBlacklisted) public onlyOwner{
        _isBlacklisted[account] = isBlacklisted;
    }
    
    function owner_setBulkIsBlacklisted(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i =0; i < accounts.length; i++){
            _isBlacklisted[accounts[i]] = state;
        }
    }

    function owner_setBuyTaxes(uint8 marketingTax, uint8 lpTax) external onlyOwner{
        uint tTax =  marketingTax + lpTax;
        require(tTax <= 30, "Can't set tax too high");
        buyTax = Tax(marketingTax,lpTax);
        emit TaxesChanged();
    }

    function owner_setSellTaxes(uint8 marketingTax, uint8 lpTax) external onlyOwner{
        uint tTax = marketingTax + lpTax;
        require(tTax <= 80, "Can't set tax too high");
        sellTax = Tax(marketingTax,lpTax);
        emit TaxesChanged();
    }
    
    function owner_setTransferMaxes(uint maxTX_EXACT, uint maxWallet_EXACT) public onlyOwner{
        uint pointFiveSupply = (_tTotal * 5 / 1000) / (10**_decimals);
        require(maxTX_EXACT >= pointFiveSupply && maxWallet_EXACT >= pointFiveSupply, "Invalid Settings");
        maxTxAmount = maxTX_EXACT * (10**_decimals);
        maxWallet = maxWallet_EXACT * (10**_decimals);
    }

    function owner_rescueETH(uint256 weiAmount) public onlyOwner{
        require(address(this).balance >= weiAmount, "Insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }

    function owner_rescueExcessTokens() public{
        // Make sure ca doesn't withdraw the pending taxes to be swapped.
        // Sends excess tokens / accidentally sent tokens back to marketing wallet.
        uint pendingTaxTokens = totalTokensFromTax.lpTokens + totalTokensFromTax.marketingTokens;
        require(balanceOf(address(this)) >  pendingTaxTokens);
        uint excessTokens = balanceOf(address(this)) - pendingTaxTokens;
        _transfer(address(this), marketingWallet, excessTokens);
    }
    
    function owner_setWatchDogMode(bool status_) external onlyOwner{
        watchdogMode = status_;
    }

    function owner_setDogSellTimeForAddress(address holder, uint dTime) external onlyOwner{
        _dogSellTime[holder] = block.timestamp + dTime;
    }

// ========================================//
    
    function _getTaxValues(uint amount, address from, bool isSell) private returns(uint256){
        Tax memory tmpTaxes = buyTax;
        if (isSell){
            tmpTaxes = sellTax;
        }

        uint tokensForMarketing = amount * tmpTaxes.marketingTax / 100;
        uint tokensForLP = amount * tmpTaxes.lpTax / 100;

        if(tokensForMarketing > 0)
            totalTokensFromTax.marketingTokens += tokensForMarketing;

        if(tokensForLP > 0)
            totalTokensFromTax.lpTokens += tokensForLP;

        uint totalTaxedTokens = tokensForMarketing + tokensForLP;

        _tOwned[address(this)] += totalTaxedTokens;
        if(totalTaxedTokens > 0)
            emit Transfer (from, address(this), totalTaxedTokens);
            
        return (amount - totalTaxedTokens);
    }

    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= maxTxAmount || _isExcludedFromMaxBalance[from], "Transfer amount exceeds the _maxTxAmount.");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "Blacklisted, can't trade");

        if(!_isExcludedFromMaxBalance[to])
            require(balanceOf(to) + amount <= maxWallet, "Transfer amount exceeds the maxWallet.");
        
        if (balanceOf(address(this)) >= swapThreshold && block.timestamp >= (_lastSwap + _swapCooldown) && !swapping && from != pair && from != owner() && to != owner())
            swapAndLiquify();
          
        _tOwned[from] -= amount;
        uint256 transferAmount = amount;
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            transferAmount = _getTaxValues(amount, from, to == pair);
            if (from == pair){
                if(watchdogMode){
                    _caughtDogs++;
                    _dogSellTime[to] = block.timestamp + _dogSellTimeOffset;
                }
            }else{
                if (_dogSellTime[from] != 0)
                    require(block.timestamp < _dogSellTime[from]); 
            }
        }

        _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }

    function swapAndLiquify() private lockTheSwap{
        
        if(totalTokensFromTax.marketingTokens > 0){
            uint256 ethSwapped = swapTokensForETH(totalTokensFromTax.marketingTokens);
            if(ethSwapped > 0){
                payable(marketingWallet).transfer(ethSwapped);
                totalTokensFromTax.marketingTokens = 0;
            }
        }   

        if(totalTokensFromTax.lpTokens > 0){
            uint half = totalTokensFromTax.lpTokens / 2;
            uint otherHalf = totalTokensFromTax.lpTokens - half;
            uint balAutoLP = swapTokensForETH(half);
            if (balAutoLP > 0)
                addLiquidity(otherHalf, balAutoLP);
            totalTokensFromTax.lpTokens = 0;
        }

        emit SwapAndLiquify();

        _lastSwap = block.timestamp;
    }

    function swapTokensForETH(uint256 tokenAmount) private returns (uint256) {
        uint256 initialBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        return (address(this).balance - initialBalance);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);

        (,uint256 ethFromLiquidity,) = router.addLiquidityETH {value: ethAmount} (
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
        
        if (ethAmount - ethFromLiquidity > 0)
            payable(marketingWallet).sendValue (ethAmount - ethFromLiquidity);
    }

    event SwapAndLiquify();
    event TaxesChanged();

}