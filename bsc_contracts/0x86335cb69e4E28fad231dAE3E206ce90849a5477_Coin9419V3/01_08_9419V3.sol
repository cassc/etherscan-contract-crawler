/**
 *
 *  9419 DAO
 *  SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./DateTimeLibrary.sol";
import "./Pancake.sol";

// interface
interface I9419Marketing {
    function autoAddLp() external; // auto add lp
}

interface I9419Repurchase{
    function autoSwapAndAddToMarketing() external; // auto repurchase
}

interface I6827Marketing{
    function bonusTokenTo9419(address _to, uint256 _usdt) external; // auto bonus 6827
    function isBonus6827() external view returns (bool);
}

contract TokenTracker{
    constructor (address token, uint256 amount) {
        IERC20(token).approve(msg.sender, amount);
    }
}

contract Coin9419V3 is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
 
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
   
    uint256 private _decimals = 18;
    uint256 private _totalSupply = 221800000000000 * 10**18;
 
    string private _name = "9419 Token";
    string private _symbol = "9419";
    
    uint256 private _commonDiv = 1000; //Fee DIV

    uint256 private _buyLiquidityFee = 10; //1% LP

    uint256 private _buyDestroyFee = 10; //1%
    uint256 private _sellDestroyFee = 10; //1%

    uint256 private _buyRepurchaseFee = 50; // 5%
    uint256 private _sellRepurchaseFee = 70; // 7%

    uint256 public totalBuyFee = 70;//7%
    uint256 public totalSellFee = 80; //8%
   
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
 
    mapping(address => bool) public ammPairs;
    
    bool inSwapAndLiquidity;
    address private _router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E); //prod
    address private factoryAddress;
    address private usdtAddress = address(0x55d398326f99059fF775485246999027B3197955);// prod

    address private marketingAddress;//
    address private repurchaseAddress;// default repurchase fee address
    address public tokenReceiver; 

    address private coin6827Address = 0xeA8dB921475764f7fb8e2548d77F5A6425605B45;//
    address private coin6827Marketing = 0xa5a4D4af045d86A41495A6F82C8842B7FB5c877e; // after 6827 online to ADD

    address private destroyFeeAddress = address(0);

    address public migrantAddress = 0x5a522C949F3DcBc30f511E20D72fb44B770f28e6;

    uint256 public serviceRate;
    uint256 public liquidityRate;

    address private topAddress; // top user
    address constant public rootAddress = address(0x000000000000000000000000000000000000dEaD);
    mapping (address => address) public _recommerMapping;
    mapping(address => mapping(address => bool)) public _refBackMapping;
    mapping(uint256 => address) public totalUserAddres;
    uint256 public userTotal = 0;
    uint256 public startTime;

    uint256 public lvRate = 120; // 12%

    bool public enableRepurchase = true;
    bool public enableMarketingAddLp = true;

    uint256 public checkReferalBonusRate = 5;
    uint256 public maxTxAmount = 3000000000*10**18; // reback threshold amount need to modify after price update

    uint256 public holdBonusAmount = 500000000*10**18;// 5e9
    uint256 public remainTokenAmount = 1*10**18; // 1 token hold
    uint256 public repurchaseThreshold = 100*10**18; // 1 usdt threshold Online 100u TODO

    modifier lockTheSwap {
        inSwapAndLiquidity = true;
        _;
        inSwapAndLiquidity = false;
    }

    modifier onlyMigrant{
        require(msg.sender == migrantAddress, "Err migrant contract address");
        _;
    }

    uint256 private constant MAX = type(uint256).max;
    
    constructor (){
        topAddress = msg.sender; // modify to foundation address online
        _recommerMapping[rootAddress] = address(0xdeaddead);
        _recommerMapping[topAddress] = rootAddress;
        userTotal++;
        totalUserAddres[userTotal] = topAddress;
        startTime = block.timestamp; // set init date time
      
        uniswapV2Router = IUniswapV2Router02(_router);
        factoryAddress = uniswapV2Router.factory();
        uniswapV2Pair  = IUniswapV2Factory(factoryAddress).createPair(address(this), usdtAddress);
        ammPairs[uniswapV2Pair] = true;

        tokenReceiver = address(new TokenTracker(address(usdtAddress), MAX));

        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[destroyFeeAddress] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function setHoldBonusAmount(uint256 _amount) external onlyOwner{
        holdBonusAmount = _amount;
    }

    function setMaxTxAmount(uint256 _amount) external onlyOwner{
        maxTxAmount = _amount;
    }

    function setCheckReferalBonusRate(uint256 _rate) external onlyOwner{
        checkReferalBonusRate = _rate;
    }

    function setCoin6827(address _addr) external onlyOwner{
        coin6827Address = _addr;
    }

    function setCoin6827Marketing(address _addr) external onlyOwner{
        coin6827Marketing = _addr;
    }

    function setMigrantContract(address _addr) external onlyOwner{
        migrantAddress = _addr;
    }

    //----------Fee Config-----------//
    function setRepurchaseThreshold(uint256 _amount) external onlyOwner{
        repurchaseThreshold = _amount;
    }

    function setDestroyFeeAddress(address _destroyAddr) external onlyOwner{
        _isExcludedFromFee[destroyFeeAddress] = false;
        destroyFeeAddress = _destroyAddr;
        _isExcludedFromFee[_destroyAddr] = true;
    }

    function setRepurchaseFeeAddress(address _repurchageAddr) external onlyOwner{
        require(_repurchageAddr != address(0), "Invalid repurchase fee address");
        repurchaseAddress = _repurchageAddr;
    }

    function setMarketingAddress(address _marketAddr) external onlyOwner{
        require(_marketAddr != address(0), "Invalid marketing fee address");
        marketingAddress = _marketAddr;
    }

    function excludeFromFees(address[] memory accounts) public onlyOwner{
        uint len = accounts.length;
        for( uint i = 0; i < len; i++ ){
            _isExcludedFromFee[accounts[i]] = true;
        }
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function getDay() public view returns (uint256) {
        return (block.timestamp - startTime)/1 days;
    }

    /**
        configuration address
     */
    function getAllOfConfigAddress() external view returns (address, address, address){
        return (repurchaseAddress, destroyFeeAddress, marketingAddress);
    }

    /**
        configuration buy slip fee
     */
    function getAllOfBuySlipFee() external view returns (uint256,uint256,uint256){
        return (_buyLiquidityFee, _buyDestroyFee, _buyRepurchaseFee);
    }

    /**
        configuration sell slip fee
     */
    function getAllOfSellSlipFee() external view returns (uint256,uint256){
        return (_sellDestroyFee, _sellRepurchaseFee);
    }

    function setAmmPair(address pair,bool hasPair) external onlyOwner{
        ammPairs[pair] = hasPair;
    }

    function setEnableRepurchase(bool _flag) external onlyOwner{
        enableRepurchase = _flag;
    }

    function setEnableMarketingAddLp(bool _flag) external onlyOwner{
        enableMarketingAddLp = _flag;
    }

    function setLvRate(uint256 _rate) external onlyOwner{
        lvRate = _rate;
    }
 
    function name() public view returns (string memory) {
        return _name;
    }
 
    function symbol() public view returns (string memory) {
        return _symbol;
    }
 
    function decimals() public view returns (uint256) {
        return _decimals;
    }
 
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
 
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    receive() external payable {}
    
    function checkReferalBonus() public view returns (bool) {
        uint256 mktTokenBal = IERC20(address(this)).balanceOf(marketingAddress);
        uint256 lpTokenBal = IERC20(address(this)).balanceOf(uniswapV2Pair);
        uint256 checkLpBal = lpTokenBal.mul(checkReferalBonusRate).div(100);
        if(mktTokenBal < checkLpBal){
            return false;
        }
        return true;
    }

    function _take(uint256 tValue,address from,address to) private {
        _balances[to] = _balances[to].add(tValue);
        emit Transfer(from, to, tValue);
    }

    function _basicTransfer(address from, address to, uint256 amount) private {
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
 
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    
    // --- refer start ---- //
    event AddRelation(address indexed recommer, address indexed user);

    function addRelation(address recommer,address user) internal {
        if(recommer != user 
            && _recommerMapping[user] == address(0x0) 
            && _recommerMapping[recommer] != address(0x0)){
            _recommerMapping[user] = recommer;
            userTotal++;
            totalUserAddres[userTotal] = user;
            emit AddRelation(recommer, user);
        }
    }

    function getRefBackMapping(address from, address to) public view returns (bool){
        return _refBackMapping[from][to];
    }

    function getRecommer(address addr) public view returns(address){
        return _recommerMapping[addr];
    }

    function getForefathers(address addr,uint num) public view returns(address[] memory fathers) {
        fathers = new address[](num);
        address parent  = addr;
        for( uint i = 0; i < num; i++){
            parent = _recommerMapping[parent];
            if(parent == address(0xdead) || parent == address(0) ) break;
            fathers[i] = parent;
        }
    }

    function addRelationEx(address recommer,address user) external onlyOwner{
        addRelation(recommer, user);
    }

    function importRelation(address recommer, address user) external onlyMigrant{
        addRelation(recommer, user);
    }

    event PreAddRelation(address indexed recommer, address indexed user);

    function preRelation(address from, address to) private {
        //A->B
        if(_refBackMapping[to][from]){
            // is A ' ref b?
            //Search Back B->A
            addRelation(to, from);
        } else if (!_refBackMapping[from][to] && !_refBackMapping[to][from]) {
            _refBackMapping[from][to] = true;
            emit PreAddRelation(from, to);
        }
    }

    // -----Refer end-----//
 
    struct Param{
        bool takeFee;
        bool bonusRecord; // false no record, buy = true Record   
        uint256 tTransferAmount;
        uint256 tLiquidityFee; // liquidity fee
        uint256 tDestroyFee; // destroy fee
        uint256 tRepurchaseFee;// repurchase fee
    }

    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!from.isContract()) {
             // need remaind 1 token
            uint fromBalance = balanceOf(from);
            require(fromBalance > remainTokenAmount, "must remain 1 token");
            if( fromBalance == amount ){
                amount = amount.sub(remainTokenAmount);
            }
        }

        if (from != to && !ammPairs[from] && !ammPairs[to] && 
            from != marketingAddress && to != marketingAddress && 
            from != repurchaseAddress && to != repurchaseAddress) {
            if ((!getRefBackMapping(from, to) && balanceOf(from) >= holdBonusAmount) || getRefBackMapping(to, from)) {
                preRelation(from, to);
            }
        }
        
        uint256 _tokenBal = balanceOf(address(this));
        if( _tokenBal >= maxTxAmount
            && !inSwapAndLiquidity 
            && msg.sender != uniswapV2Pair
            && msg.sender != marketingAddress
            && msg.sender != repurchaseAddress
            && IERC20(uniswapV2Pair).totalSupply() > 10 * 10**18 ){

            _processSwap(_tokenBal); 

            _dividendUsdt(_tokenBal);
        }

        bool takeFee = true;
        if( _isExcludedFromFee[from] || _isExcludedFromFee[to] || from ==  address(uniswapV2Router)){
            takeFee = false;
        }
        
        Param memory param;
        if( takeFee ){
            param.takeFee = true;
            if(ammPairs[from]){  // buy or removeLiquidity
                _getBuyParam(amount, param);
            }
            if(ammPairs[to]){
                _getSellParam(amount, param);   //sell or addLiquidity
            }
            if(!ammPairs[from] && !ammPairs[to]){
                param.takeFee = false;
                param.tTransferAmount = amount;
            }
        } else {
            param.takeFee = false;
            param.tTransferAmount = amount;
        }

        // buy or sell to check repurchase
        if( takeFee && msg.sender != marketingAddress && msg.sender != repurchaseAddress ){
            _repurchase6827Pool();
            // marketing add lp check
            _marketingAutoAddLp();
        }

        uint256 fatherBonus; 
        if( param.bonusRecord && msg.sender != marketingAddress && msg.sender != repurchaseAddress ){
            fatherBonus = _marketingBonus(to, amount);
        }

        _tokenTransfer(from, to, amount, param);

        if ( param.bonusRecord && msg.sender != marketingAddress && msg.sender != repurchaseAddress ) {
            if ( checkReferalBonus() ){
                _dividendMarketingBonus(fatherBonus, to);
            }
            _dividend6827Bonus(param.tTransferAmount, to);
        }
    }
 
    function _getBuyParam(uint256 tAmount, Param memory param) private view  {
        param.tLiquidityFee = tAmount.mul(_buyLiquidityFee).div(_commonDiv);
        param.tDestroyFee = tAmount.mul(_buyDestroyFee).div(_commonDiv);
        param.tRepurchaseFee = tAmount.mul(_buyRepurchaseFee).div(_commonDiv);
        param.tTransferAmount = tAmount.sub(param.tLiquidityFee).sub(param.tDestroyFee).sub(param.tRepurchaseFee);
        param.bonusRecord = true;//buy
    }
 
    function _getSellParam(uint256 tAmount, Param memory param) private view  {
        param.tDestroyFee = tAmount.mul(_sellDestroyFee).div(_commonDiv);
        param.tRepurchaseFee = tAmount.mul(_sellRepurchaseFee).div(_commonDiv);
        param.tTransferAmount = tAmount.sub(param.tDestroyFee).sub(param.tRepurchaseFee);
        param.bonusRecord = false;//sell
    }

    function _marketingAutoAddLp() private {
        if(enableMarketingAddLp){
            try I9419Marketing(marketingAddress).autoAddLp() {} catch {}
        }
    }

    /**
      repurchase pool buy 6827 to repurchase wallet
     */
    function _repurchase6827Pool() private {
        if(enableRepurchase){
            try I9419Repurchase(repurchaseAddress).autoSwapAndAddToMarketing() {} catch {}
        }
    }

    function _takeFee(Param memory param, address from) private {
        if(param.tLiquidityFee > 0) {
            _take(param.tLiquidityFee, from, address(this));
            liquidityRate += param.tLiquidityFee;
        }

        if (param.tRepurchaseFee > 0) {
            _take(param.tRepurchaseFee, from, address(this));
            serviceRate += param.tRepurchaseFee;
        }

        if( param.tDestroyFee > 0 ) {
            // destroy fee
            _take(param.tDestroyFee, from, destroyFeeAddress);
        }
    }

    function _processSwap(uint256 tokenBal) private lockTheSwap {
        // to save gas fee, swap bnb at once, sub the amount of swap to 6827 
        swapTokensForUsdt(tokenBal, tokenReceiver); // swap coin to at once save gas fee
    }

    function _dividendUsdt(uint256 _totalDiv) private {
        uint256 _totalUsdtBal = IERC20(usdtAddress).balanceOf(tokenReceiver);
        if ( _totalUsdtBal > 0) {
            uint256 _sfRate = serviceRate.mul(1000000).div(_totalDiv);
            serviceRate = 0;
            liquidityRate = 0;

            uint256 serviceUsdt = _totalUsdtBal.mul(_sfRate).div(1000000);
            uint256 liquidityUsdt = _totalUsdtBal.sub(serviceUsdt);
            if( serviceUsdt > 0 ) {
                IERC20(usdtAddress).transferFrom(tokenReceiver, address(this), serviceUsdt);
            }
            if( liquidityUsdt > 0 ) {
                IERC20(usdtAddress).transferFrom(tokenReceiver, marketingAddress, liquidityUsdt);
            }
        }

        uint256 thisUsdtBal = IERC20(usdtAddress).balanceOf(address(this));
        if ( thisUsdtBal >= repurchaseThreshold ){
            swapUsdtFor6827(thisUsdtBal, repurchaseAddress);
        }
    }

    event ParamEvent(address indexed sender, uint256 tLiquidityFee, uint256 tDestroyFee, uint256 tRepurchaseFee, uint256 tTransferAmount, string a);
    event FatherBonus(address indexed sender, address indexed father, uint256 bonus);

    function _dividendMarketingBonus(uint256 fatherBonus, address recipient) private {
        if ( fatherBonus > 0 && balanceOf(marketingAddress) >= fatherBonus) {
            _basicTransfer(marketingAddress, _recommerMapping[recipient], fatherBonus);
        }
    }

    function _dividend6827Bonus(uint256 buyAmount, address buyer) private {
        if (getRecommer(buyer) != address(0) && I6827Marketing(coin6827Marketing).isBonus6827()){
            uint256 usdtAmount = worthTokenUsdt(buyAmount);
            if ( usdtAmount > 100 ){
                try I6827Marketing(coin6827Marketing).bonusTokenTo9419(buyer, usdtAmount) {} catch {}
            }
        }
    }

    /**
        calc marketing bonus to father
     */
    event MarketingBonus(address indexed sender, uint256 bonus);

    function _marketingBonus(address buyer, uint256 tAmount) private view returns(uint256 fatherBonus){
        //buy calc user's balance is large than 100U
        if(_recommerMapping[buyer] != address(0)){
            fatherBonus = tAmount.mul(lvRate).div(_commonDiv);
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, Param memory param) private {
        // excute transfer from
        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(param.tTransferAmount);
        emit Transfer(sender, recipient, param.tTransferAmount);

        if(param.takeFee){
            emit ParamEvent(sender,
            param.tLiquidityFee,
            param.tDestroyFee,
            param.tRepurchaseFee,
            param.tTransferAmount, "takeFee true");

            _takeFee(param, sender);
        }
    }

    function worthTokenUsdt(uint256 _tokenAmount) public view returns (uint256){
        address[] memory _path = new address[](2);
        _path[0] = address(this);
        _path[1] = usdtAddress;
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(_tokenAmount, _path);
        return amounts[1];
    }

    function swapTokensForUsdt(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdtAddress;

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp
        );
    }

    function swapUsdtFor6827(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = usdtAddress;
        path[1] = coin6827Address;

        IERC20(usdtAddress).approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp + 300
        );
    }
}