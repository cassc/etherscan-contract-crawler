/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapRouter {
    function factory() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IDapp {
    function addLpAmount(uint112 usdtAmount) external;
}

library EnumerableSet {
   
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { 
            
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

    
            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            
            set._indexes[lastvalue] = toDeleteIndex + 1; 

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }


    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

   
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }


    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

   
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

   
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenDistributor {
    constructor (address token) {
        IERC20(token).approve(msg.sender, ~uint256(0));
    }
}

abstract contract BaseToken is IERC20, Ownable {
    event ProcessLP(uint totalLpCount,uint processLpCount);
    using EnumerableSet for EnumerableSet.AddressSet;

    uint8 private _decimals;  
    uint32 private _startTradeBlock;
    uint32 private _currentIndex;
    uint32 private _priceTime;
    uint32 private _gasLimit;
    uint256 private _waitForSwapAmount;
    uint256 private _waitForSwapCutAmount;
    uint256 private _limitAmount;
    uint256 private _minAmountLpHolder;
    uint256 private _addPriceTokenAmount; 
    uint256 private _lastPrice;
    uint256 private _totalSupply;
    uint256 private constant MAX = ~uint256(0);


    ISwapRouter private _swapRouter;
    TokenDistributor private _tokenDistributor;
    address private _dapp;
    address private _marketAddress;
    address private _usdtAddress;
    address private _usdtPairAddress;

    string private _name;
    string private _symbol;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _feeWhiteList;
    mapping(address => bool) public _swapPairMap;
    EnumerableSet.AddressSet _lpProviders;
    
    constructor (string memory Name, string memory Symbol, uint256 Supply, address RouterAddress, address UsdtAddress, address marketAddress){
        _name = Name;
        _symbol = Symbol;
        _decimals = 18;
        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        _usdtAddress = UsdtAddress;
        _swapRouter = swapRouter;
        _allowances[address(this)][RouterAddress] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        _usdtPairAddress = swapFactory.createPair(address(this), UsdtAddress);
        _swapPairMap[_usdtPairAddress] = true;

        uint256 total = Supply * 1e18;
        _totalSupply = total;

        
        _marketAddress = marketAddress;
        _dapp = msg.sender;

        _balances[msg.sender] = total; 
        emit Transfer(address(0), msg.sender, total);
        _feeWhiteList[msg.sender] = true;

        _feeWhiteList[marketAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0x000000000000000000000000000000000000dEaD)] = true;

        _limitAmount = 1e19;
        _addPriceTokenAmount = 1e14;
        _minAmountLpHolder = 1e16;
        _gasLimit = 3000000;
        _tokenDistributor = new TokenDistributor(UsdtAddress);
        _startTradeBlock = 0;
    }
    function getParam() external view returns(
        uint32  startTradeBlock,
        uint32  currentIndex,
        uint32  priceTime,
        uint32  gasLimit,
        uint256  waitForSwapAmount,
        uint256  waitForSwapCutAmount,
        uint256  limitAmount,
        uint256  minAmountLpHolder,
        uint256  addPriceTokenAmount,
        uint256  lastPrice,
        address dapp,
        address tokenDistributor){
            startTradeBlock = _startTradeBlock;
            currentIndex = _currentIndex;
            priceTime = _priceTime;
            gasLimit=_gasLimit;
            waitForSwapAmount=_waitForSwapAmount;
            waitForSwapCutAmount=_waitForSwapCutAmount;
            limitAmount=_limitAmount;
            minAmountLpHolder=_minAmountLpHolder;
            addPriceTokenAmount=_addPriceTokenAmount;
            lastPrice=_lastPrice;
            dapp=_dapp;
            tokenDistributor=address(_tokenDistributor);
    }

    function pairAddress() external view returns (address) {
        return _usdtPairAddress;
    }
    
    function routerAddress() external view returns (address) {
        return address(_swapRouter);
    }
    
    function usdtAddress() external view returns (address) {
        return _usdtAddress;
    }
    
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _isLiquidity(address from,address to) internal view returns(bool isAdd,bool isDel){        
        (uint r0,uint r1,) = IUniswapV2Pair(_usdtPairAddress).getReserves();
        uint rUsdt = r0;  
        uint bUsdt = IERC20(_usdtAddress).balanceOf(_usdtPairAddress);      
        if(address(this)<_usdtAddress){ 
            rUsdt = r1; 
        }
        if( _swapPairMap[to] ){ 
            if( bUsdt >= rUsdt ){
                isAdd = bUsdt - rUsdt >= _addPriceTokenAmount; 
            }
        }
        if( _swapPairMap[from] ){   
            isDel = bUsdt <= rUsdt;  
        }
    }

    function updateLastPrice() public {
        uint32 newTime = uint32(block.timestamp)/86400; 
        if(newTime > _priceTime){
            _lastPrice = getNowPrice();
            _priceTime = newTime;
        }
    }

    function getNowPrice() internal view returns(uint256){
        uint256 poolToken = _balances[_usdtPairAddress];
        if(poolToken > 0){
            return IERC20(_usdtAddress).balanceOf(_usdtPairAddress)*1e18/poolToken;
        }
        return 0;
    }

    function getDownRate() public view returns(uint256){ 
        if(_lastPrice > 0){
            uint256 nowPrice = getNowPrice();
            if(_lastPrice > nowPrice){
                return (_lastPrice - nowPrice)*100/_lastPrice;
            }
        }
        return 0;
    }

    function getCutRate() public view returns(uint256){
        uint256 downRate = getDownRate();
        if(downRate >= 50){
            return 40;
        }else if(downRate >= 30){
            return 20;
        }else{
            return 0;
        }
    }

    function getCurrentPrice() external view returns (uint256){
        return getNowPrice();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {       
        require(amount > 0, "KL: transfer amount must be >0");
        if(address(this)==from) {
            _tokenTransfer(from, to, amount); 
            return;
        }
        bool isAddLiquidity;
        bool isDelLiquidity;
        ( isAddLiquidity, isDelLiquidity) = _isLiquidity(from,to);
        
        if (_feeWhiteList[from] || _feeWhiteList[to] || isAddLiquidity || isDelLiquidity){            
            _tokenTransfer(from, to, amount);
        }else if(_swapPairMap[from] || _swapPairMap[to]){
            
            require(_startTradeBlock > 0, "KL: trade don't start");   
            updateLastPrice();    
            if (_swapPairMap[to]) { 
                
                require(amount <= (_balances[from])*99/100, "KL: sell amount exceeds balance 99%");  
                
                
                swapUSDT();

                uint256 cutRate = getCutRate();    
                if(cutRate > 0) {
                    _tokenTransfer(from, to, amount*(100-cutRate)/100); 
                    cutRate -= 6;
                    _tokenTransfer(from, address(this), amount*cutRate/100) ; 
                    _waitForSwapCutAmount += amount*cutRate/100;
                }else{
                    _tokenTransfer(from, to, amount*94/100); 
                }
                
            }else{  
                _tokenTransfer(from, to, amount*94/100); 
                 
            }   
            
            
            _tokenTransfer(from, address(this), amount*55/1000); 
            _tokenTransfer(from, address(0x000000000000000000000000000000000000dEaD), amount/200); 
            _waitForSwapAmount += amount*55/1000; 
            
             
        }else{
            
            swapUSDT() ;
            _tokenTransfer(from, to, amount/2);
            _tokenTransfer(from, address(0x000000000000000000000000000000000000dEaD), amount/2); 
        }
        if (isAddLiquidity) { 
            if(address(0)!=from && address(0x000000000000000000000000000000000000dEaD)!=from){
                _lpProviders.add(from);
            }
        }
        if(isDelLiquidity){
           _removeLpProvider(to);
        }
        _processLP(_gasLimit);
    }
    
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        _balances[recipient] = _balances[recipient] + tAmount;
        emit Transfer(sender, recipient, tAmount);
    }

    function swapUSDT() internal  {
        uint256 total = _waitForSwapAmount + _waitForSwapCutAmount;
        if(total < _limitAmount) return;
        address tokenDistributor = address(_tokenDistributor);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdtAddress;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            total,
            0,
            path,
            tokenDistributor,
            block.timestamp
        );        
        IERC20 USDT = IERC20(_usdtAddress);
        uint256 usdtBalance = USDT.balanceOf(tokenDistributor);
        uint256 cutAmount = usdtBalance * _waitForSwapCutAmount/total;
        uint256 rewardAmount = usdtBalance - cutAmount;
        _waitForSwapAmount = 0;
        _waitForSwapCutAmount = 0;
        USDT.transferFrom(tokenDistributor, _marketAddress, cutAmount + rewardAmount*15/55); 
        USDT.transferFrom(tokenDistributor, _dapp, rewardAmount*20/55); 
        USDT.transferFrom(tokenDistributor, address(this), rewardAmount*20/55); 
    }

    function getLps() external view returns(address [] memory){
        uint size = _lpProviders.length();
        address[] memory addrs = new address[](size);
        for(uint i=0;i<size;i++) addrs[i]= _lpProviders.at(i);
        return addrs;
    }

    function processLP(uint256 gas) external onlyOwner{
        _processLP(gas);
    }

    function _processLP(uint256 gas) internal {
        IERC20 mainpair = IERC20(_usdtPairAddress);
        uint totalPair = mainpair.totalSupply();
        if (0 == totalPair) {
            return;
        }

        IERC20 USDT = IERC20(_usdtAddress);
        uint256 usdtTokenBalance = USDT.balanceOf(address(this));
        if (usdtTokenBalance < _limitAmount) {
            return;
        }

        address lpHolder;
        uint256 pairBalance;
        uint256 amount;

        uint256 lpHolderCount = _lpProviders.length();

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        

        while (gasUsed < gas && iterations < lpHolderCount) {
            if (_currentIndex >= lpHolderCount) {
                _currentIndex = 0;
            }
            lpHolder = _lpProviders.at(_currentIndex);
            pairBalance = mainpair.balanceOf(lpHolder);
            if (pairBalance > 0) {
                amount = usdtTokenBalance * pairBalance / totalPair;
                if (amount > 0) {
                    USDT.transfer(lpHolder, amount);
                    if(lpHolder == _dapp){
                        IDapp(_dapp).addLpAmount(uint112(amount));
                    }
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            _currentIndex++;
            iterations++;
        }
        emit ProcessLP(lpHolderCount, iterations);
    }

    function _removeLpProvider(address addr) internal{
        if(IERC20(_usdtPairAddress).balanceOf(addr)<_minAmountLpHolder){
            _lpProviders.remove(addr);
        }
    }

    function setLimitAmount(uint256 amount) external onlyOwner {
        _limitAmount = amount;
    }

    function setGasLimit(uint32 limit) external onlyOwner {
        _gasLimit = limit;
    }

    function manulAddLpProvider(address[] calldata addrs) external returns(bool){
        require(msg.sender==owner()||msg.sender==_dapp,"caller should be owner or dapp adderss");
        for(uint i=0;i<addrs.length;i++) {        
            if(address(0)!=addrs[i] && address(0x000000000000000000000000000000000000dEaD)!=addrs[i]){
                _lpProviders.add(addrs[i]);
            }
        }
        
        return true;
    }

    function manulRemoveLpProvider(address addr) external onlyOwner{
         _lpProviders.remove(addr);
    }

    function setMarketAddress(address addr) external onlyOwner {
        _marketAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function getMarketAddress() external view returns(address) {
        return _marketAddress;
    }

    function setDappAddress(address addr) external onlyOwner {
        _dapp = addr;
        _feeWhiteList[addr] = true;
    }

    function startTrade() external onlyOwner {
        require(0 == _startTradeBlock, "trading");
        _startTradeBlock = uint32(block.number);
    }

    function closeTrade() external onlyOwner {
        _startTradeBlock = 0;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }    

    function setSwapPairMap(address addr, bool enable) external onlyOwner {
        _swapPairMap[addr] = enable;
    }

    function setAddPriceTokenAmount(uint256 addPriceTokenAmount) external onlyOwner{
        _addPriceTokenAmount = addPriceTokenAmount;
    }

    receive() external payable {}
}

contract Kunlun is BaseToken {
    constructor() BaseToken(
        "Kunlun coin",
        "KL",
        21000000,
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E), 
        address(0x55d398326f99059fF775485246999027B3197955), 
        address(0x1f4Beb50A6B3E539B6Db65B2c6558EA8982F2f1C) 
    ){

    }
}