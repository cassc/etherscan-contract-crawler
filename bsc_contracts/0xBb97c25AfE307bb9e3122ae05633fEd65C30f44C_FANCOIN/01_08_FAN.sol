// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

import "./Pancake.sol";

contract FANCOIN is IERC20Metadata, Ownable, Operator {
    using SafeMath for uint256;
    using Address for address;
 
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _antiRobot;

    uint8 private _decimals = 18;
    uint256 private _totalSupply = 10000000000 * 10**18;
 
    string private _name = "FANCOIN"; // FAN COIN
    string private _symbol = "FAN"; // FAN
    
    uint256 private _commonDiv = 10000;

    uint256 private _lpFee = 400; // 4%
    uint256 private _reflowFee = 50; // 0.5%
    uint256 private _burnFee = 50; // 0.5%
    uint256 private _communityFee = 100; // 1%
    uint256 public totalFee = 600; //6%

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    address private uniswapV2Pair_BNB;
 
    mapping(address => bool) public ammPairs;
    
    uint256 private constant MAX = type(uint256).max;
    address private _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //prod
    address public usdtAddress = 0x55d398326f99059fF775485246999027B3197955; // prod
    address private lpFeeAddress;
    // address private lpRankFeeAddress;
    // address private holderFeeAddress;
    address private middlePoolAddress;
    address private communityFeeAddress;
    address private reflowFeeAddress;
    address private marketFeeAddress;
    address private lpAddAddress;

    uint256 public startTime;

    mapping (uint => uint256) public lpBonus;

    uint256 public _maxTxAmount = 1000 * 10**18; // prod collection token to save gas

    bool inSwapAndLiquify;
    bool public isLiquidityInBnb = true;

    constructor (){
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Router = _uniswapV2Router;

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), usdtAddress);
        uniswapV2Pair = _uniswapV2Pair;

        address _uniswapV2Pair_bnb = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Pair_BNB = _uniswapV2Pair_bnb;
        ammPairs[uniswapV2Pair] = true;
        ammPairs[uniswapV2Pair_BNB] = true;

        lpFeeAddress = _msgSender();
        lpAddAddress = _msgSender();
        
        _isExcludedFromFee[lpFeeAddress] = true;
        _isExcludedFromFee[address(this)] = true;
        startTime = block.timestamp;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
        
    receive() external payable {}

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function excludeFromFees(address[] memory accounts) public onlyOwner{
        uint len = accounts.length;
        for( uint i = 0; i < len; i++ ){
            _isExcludedFromFee[accounts[i]] = true;
        }
    }

    function setStartTime(uint _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function getTheDay() public view returns (uint) {
        return (block.timestamp - startTime)/1 days;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setAmmPair(address pair,bool hasPair) external onlyOwner{
        require(pair != address(0), "Amm pair must be a address");
        ammPairs[pair] = hasPair;
    }

    function setRobotAddress(address _addr, bool _flag) external onlyOwner{
        _antiRobot[_addr] = _flag;
    }
    
    function setlpFeeAddress(address account) public onlyOwner{
        require(account != lpFeeAddress, "Lp fee address must be a new address");
        _isExcludedFromFee[account] = true;
        lpFeeAddress = account;
    }

    function setLpAddAddress(address account) public onlyOwner{
        require(account != lpAddAddress, "Invalid LP Add Address");
        _isExcludedFromFee[account] = true;
        lpAddAddress = account;
    }

    function setMiddlePoolAddress(address account) external onlyOwner{
        require(account != middlePoolAddress, "Invalid middlePoolAddress dividend address");
        _isExcludedFromFee[account] = true;
        middlePoolAddress = account;
    }

    function setCommunityFeeAddress(address account) public onlyOwner{
        require(account != communityFeeAddress, "Invalid Community dividend address");
        _isExcludedFromFee[account] = true;
        communityFeeAddress = account;
    }

    function setMarketFeeAddress(address account) external onlyOwner{
        _isExcludedFromFee[account] = true;
        marketFeeAddress = account;
    }

    function setReflowFeeAddress(address account) external onlyOwner{
        _isExcludedFromFee[account] = true;
        reflowFeeAddress = account;
    }

    function setMaxTxAmount(uint256 _amount) external onlyOwner{
        _maxTxAmount = _amount;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        require(_isExcludedFromFee[msg.sender], "Not allowed");
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
 
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    struct Param{
        bool takeFee;
        uint256 tTransferAmount;
        uint256 tLpFee;
        uint256 tBurnFee;
        uint256 tReflowFee;
        uint256 tCommunityFee;
    }

    function _transfer(address from,address to,uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_antiRobot[from], "Robot address can't exchange");
        
        // uint256 contractTokenBalance = balanceOf(address(this));
        // if( contractTokenBalance >= _maxTxAmount
        //     && !inSwapAndLiquify 
        //     && !ammPairs[from] 
        //     && !ammPairs[to]
        //     && IERC20(uniswapV2Pair).totalSupply() > 10 * 10**18 ){
        //     _swapTokensForUsdt(contractTokenBalance, address(this));
        // }

        // _shareBonus();

        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || from ==  address(uniswapV2Router)){
            takeFee = false;
        }

        Param memory param;
        if( takeFee ){
            param.takeFee = true;
            _getParam(amount, param);   //sell buy transfer
        } else {
            param.takeFee = false;
            param.tTransferAmount = amount; //no fee
        }
        _tokenTransfer(from, to, amount, param);
    }

    function _getParam(uint256 tAmount,Param memory param) private view  {
        param.tReflowFee = tAmount.mul(_reflowFee).div(_commonDiv);
        param.tCommunityFee = tAmount.mul(_communityFee).div(_commonDiv);
        param.tLpFee = tAmount.mul(_lpFee).div(_commonDiv);
        param.tBurnFee = tAmount.mul(_burnFee).div(_commonDiv);
        uint256 tFee = tAmount.mul(totalFee).div(_commonDiv);
        param.tTransferAmount = tAmount.sub(tFee);
    }

    function _take(uint256 tValue,address from,address to) private {
        _balances[to] = _balances[to].add(tValue);
        emit Transfer(from, to, tValue);
    }

    // function _shareBonus() private {
    //     uint256 _totalUsdtBal = IERC20(usdtAddress).balanceOf(address(this));
    //     if(_totalUsdtBal >= 10*10**18){
    //         uint256 _lpFeeBonus = _totalUsdtBal.mul(_lpFee).div(totalFee);
    //         uint256 _reflowBonus = _totalUsdtBal.mul(_reflowFee).div(totalFee);
    //         uint256 _burnBonus = _totalUsdtBal.mul(_burnFee).div(totalFee);
    //         uint256 _communityFeeBonus = _totalUsdtBal.mul(_communityFee).div(totalFee);
    //         IERC20(usdtAddress).transfer(communityFeeAddress, _communityFeeBonus);
    //         IERC20(usdtAddress).transfer(reflowFeeAddress, _reflowBonus);
    //         IERC20(usdtAddress).transfer(marketFeeAddress, _burnBonus);

    //         lpBonus[getTheDay()] = lpBonus[getTheDay()].add(_lpFeeBonus);
    //         IERC20(usdtAddress).transfer(lpFeeAddress, _lpFeeBonus);
    //     }
    // }

    function _takeFee(Param memory param, address from) private {
        uint256 _totalFee;
        if( param.tLpFee > 0 ){
            // Record today's bonus total amount
            _totalFee = _totalFee.add(param.tLpFee);
        }
        if( param.tCommunityFee > 0 ){
            _totalFee = _totalFee.add(param.tCommunityFee);
        }
        if( param.tReflowFee > 0 ){
            _totalFee = _totalFee.add(param.tReflowFee);
        }
        if( param.tBurnFee > 0 ){
            _totalFee = _totalFee.add(param.tBurnFee);
        }
        _take(_totalFee, from, middlePoolAddress);
    }

    event ParamEvent(
        address indexed sender, 
        address indexed to, 
        uint256 tLpFee, 
        uint256 tCommunityFee, 
        uint256 tReflowFee,
        uint256 tBurnFee,
        uint256 tTransferAmount);
 
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, Param memory param) private {
        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(param.tTransferAmount);
         emit Transfer(sender, recipient, param.tTransferAmount);

        if( param.takeFee ){
            emit ParamEvent(sender, recipient, param.tLpFee, 
            param.tCommunityFee, 
            param.tReflowFee,
            param.tBurnFee,
            param.tTransferAmount);
            _takeFee(param, sender);
        }
    }

    event SwapAndLiquidity(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokens);
    event SwapAndLiquidityUsdt(uint256 tokensSwapped, uint256 usdtReceived, uint256 tokens);
    
    function _swapAndLiquidity(uint256 contractTokenBalance) private lockTheSwap{
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        if( isLiquidityInBnb ){
            uint256 initialBalance = address(this).balance;
            _swapTokensForEth(half, address(this)); 
            uint256 newBalance = address(this).balance.sub(initialBalance);
            _addLiquidity(otherHalf, newBalance, lpAddAddress);
            emit SwapAndLiquidity(half, newBalance, otherHalf);
        } else {
            uint256 initialBalance = IERC20(usdtAddress).balanceOf(address(this));
            _swapTokensForUsdt(half, address(this));
            uint256 newBalance = IERC20(usdtAddress).balanceOf(address(this)).sub(initialBalance);
            _addLiquidityUsdt(otherHalf, newBalance, lpAddAddress);
            emit SwapAndLiquidityUsdt(half, newBalance, otherHalf);
        }
    }

    function _swapTokensForUsdt(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdtAddress;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            to,
            block.timestamp + 300
        );
    }
 
    function _swapTokensForEth(uint256 tokenAmount,address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            to,
            block.timestamp + 300
        );
    }
 
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount, address to) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            to,
            block.timestamp + 300
        );
    }

    function _addLiquidityUsdt(uint256 tokenAmount, uint256 usdtAmount, address to) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        TransferHelper.safeApprove(usdtAddress, address(uniswapV2Router), usdtAmount);
        uniswapV2Router.addLiquidity(
            address(this),
            usdtAddress,
            tokenAmount,
            usdtAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            to,
            block.timestamp + 300
        );
    }

    function setIsLiquidityInBnb(bool _value) external onlyOperator {
        require(isLiquidityInBnb != _value, "Not changed");
        isLiquidityInBnb = _value;
    }

    function clearStuckBalance(address _receiver) external onlyOperator {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
    }

    function rescueToken(address _token, uint256 _value) external onlyOperator{
        TransferHelper.safeTransfer(_token, msg.sender, _value);
    }
}