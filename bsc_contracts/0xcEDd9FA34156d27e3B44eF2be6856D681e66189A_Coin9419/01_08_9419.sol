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


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        // (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
 
contract Operator is Context {
    address private _operator;
    constructor() {
        _transferOperator(_msgSender());
    }

    modifier onlyOperator() {
        require(_operator == _msgSender(), "Operator: caller is not the operator");
        _;
    }
    function renounceOperator() public virtual onlyOperator {
        _transferOperator(address(0));
    }
    function transferOperator(address newOperator) public virtual onlyOperator {
        require(newOperator != address(0), "Operator: new operator is the zero address");
        _transferOperator(newOperator);
    }
    function _transferOperator(address newOperator) internal virtual {
        // address oldOperator = _operator;
        _operator = newOperator;
    }
}
// interface
interface I9419Marketing {
    function autoAddLp() external; // auto add lp
    function dayTimes(uint256) external view returns (uint256);
    function getDay() external view returns (uint256);
    function getHour() external view returns (uint256);
    function recordHour() external view returns (uint256);
}

interface I9419Repurchase{
    function autoSwapAndAddToMarketing() external; // auto repurchase
    function recordDay() external view returns(uint256);
    function getDay() external view returns(uint256);
}

contract Coin9419 is IERC20, Context, Ownable, Operator {
    using SafeMath for uint256;
    using Address for address;
 
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
   
    uint256 private _decimals = 18;
    uint256 private _totalSupply = 2000000000000000 * 10**18;
 
    string private _name = "9419";
    string private _symbol = "9419";
    
    uint256 private _commonDiv = 1000; //Fee DIV

    uint256 private _buyLiquidityFee = 10; //1% LP
    uint256 private _sellServiceFee = 10; //1% tech service fee

    uint256 private _sellFoundationFee = 10; //1%

    uint256 private _buyDestroyFee = 10; //1%
    uint256 private _sellDestroyFee = 10; //1%

    uint256 private _buyRepurchaseFee = 50; // 5%
    uint256 private _sellRepurchaseFee = 50; // 5%

    uint256 public totalBuyFee = 70;//7%
    uint256 public totalSellFee = 80; //8%
   
    IUniswapV2Router02 private immutable uniswapV2Router;
    address private immutable uniswapV2Pair;
 
    mapping(address => bool) public ammPairs;
    
    bool inSwapAndLiquidity;
    // address private _router = address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //testnet
    address private _router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E); //prod
    address private factoryAddress;

    uint256 public repurchaseAmount = 2*10**18; // 2 bnb

    // address public mbankAddress = address(0x9dA171B8F4648852b6fc8679879501369478D660); //mbank test coin
    address public mbankAddress = address(0x9E9Bef94795Bfe87a11A0369B4e0c3B60A6FCf2B);// mbank address
    address public mbankBnbPair;

    address private marketingAddress = address(0x2fB6e0865653c071D05AbB51c5F4335dDfFc6534);//
    address private repurchaseAddress = address(0x23cFB5a615F9a9eF23C58E13561d569aBbe487c9);// default repurchase fee address
    
    address private foundationAddress = address(0x9977815948139fc19AdB1152398a7DAb90fAc0e3);

    address private destroyFeeAddress = address(0);
    address private serviceFeeAddress = address(0x32EFd4C58BF98C933190B0196064AeB4B1Eb4BE1); 
    address private mintDaoAddress = address(0xe142277C522007055c0cF756219f5CA99c45edBC);

    uint256 public repurchaseRate;
    uint256 public serviceRate;
    uint256 public foundationRate;
    uint256 public liquidityRate;

    address private topAddress; // top user
    address constant public rootAddress = address(0x000000000000000000000000000000000000dEaD);
    mapping (address => address) public _recommerMapping;
    mapping(uint256 => address) public totalUserAddres;
    mapping(uint => uint256) public dayDestroyTotal;
    uint256 public userTotal = 0;
    uint256 public startTime;

    bool public enableRepurchase = true;
    bool public enableMarketingAddLp = true;

    uint256 public maxTxAmount = 100000000*10**18; // reback threshold amount need to modify after price update

    uint256 public holdBonusAmount = 100000000*10**18;// 1e9
    uint256 public remainTokenAmount = 1*10**17; // 0.1 remain

    modifier lockTheSwap {
        inSwapAndLiquidity = true;
        _;
        inSwapAndLiquidity = false;
    }

    uint256 private constant MAX = type(uint256).max;
    
    constructor (){
        topAddress = msg.sender;
        _recommerMapping[rootAddress] = address(0xdeaddead);
        _recommerMapping[topAddress] = rootAddress;
        userTotal++;
        totalUserAddres[userTotal] = topAddress;
        startTime = block.timestamp;
      
        uniswapV2Router = IUniswapV2Router02(_router);
        factoryAddress = uniswapV2Router.factory();
        uniswapV2Pair  = IUniswapV2Factory(factoryAddress).createPair(address(this), uniswapV2Router.WETH());
        ammPairs[uniswapV2Pair] = true;
        mbankBnbPair = IUniswapV2Factory(factoryAddress).getPair(mbankAddress, uniswapV2Router.WETH());
        TransferHelper.safeApprove(uniswapV2Router.WETH(), _router, MAX);

        _isExcludedFromFee[topAddress] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[destroyFeeAddress] = true;
        _isExcludedFromFee[serviceFeeAddress] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[repurchaseAddress] = true;
        _isExcludedFromFee[foundationAddress] = true;
        _isExcludedFromFee[0xFDF238A1DB0040e3Db349a4C24E0E883Be64dE7a] = true;

        _isExcludedFromFee[mintDaoAddress] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), topAddress, _totalSupply);
    }

    function setStartTime(uint256 _startTime) external onlyOwner{
        startTime = _startTime;
    }

    function setHoldBonusAmount(uint256 _amount) external onlyOwner{
        holdBonusAmount = _amount;
    }

    function setRemainTokenAmount(uint256 _amount) external onlyOwner{
        remainTokenAmount = _amount;
    }

    function setMaxTxAmount(uint256 _amount) external onlyOperator{
        maxTxAmount = _amount;
    }

    //----------Fee Config-----------//
    function setFoundationFeeAddress(address _foundationAddr) external onlyOwner{
        require(_foundationAddr != address(0), "Invalid foundation address");
        foundationAddress = _foundationAddr;
        _isExcludedFromFee[_foundationAddr] = true;
    } 

    function setDestroyFeeAddress(address _destroyAddr) external onlyOwner{
        destroyFeeAddress = _destroyAddr;
        _isExcludedFromFee[_destroyAddr] = true;
    }

    function setMbankAddress(address _mbankAddr) external onlyOwner{
        require(_mbankAddr.isContract(), "Invalid mbank address");
        mbankAddress = _mbankAddr;
        mbankBnbPair = IUniswapV2Factory(factoryAddress).getPair(mbankAddress, uniswapV2Router.WETH());
    }

    function setRepurchaseAmount(uint256 _repurchaseBnbAdmount) external onlyOwner{
        repurchaseAmount = _repurchaseBnbAdmount;
    }

    function setServiceFeeAddress(address _serviceAddr) external onlyOwner{
        require(_serviceAddr != address(0), "Invalid service address");
        serviceFeeAddress = _serviceAddr;
        _isExcludedFromFee[_serviceAddr] = true;
    }

    function setRepurchaseFeeAddress(address _repurchageAddr) external onlyOwner{
        require(_repurchageAddr != address(0), "Invalid repurchase fee address");
        repurchaseAddress = _repurchageAddr;
        _isExcludedFromFee[_repurchageAddr] = true;
    }

    function setMarketingAddress(address _marketAddr) external onlyOwner{
        require(_marketAddr != address(0), "Invalid marketing fee address");
        marketingAddress = _marketAddr;
        _isExcludedFromFee[_marketAddr] = true;
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
    function getAllOfConfigAddress() public view returns (address, address, address, address, address){
        return (repurchaseAddress, destroyFeeAddress, serviceFeeAddress, foundationAddress, marketingAddress);
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
    function getAllOfSellSlipFee() external view returns (uint256,uint256,uint256,uint256){
        return (_sellServiceFee, _sellDestroyFee, _sellFoundationFee, _sellRepurchaseFee);
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
 
    function _take(uint256 tValue,address from,address to) private {
        _balances[to] = _balances[to].add(tValue);
        emit Transfer(from, to, tValue);
    }
    
    function getForefathers(address owner,uint num) public view returns(address[] memory fathers){
        fathers = new address[](num);
        address parent  = owner;
        for( uint i = 0; i < num; i++){
            parent = _recommerMapping[parent];
            if( parent == rootAddress || parent == address(0) ) break;
            fathers[i] = parent;
        }
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
 
    event AddRelation(address recommer, address user);
    
    function addRelationEx(address recommer,address user) internal {
        if(recommer != user 
            && _recommerMapping[user] == address(0x0) 
            && _recommerMapping[recommer] != address(0x0) ){
                _recommerMapping[user] = recommer;
                userTotal++;
                totalUserAddres[userTotal] = user;
                emit AddRelation(recommer, user);
        }
    }
 
    struct Param{
        bool takeFee;
        bool bonusRecord; // false no record, buy = true Record   
        uint256 tTransferAmount;
        uint256 tLiquidityFee; // liquidity fee
        uint256 tServiceFee; // tech service fee
        uint256 tDestroyFee; // destroy fee
        uint256 tFoundationFee; // foundation fee
        uint256 tRepurchaseFee;// repurchase fee
    }

    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!from.isContract()) {
             // need remaind 0.1 token
            uint fromBalance = balanceOf(from);
            require(fromBalance > remainTokenAmount, "must remain 0.1 token");
            if( fromBalance == amount ){
                amount = amount.sub(remainTokenAmount);
            }
        }

        if( !to.isContract() && !from.isContract()
            && _recommerMapping[to] == address(0) 
            && balanceOf(from) >= holdBonusAmount ){
            addRelationEx(from, to);
        }

        uint256 _tokenBal = balanceOf(address(this));
        if( _tokenBal >= maxTxAmount
            && !inSwapAndLiquidity 
            && !ammPairs[msg.sender] 
            && msg.sender != marketingAddress
            && msg.sender != repurchaseAddress
            && IERC20(uniswapV2Pair).totalSupply() > 10 * 10**18 ){
            _processSwap(_tokenBal);

            _repurchaseMbankPool();
            // marketing add lp check
            _marketingAutoAddLp();
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

        uint256 fatherBonus; 
        uint256 buyerBonus;
        if( param.bonusRecord ){
            (fatherBonus, buyerBonus) = _marketingBonus(to, param.tTransferAmount);
        }

        _tokenTransfer(from, to, amount, param);

        if(to == destroyFeeAddress){
            uint _day = getDay();
            dayDestroyTotal[_day] = dayDestroyTotal[_day].add(param.tTransferAmount);
        }

        if( param.bonusRecord ){
            _dividendMarketingBonus(fatherBonus, buyerBonus, to);
        }
    }
 
    function _getBuyParam(uint256 tAmount, Param memory param) private view  {
        param.tLiquidityFee = tAmount.mul(_buyLiquidityFee).div(_commonDiv);
        param.tDestroyFee = tAmount.mul(_buyDestroyFee).div(_commonDiv);
        param.tRepurchaseFee = tAmount.mul(_buyRepurchaseFee).div(_commonDiv);
        uint256 tFee = tAmount.mul(totalBuyFee).div(_commonDiv);
        param.tTransferAmount = tAmount.sub(tFee);
        param.bonusRecord = true;//buy
    }
 
    function _getSellParam(uint256 tAmount, Param memory param) private view  {
        param.tServiceFee = tAmount.mul(_sellServiceFee).div(_commonDiv);
        param.tDestroyFee = tAmount.mul(_sellDestroyFee).div(_commonDiv);
        param.tFoundationFee = tAmount.mul(_sellFoundationFee).div(_commonDiv);
        param.tRepurchaseFee = tAmount.mul(_sellRepurchaseFee).div(_commonDiv);
        uint256 tFee = tAmount.mul(totalSellFee).div(_commonDiv);
        param.tTransferAmount = tAmount.sub(tFee);
        param.bonusRecord = false;//sell
    }

    function _marketingAutoAddLp() private {
        if(enableMarketingAddLp){
            try I9419Marketing(marketingAddress).autoAddLp() {} catch {}
        }
    }

    /**
      repurchase pool buy mbank to repurchase wallet
     */
    function _repurchaseMbankPool() private {
        uint256 _repurchasePool = address(this).balance;
        if(enableRepurchase && _repurchasePool >= repurchaseAmount && mbankBnbPair != address(0)){
            swapEthForMbank(_repurchasePool, repurchaseAddress);
            try I9419Repurchase(repurchaseAddress).autoSwapAndAddToMarketing() {} catch {}
        }
    }

    function _takeFee(Param memory param, address from) private {
        uint256 _totalCollectAmount;
        if(param.tLiquidityFee > 0){
            _totalCollectAmount += param.tLiquidityFee;
            liquidityRate += param.tLiquidityFee;
        }
        if(param.tServiceFee > 0){
            _totalCollectAmount += param.tServiceFee;
            serviceRate += param.tServiceFee;
        }

        if(param.tRepurchaseFee > 0){
            _totalCollectAmount += param.tRepurchaseFee;
            repurchaseRate += param.tRepurchaseFee;
        }

        if(param.tFoundationFee > 0){
            _totalCollectAmount += param.tFoundationFee;
        }

        if(_totalCollectAmount > 0){
            _take(_totalCollectAmount, from, address(this));
        }

        if( param.tDestroyFee > 0 ){
            // destroy fee
            _take(param.tDestroyFee, from, destroyFeeAddress);
            uint _day = getDay();
            dayDestroyTotal[_day] = dayDestroyTotal[_day].add(param.tDestroyFee);
        }
    }

    function _processSwap(uint256 tokenBal) private lockTheSwap {
        // to save gas fee, swap bnb at once, sub the amount of swap to mbank 
        uint256 _swapToBnb = repurchaseRate.add(liquidityRate).add(serviceRate);
        if(tokenBal >= _swapToBnb){
            uint256 _beforeBnbBal = address(this).balance;
            swapTokensForEth(_swapToBnb, address(this)); // swap coin to bnb at once
            uint256 _increaseBnbBal = address(this).balance.sub(_beforeBnbBal);// swap get bnb amount at this transaction

            uint256 _lpRate = liquidityRate.mul(10000).div(_swapToBnb);
            uint256 _sfRate = serviceRate.mul(10000).div(_swapToBnb);
            repurchaseRate = 0;
            liquidityRate = 0;
            serviceRate = 0;
            if( _increaseBnbBal > 0){
                // lp fee rate * bnb bal
                if(_lpRate > 0){
                    payable(marketingAddress).transfer(_increaseBnbBal.mul(_lpRate).div(10000));
                }
                if(_sfRate > 0){
                    payable(serviceFeeAddress).transfer(_increaseBnbBal.mul(_sfRate).div(10000));
                }
            }

            uint256 _swapToMbank = tokenBal.sub(_swapToBnb);
            if(_swapToMbank > 0) {
                swapTokenToMbank(_swapToMbank, foundationAddress);
            }
        }
    }

    event ParamEvent(address indexed sender,uint256 tLiquidityFee,uint256 tSerivceFee,
    uint256 tDestroyFee,uint256 tFoundationFee,uint256 tRepurchaseFee,uint256 tTransferAmount,string a);
    event FatherBonus(address indexed sender, address indexed father, uint256 bonus);

    function _dividendMarketingBonus(uint256 fatherBonus, uint256 buyerBonus, address recipient) private {
        uint256 _totalBonus = fatherBonus.add(buyerBonus);
        if( _totalBonus > 0 && balanceOf(marketingAddress) >= _totalBonus){
            if(buyerBonus > 0){
                IERC20(address(this)).transferFrom(marketingAddress, recipient, buyerBonus);
            }
            if(fatherBonus > 0){
                address _father = _recommerMapping[recipient];
                IERC20(address(this)).transferFrom(marketingAddress, _father, fatherBonus);
            }
        }
    }

    event MarketingBonus(address indexed sender, uint256 bonus);
    /**
        calc marketing bonus to father
     */
    function _marketingBonus(address buyer, uint256 tAmount) private view 
        returns(uint256 fatherBonus, uint256 buyerBonus){
        //buy calc user's balance is large than 100U
        uint256 tenPercentBonus = tAmount.mul(11).div(100); 
        address _father = _recommerMapping[buyer];
        if(_father != address(0) && balanceOf(_father) >= holdBonusAmount){
            fatherBonus = tenPercentBonus.mul(7).div(10);
        }
        if(balanceOf(buyer) >= holdBonusAmount){
            buyerBonus =  tenPercentBonus.sub(fatherBonus);
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
            param.tServiceFee,
            param.tDestroyFee,
            param.tFoundationFee,
            param.tRepurchaseFee,
            param.tTransferAmount, "takeFee true");

            _takeFee(param, sender);
        }
    }
 
    function swapTokensForEth(uint256 tokenAmount,address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            to,
            block.timestamp
        );
    }

    function swapEthForMbank(uint256 bnbAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = mbankAddress;
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0, 
            path, 
            to, 
            block.timestamp
        );
    }

    function swapTokenToMbank(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = mbankAddress;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path, 
            to, 
            block.timestamp + 300
        );
    }

    function clearStuckBalance(address _receiver) external onlyOperator {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
    }

    function rescueToken(address _token, uint256 _value) external onlyOperator{
        TransferHelper.safeTransfer(_token, msg.sender, _value);
    }
}