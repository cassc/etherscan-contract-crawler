// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../basex/interfaces/IPancakePair.sol";
import "../basex/interfaces/IPancakeFactory.sol";
import "../basex/interfaces/IPancakeRouter.sol";


contract Distributor is Ownable {
    function transferUSDT(
        IERC20 usdt,
        address to,
        uint256 amount
    ) external onlyOwner {
        usdt.transfer(to, amount);
    }
}


contract LuckyPlanet is  Context, IERC20, IERC20Metadata, Ownable {
    ///////////////////////////////////////////////////////////
    ////// @openzeppelin/contracts/token/ERC20/ERC20.sol //////
    ///////////////////////////////////////////////////////////

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override(IERC20) returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    ///////////////////////////////////////////////////////////
    ////////////////////////// main ///////////////////////////
    ///////////////////////////////////////////////////////////

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;


    bool private _paused;
    mapping(address => bool) public operators;

    IERC20 public USDT;
    IPancakeRouter public router;
    IPancakePair public pair;
    uint256 public burnAmount;
    EnumerableSet.AddressSet private chibiSet;
    uint256 public dividendTokensAtAmount =  500 * 10000 * (10**18);  //




    mapping(address => bool) public isDividendExempt;

    uint256 public minPeriod = 15 seconds;
    uint256 public minDistribution = 0.01 ether; // bnb
    uint256 public lastDividendTime;
    address private fromAddress;
    address private toAddress;

    uint256 public currentIndex;
    uint256 public constant distributorGas = 100 * 10000;


    
    mapping (address => bool) public automatedMarketMakerPairs;  //
    uint256 public numTokenToSwap = 20 * 10000 * 1e18; // 
    bool inSwapAndLiquify;
    Distributor public distributor;


    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _paused = false;
        operators[msg.sender] = true;
        
        _name = "Lucky Planet";
        _symbol = "LP";

        uint chainId; 
        assembly { chainId := chainid() }

        if (chainId == 56) {
            //_mint(0x0000000000000000000, 100 * 10000 * 10000 * 10**18);
            _mint(msg.sender, 100 * 10000 * 10000 * 10**18);

        } else {
            _mint(msg.sender, 100 * 10000 * 10000 * 10**18);

            minPeriod = 3 seconds;
            minDistribution = 0.00001 ether; // bnb
            dividendTokensAtAmount = 200 ether;
        }


        isDividendExempt[address(this)] = true;
        isDividendExempt[address(0)] = true;
        isDividendExempt[address(msg.sender)] = true;
        isDividendExempt[0x000000000000000000000000000000000000dEaD] = true;

        distributor = new Distributor();
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    function initData() public onlyOwner {
        //setRouter
    }

    function setPaused(bool paused_) public onlyOwner {
        _paused = paused_;
    }

    function setisDividendExempt(address account, bool excluded) public onlyOperator {
        isDividendExempt[account] = excluded;
    }
    function setisDividendExempts(address[] memory account, bool excluded) public onlyOperator {
        for (uint256 index = 0; index < account.length; index++) {
            isDividendExempt[account[index]] = excluded;
        }
    }

    function setDividendTokensAtAmount(uint256 _dividendTokensAtAmount) external onlyOwner{
        dividendTokensAtAmount = _dividendTokensAtAmount;
    }


    function setDistributionCriteria( uint256 _minPeriod, uint256 _minDistribution, uint256 _numTokenToSwap) public onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        numTokenToSwap = _numTokenToSwap;
    }

    

    function setOperator(address _operator, bool _enabled) public onlyOwner {
        operators[_operator] = _enabled;
    }


    function setNameAndSymbol(string memory name_, string memory symbol_) public onlyOwner {
        _name = name_;
        _symbol = symbol_;
    }

    function setRouter(IERC20 _USDT, IPancakeRouter _router) public onlyOwner {
        USDT = _USDT;
        router = _router;
        address _pair = IPancakeFactory(_router.factory()).createPair(address(_USDT), address(this));
        pair = IPancakePair(_pair);

        automatedMarketMakerPairs[_pair] = true;

        _approve(address(this), address(router), type(uint256).max);
    }

    function selfApprove(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) public onlyOwner {
        _token.approve(_spender, _amount);
    }

    function _isLp(address _addr) internal view returns (bool) {
        return automatedMarketMakerPairs[_addr];
    }

    function _isLiquidity()internal view returns(uint){

        address token0 = IPancakePair(address(pair)).token0();
        address token1 = IPancakePair(address(pair)).token1();
        (uint r0,uint r1,) = IPancakePair(address(pair)).getReserves();
        uint bal1 = IERC20(token1).balanceOf(address(pair));
        uint bal0 = IERC20(token0).balanceOf(address(pair));
        if( token0 == address(this) ){
            if( bal1 > r1){
                if ((bal1 - r1) > 1000) {
                    return 3;               //
                }
            }else if ( r1 > bal1){
                if ((r1 - bal1) > 1000) {
                    return 4;               //
                }
            }
        }else{
            if( bal0 > r0){
                if ((bal0 - r0) > 1000) {
                    return 3;               //
                }
            }else if ( r0 > bal0){
                if ((r0 - bal0) > 1000) {
                    return 4;               //
                }
            }
        }

        return 0;
    }

    // 0: normal transfer

    // 1: buy from official LP
    // 4: remove official LP

    // 2: sell to official LP
    // 3: add official LP
    function _getTransferType(address _from, address _to) internal view returns (uint256) {

        if (_isLp(_from) && !_isLp(_to)) {
            if (_isLiquidity() == 4){
                return 4;
            }else{
                return 1;
            }
        }

        if (!_isLp(_from) && _isLp(_to)) {
            if (_isLiquidity() == 3){
                return 3;
            }else{
                return 2;
            }
        }

        return 0;

    }

    function _rawTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual {
        if (_amount == 0) {
            return;
        }


        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(_from, _to, _amount);

        uint256 senderBalance = _balances[_from];
        require(senderBalance >= _amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[_from] = senderBalance - _amount;
        }
        _balances[_to] += _amount;

        emit Transfer(_from, _to, _amount);

        _afterTokenTransfer(_from, _to, _amount);
    }

    function shouldSwapToDiv(address ,uint256 _transferType) internal view returns (bool) {
        uint256 contractTokenBalance = balanceOf(address(this));
        bool isOverMinTokenBalance = contractTokenBalance >= numTokenToSwap;
        if (
            isOverMinTokenBalance &&
            !inSwapAndLiquify &&
            _transferType == 2
        ) {
            return true;
        } else {
            return false;
        }
    }
    
    function swapAndToDividend() internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(USDT);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            balanceOf(address(this)),
            0,
            path,
            address(distributor),
            block.timestamp
        );

        uint256 theSwapAmount = IERC20(USDT).balanceOf(address(distributor));
        try
            distributor.transferUSDT(IERC20(USDT), address(this), theSwapAmount)
        {} catch {}

    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if(_amount == 0) {
            _rawTransfer(_from, _to, 0);
            setShareAndProcess(_from,_to,true);
            return;
        }
        if (inSwapAndLiquify) {
            _rawTransfer(_from, _to, _amount);
            setShareAndProcess(_from,_to,true);
            return;
        }

        // 0: normal transfer
        // 1: buy from official LP
        // 4: remove official LP
        // 2: sell to official LP
        // 3: add official LP
        uint256 _transferType = _getTransferType(_from, _to);
        if (_transferType == 0){
            _rawTransfer(_from, _to, _amount);
            setShareAndProcess(_from,_to,true);
            return;
        }

        if ( _from == address(this) ||  _to == address(this) 
            ||  _from == address(router) ||  _to == address(router) ) {
            _rawTransfer(_from, _to, _amount);
            setShareAndProcess(_from,_to,true);
            return;
        }

        bool isSwap = shouldSwapToDiv(_from,_transferType);
        if (isSwap) {
            swapAndToDividend();
        }


        if (_transferType == 1){ // 1: buy 
            uint256 _amountDividend = _amount.mul(4).div(100);
            uint256 _amountBurn = _amount.mul(2).div(100);

            _rawTransfer(_from, address(this),    _amountDividend);
            if (burnAmount >= 10000 * 10000 * 10**18){
                _rawTransfer(_from, address(pair),  _amountBurn);
            }else{
                _rawTransfer(_from, 0x000000000000000000000000000000000000dEaD,  _amountBurn);
                burnAmount += _amountBurn;
            }

            _amount =  _amount.sub(_amountDividend + _amountBurn);
        }
        
        if (_transferType == 2){  // sell 
            uint256 _amountToPair = _amount.mul(6).div(100);
            _rawTransfer(_from, address(pair),  _amountToPair);

            _amount =  _amount.sub(_amountToPair);
        }

        _rawTransfer(_from, _to, _amount);

        setShareAndProcess(_from,_to,isSwap);
    }

    function setShareAndProcess(address _from,address _to,bool isSwap) private {

        if (fromAddress == address(0)) fromAddress = _from;
        if (toAddress == address(0)) toAddress = _to;

        setShareChibi(fromAddress);
        setShareChibi(toAddress);
        fromAddress = _from;
        toAddress = _to;

        if (isSwap){
            return;
        }
        

        if (
            IERC20(USDT).balanceOf(address(this)) >= minDistribution &&
            _from != address(this) &&
            lastDividendTime + minPeriod <= block.timestamp
        ) {
            process(distributorGas);
            lastDividendTime = block.timestamp;
        }

    }

    function process(uint256 gas) private {
        address theHolder;

        uint256 chibiSetLen = chibiSet.length();
        if (chibiSetLen == 0) return;

        uint256 nowbalanceUsdt = IERC20(USDT).balanceOf(address(this));
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 allchibi = 0;

        for (uint256 i = 0; i < chibiSetLen; i++) {
            allchibi += balanceOf(chibiSet.at(i));
        }


        while (gasUsed < gas && iterations < chibiSetLen) {
            if (currentIndex >= chibiSetLen) {
                currentIndex = 0;
            }

            theHolder = chibiSet.at(iterations);
            uint256 percent = balanceOf(theHolder) * 1e10 / allchibi;
            uint256 amountUsdt = nowbalanceUsdt * percent / 1e10;
            if(amountUsdt > 0) { IERC20(USDT).transfer(theHolder, amountUsdt); }

            unchecked {
                gasUsed += gasLeft - gasleft();
                gasLeft = gasleft();
                currentIndex++;
                iterations++;
            }
        }
    }

    function setShareChibi( address user) internal {
        if(isDividendExempt[user]) {
            chibiSet.remove(user);
            return;
        }

        if(_isContract(user)){
            return;
        }

        if (balanceOf(user) >= dividendTokensAtAmount){
            chibiSet.add(user);
        }else{
            chibiSet.remove(user);
        }
    }


    function dividendsUserLists() public view returns (address[] memory) {
        uint256 chibiSetLen = chibiSet.length();
        address[] memory rets = new address[](chibiSetLen);

        for (uint256 i = 0; i < chibiSetLen; i++) {
            rets[i] = chibiSet.at(i);
        }
        return rets;
    }

    function dividendsUserNums() public view returns (uint256) {
        return chibiSet.length();
    }



    fallback() external payable {

    }
    receive() external payable {

  	}
    //--------------------------------------------------------------------------------

    // 1e18 units main token = how many units quote token
    function getPrice() public view returns (uint256) {
        address _token0 = pair.token0();
        (uint256 _reserve0, uint256 _reserve1, ) = pair.getReserves();
        (uint256 _main, uint256 _quote) = address(USDT) == _token0
            ? (_reserve1, _reserve0)
            : (_reserve0, _reserve1);
        return _main == 0 ? 0 : _quote.mul(1e18).div(_main);
    }

    // 1e18 units LP token value = how many units quote token
    function getLpPrice() public view  returns (uint256) {
        uint256 _total = pair.totalSupply();
        address _token0 = pair.token0();
        (uint256 _reserve0, uint256 _reserve1, ) = pair.getReserves();
        uint256 _quote = address(USDT) == _token0 ? _reserve0 : _reserve1;
        return _total == 0 ? 0 : _quote.mul(2).mul(1e18).div(_total);
    }

    function getLpAddress() public view  returns (address) {
        return address(pair);
    }

    function rescuescoin(
        address _token,
        address payable _to,
        uint256 _amount
    ) public onlyOwner {
        if (_token == address(0)) {
            (bool success, ) = _to.call{ gas: 23000, value: _amount }("");
            require(success, "transferETH failed");
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

}