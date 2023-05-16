/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

/**
 *Submitted for verification at BscScan.com on 2023-04-30
*/
// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.19;
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ETHereum/solidity/issues/2691
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
interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
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
contract pepe1 is Context, IBEP20, Ownable {
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBot;
    address[] private _excluded;
    bool public swapEnabled = true;
    bool private swapping;
    IRouter public router;
    address public pair;
    uint8 private constant _decimals = 18;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1_000_000_000_000_000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    address public marketingAddress = 0x5EBC7ADAda27f9f347e238B08b41243535dc92DC;
    address public TeamAddress = 0x81e33802fBEBAc43BCa6DeC57CE2B57BB69242bd;
    string private constant _name = "pepe1 ";
    string private constant _symbol = "pepe1";

    struct Taxes {
    uint256 RewardsFee;
    uint256 Team;
    uint256 marketing;
    uint256 liquidity;
    }
    Taxes public Buytaxes = Taxes(1,2,5,2);
    Taxes public sellTaxes = Taxes(1,2,5,2);
    struct TotFeesPaidStruct{
        uint256 RewardsFee;
        uint256 marketing;
        uint256 Team;
        uint256 liquidity;
    }
    TotFeesPaidStruct public totFeesPaid;
    struct valuesFromGetValues{
    uint256 rAmount;
    uint256 rTransferAmount;
    uint256 rRewardsFee;
    uint256 rMarketing;
    uint256 rTeam;
    uint256 rLiquidity;
    uint256 tTransferAmount;
    uint256 tRewardsFee;
    uint256 tMarketing;
    uint256 tTeam;
    uint256 tLiquidity;
    }
   
   
    uint256 public swapTokensAtAmount = 5_000_000_000_000 * 10**_decimals; //Should be 0.1% or lower
    uint256 private maxSellAmount = 1_000_000_000_000_000 * 10**_decimals;
    uint256 private maxBuyAmount = 1_000_000_000_000_000 * 10**_decimals;
    uint256 private maxWalletBalance = 1_000_000_000_000_000 * 10**_decimals;

    event FeesChanged();
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
    constructor () {
        // @ES: PancakeSwap V2 Router BSC mainnet address: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        // @ES: PancakeSwap V2 Router BSC testnet address: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        IRouter _router = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());
        router = _router;
        pair = _pair;
       
        excludeFromReward(pair);
        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingAddress]=true;
        _isExcludedFromFee[TeamAddress] = true;
        emit Transfer(address(0), owner(), _tTotal);
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
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferRewardsFee, bool isSell) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRewardsFee) {
            valuesFromGetValues memory s = _getValues(tAmount, false, isSell);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true, isSell);
            return s.rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
   
    function setSellTaxes(uint256 _RewardsFee, uint256 _marketing, uint256 _Team, uint256 _liquidity) public onlyOwner {
        sellTaxes.RewardsFee = _RewardsFee;
        sellTaxes.marketing = _marketing;
        sellTaxes.Team = _Team;
        sellTaxes.liquidity = _liquidity;
        emit FeesChanged();
    }
    function _reflectRewardsFee(uint256 rRewardsFee, uint256 tRewardsFee) private {
        _rTotal -=rRewardsFee;
        totFeesPaid.RewardsFee +=tRewardsFee;
    }
    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totFeesPaid.liquidity +=tLiquidity;
        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tLiquidity;
        }
        _rOwned[address(this)] +=rLiquidity;
    }
    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totFeesPaid.marketing +=tMarketing;
        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tMarketing;
        }
        _rOwned[address(this)] +=rMarketing;
    }
   
    function _takeTeam(uint256 rTeam, uint256 tTeam) private {
        totFeesPaid.Team += tTeam;
        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+= tTeam;
        }
        _rOwned[address(this)] += rTeam;
    }
    function _getValues(uint256 tAmount, bool takeFee, bool isSell) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee, isSell);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRewardsFee, to_return.rMarketing, to_return.rTeam, to_return.rLiquidity) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }
    function _getTValues(uint256 tAmount, bool takeFee, bool isSell) private view returns (valuesFromGetValues memory s) {
        if(!takeFee) {
        s.tTransferAmount = tAmount;
        return s;
        }
        Taxes memory temp;
        if(isSell) temp = sellTaxes;
        else temp = Buytaxes;
       
        s.tRewardsFee = tAmount*temp.RewardsFee/100;
        s.tMarketing = tAmount*temp.marketing/100;
        s.tLiquidity = tAmount*temp.liquidity/100;
        s.tTeam = tAmount*temp.Team/100;
        s.tTransferAmount = tAmount-s.tRewardsFee-s.tMarketing-s.tTeam-s.tLiquidity;
        return s;
    }
    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRewardsFee,uint256 rMarketing, uint256 rTeam, uint256 rLiquidity) {
        rAmount = tAmount*currentRate;
        if(!takeFee) {
        return(rAmount, rAmount, 0,0,0,0);
        }
        rRewardsFee = s.tRewardsFee*currentRate;
        rMarketing = s.tMarketing*currentRate;
        rTeam = s.tTeam*currentRate;
        rLiquidity = s.tLiquidity*currentRate;
        rTransferAmount =  rAmount-rRewardsFee-rMarketing-rTeam-rLiquidity;
        return (rAmount, rTransferAmount, rRewardsFee,rMarketing,rTeam,rLiquidity);
    }
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        require(!_isBot[from] && !_isBot[to], "You are a bot");
               
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !swapping){
            if(from == pair){
                require(amount <= maxBuyAmount, "You are exceeding maxBuyAmount");
            }
            if(to == pair){
                require(amount <= maxSellAmount, "You are exceeding maxSellAmount");
            }
            if(to != pair){
                require(balanceOf(to) + amount <= maxWalletBalance, "You are exceeding maxWalletBalance");
            }
        }
       
        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if(!swapping && swapEnabled && canSwap && from != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            swapAndLiquify(swapTokensAtAmount);
        }
        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]), to == pair);
    }

    //this Method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee, bool isSell) private {
        valuesFromGetValues memory s = _getValues(tAmount, takeFee, isSell);
        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender]-tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }
        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
       
        if(s.rRewardsFee > 0 || s.tRewardsFee > 0) _reflectRewardsFee(s.rRewardsFee, s.tRewardsFee);
        if(s.rLiquidity > 0 || s.tLiquidity > 0) {
            _takeLiquidity(s.rLiquidity,s.tLiquidity);
        }
        if(s.rMarketing > 0 || s.tMarketing > 0){
            _takeMarketing(s.rMarketing, s.tMarketing);
        }
        if(s.rTeam > 0 || s.tTeam > 0){
            _takeTeam(s.rTeam, s.tTeam);
        }
       
        emit Transfer(sender, recipient, s.tTransferAmount);
        emit Transfer(sender, address(this), s.tLiquidity + s.tTeam + s.tMarketing);
       
    }
    function swapAndLiquify(uint256 tokens) private lockTheSwap{
    // Split the contract balance into halves
        uint256 denominator = (sellTaxes.liquidity + sellTaxes.marketing + sellTaxes.Team) * 2;
        uint256 tokensToAddLiquidityWith = tokens * sellTaxes.liquidity / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 deltaBalance = address(this).balance - initialBalance;
        uint256 unitBalance= deltaBalance / (denominator - sellTaxes.liquidity);
        uint256 ETHToAddLiquidityWith = unitBalance * sellTaxes.liquidity;
        if(ETHToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);
        }
        uint256 marketingAmt = unitBalance * 2 * sellTaxes.marketing;
        if(marketingAmt > 0){
            payable(marketingAddress).transfer(marketingAmt);
        }
       
        uint256 TeamAmt = unitBalance * 2 * sellTaxes.Team;
        if(TeamAmt > 0){
            payable(TeamAddress).transfer(TeamAmt);
        }
    }
    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);
        // add the liquidity
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }
    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    function updateMarketingWallet(address newWallet) external onlyOwner{
        marketingAddress = newWallet;
    }
   
    function updateTeamWallet(address newTeamWallet) external onlyOwner{
        TeamAddress = newTeamWallet;
    }
   
   
    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**_decimals;
    }
    function updateSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }
   
    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner{
        // LFG
        router = IRouter(newRouter);
        pair = newPair;
    }
   
    function isBot(address account) private view returns(bool){
        return _isBot[account];
    }
   
    //Use this in case ETH are sent to the contract by mistake
    function rescueETH(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }
   
    // Function to allow admin to claim *other* BEP20 tokens sent to this contract (by mistake)
    function rescueAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        require(_tokenAddr != address(this), "Cannot transfer out Token123!");
        IBEP20(_tokenAddr).transfer(_to, _amount);
    }
    receive() external payable{
    }
}