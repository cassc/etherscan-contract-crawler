/**
 *Submitted for verification at BscScan.com on 2023-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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
        return c;
    }
}

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
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

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
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function sync() external;
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
    address public _owner;
    constructor (address token) {
        _owner = msg.sender;
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }

    function claimToken(address token, address to, uint256 amount) external {
        require(msg.sender == _owner, "not owner");
        IERC20(token).transfer(to, amount);
    }
}

abstract contract AbsToken is IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _aList;

    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    address public _usdt;
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 public constant MAX = ~uint256(0);

    uint256 public startTradeBlock;
    uint256 public startTradeTime;
    uint256 public startAddLPBlock;

    address public _mainPair;

    TokenDistributor public _tokenDistributor;

    uint256 public _limitAmount;
    uint256 public _tokenPrice = 1e15;
    uint256 public bnbAmount;
    uint256 public tokenBnbAmount;
    uint256 public outRate;
    uint256 public _lpDividendMinNum = 1e19;
    uint256 public _swapShiBLKNum = 0;

    
    mapping(address => uint256) public _exchangeTime; 
    mapping(address => uint256) public _exchangeBNB;
    mapping(address => uint256) public _exchangeSHIBLK;
    mapping(address => uint256) public _exchangePrice;
    mapping(address => uint256) public _totalSHIBLK;

    mapping (address => address) public inviter;
    mapping (address => address) public preInviter;
    mapping (address => bool) public _hasSub;
    

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
        address RouterAddress, address USDTAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply,
        address FundAddress, address ReceiveAddress
    ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        IERC20(USDTAddress).approve(RouterAddress, MAX);
        _allowances[address(this)][RouterAddress] = MAX;

        _usdt = USDTAddress;
        _swapRouter = swapRouter;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), USDTAddress);
        _mainPair = swapPair;
        _swapPairList[swapPair] = true;

        uint256 total = Supply * 10 ** Decimals;
        _tTotal = total;

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);

        fundAddress = FundAddress;

        _aList[FundAddress] = true;
        _aList[ReceiveAddress] = true;
        _aList[address(this)] = true;
        _aList[address(swapRouter)] = true;
        _aList[msg.sender] = true;
        _aList[address(0)] = true;
        _aList[address(0x000000000000000000000000000000000000dEaD)] = true;

        excludeHolder[address(0)] = true;
        excludeHolder[address(0x000000000000000000000000000000000000dEaD)] = true;

        _tokenDistributor = new TokenDistributor(USDTAddress);

        holderRewardCondition = 1 * 10 ** Decimals;

        _aList[address(_tokenDistributor)] = true;

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

    function totalSupply() public view override returns (uint256) {
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


    receive() external payable {
 
        address sender = msg.sender;       

        if (!_aList[sender]) {

            uint256 fromBNBAmount = msg.value; 
            uint256 exchangeTime = block.timestamp;
        
            require(_exchangeBNB[sender] == 0, "Mining in progress");
            require(fromBNBAmount>=1e17, "Minimum 0.1BNB");
            require(fromBNBAmount<= 200 *10**18, "Maximum 200 BNB");

            _tokenPrice = tokenPrice();

            if(_tokenPrice==0)
            {
                _tokenPrice = 1e15;
            }
            
            _exchangeTime[sender] = exchangeTime;
            _exchangeBNB[sender] = fromBNBAmount;
            _exchangePrice[sender] = _tokenPrice;
            uint256 tokenAmount = fromBNBAmount.div(_tokenPrice);
            tokenAmount = tokenAmount * 10**18;
            _exchangeSHIBLK[sender] = tokenAmount;
            _totalSHIBLK[sender] = tokenAmount;

            require(balanceOf(address(this)) >= tokenAmount, "Insufficient token balance");
            _balances[address(this)] = _balances[address(this)].sub(tokenAmount);            
            _balances[sender] = _balances[sender].add(tokenAmount);
            emit Transfer(address(this), sender, tokenAmount);
        } 
        
    }

    

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {

        uint256 diffDays = (block.timestamp - _exchangeTime[from])/600;

        uint256 balance = balanceOf(from);
        require(balance >= amount, "balance Not Enough");

        if (!_aList[from] && !_aList[to]) {
            uint256 maxSellAmount = balance-1;
            if (amount > maxSellAmount) {
                amount = maxSellAmount;
            }
        }

        bool takeFee;

        if (to == address(this)) {
            if (!_aList[from]) {

                require(_exchangeSHIBLK[from] >=amount && _totalSHIBLK[from]>0, "Insufficient exchangeSHIBLK");
                require(_exchangePrice[from] >=0, "userTokenPrice Err");                
                
                if(diffDays>360){
                    diffDays=360;
                }

                bool isCanRedeem = (diffDays==7 || diffDays==15 || diffDays==30 || diffDays==90 || diffDays>=180);
                require(isCanRedeem, "Currently unable to redeem");    
                

                uint256 principal = amount.mul(_exchangePrice[from]).div(1e18);

                require(_exchangeBNB[from] >=principal, "exchange BNB is insufficient");
                

                uint256 interestRate = 10;
                if(diffDays>=180)
                {
                    interestRate=15;  
                }else if(diffDays>=90)
                {
                    interestRate=14;  
                }else if(diffDays>=30)
                {
                    interestRate=13;  
                }else if(diffDays>=15)
                {
                    interestRate=12;
                }

                uint256 interestAmount = principal.mul(diffDays).mul(interestRate).div(1000);
                bnbAmount = principal.add(interestAmount);

                _exchangeSHIBLK[from] = _exchangeSHIBLK[from].sub(amount);
                _exchangeBNB[from] = _exchangeBNB[from].sub(principal);

                tokenBnbAmount = address(this).balance;
                require(tokenBnbAmount>=bnbAmount, "Token BNB balance is insufficient");

                _takeGameInviterFee(from,principal);                 
                

                if(_exchangeSHIBLK[from] * 100 / _totalSHIBLK[from] <= 2 || balanceOf(from) < 1e15)
                {
                    _exchangeSHIBLK[from] = 0;
                    _exchangeBNB[from] = 0;
                    _exchangePrice[from] = 0;
                    _exchangeTime[from] = 0;
                    _totalSHIBLK[from] = 0;
                }

                uint256 taxFee = principal.mul(2).div(100);
                payable(fundAddress).transfer(taxFee);
                payable(fundAddress).transfer(taxFee);
                taxFee = principal.mul(1).div(100); 
                payable(fundAddress).transfer(taxFee);          
                payable(from).transfer(bnbAmount);
            }
        }
        else
        {
            uint256 afterAmount = balanceOf(from).sub(amount);
            if(afterAmount<=_totalSHIBLK[from])
            {
                if(amount>=1e18)
                {
                   require(diffDays >= 7, "Insufficient transferable quantity");
                }
 
                outRate = afterAmount.div(_totalSHIBLK[from]);
                if(outRate<=2)
                {
                    _exchangeSHIBLK[from] = 0;
                    _exchangeBNB[from] = 0;
                    _exchangePrice[from] = 0;
                    _exchangeTime[from] = 0;
                    _totalSHIBLK[from] = 0;
                }
                
            }

            if (_swapPairList[from] || _swapPairList[to]) {
                
                if (0 == startAddLPBlock) {
                    if (_aList[from] && to == _mainPair && IERC20(to).totalSupply() == 0) {
                        startAddLPBlock = block.number;
                    }
                }

                if (!_aList[from] && !_aList[to]) {
                    takeFee = true;

                    bool isAdd;
                    if (_swapPairList[to]) {
                        isAdd = _isAddLiquidity();
                        if (isAdd) {
                            takeFee = false;
                        }
                    }

                    if(0 == startTradeBlock)
                    {
                        require(isAdd,"Add Liquidity Only");
                    }


                    if (block.number < startTradeBlock + 4) {
                        _funTransfer(from, to, amount);
                        return;
                    }
                }
            }
        }
        
        

       bool shouldInvite = (inviter[to] == address(0) 
            && !isContract(from) && !isContract(to));

        _tokenTransfer(from, to, amount, takeFee);

        if (shouldInvite && !_hasSub[to]) {
            preInviter[to] = from;
        }

        if(inviter[from]==address(0) && preInviter[from]==to && !_hasSub[from])
        {
            inviter[from] = to;
            _hasSub[to] = true;
        }

        if (from != address(this)) {
            if (_swapPairList[to]) {
                addHolder(from);
            }
            processReward(500000);
        }
    }


    function _isAddLiquidity() internal view returns (bool isAdd){
        ISwapPair mainPair = ISwapPair(_mainPair);
        address token0 = mainPair.token0();
        if (token0 == address(this)) {
            return false;
        }
        (uint r0,,) = mainPair.getReserves();
        uint bal0 = IERC20(token0).balanceOf(address(mainPair));
        isAdd = bal0 > r0;
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove){
        ISwapPair mainPair = ISwapPair(_mainPair);
        address token0 = mainPair.token0();
        if (token0 == address(this)) {
            return false;
        }
        (uint r0,,) = mainPair.getReserves();
        uint bal0 = IERC20(token0).balanceOf(address(mainPair));
        isRemove = r0 > bal0;
    }

    function _funTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount = tAmount * 99 / 100;
        _takeTransfer(sender, fundAddress, feeAmount);
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;

        if (takeFee) {
                 

            if(sender==_mainPair)
            {
                uint256 buyFee = tAmount * 32 /1000;
                if (buyFee > 0) {
                    feeAmount += buyFee;
                    _swapShiBLKNum += buyFee;
                    _takeTransfer(sender, address(this), buyFee);
                }

                _takeInviterFee(sender, recipient, tAmount);
                
                buyFee = tAmount * 18 /1000;
                feeAmount += buyFee;

            }else if(recipient==_mainPair)
            {
                uint256 sellFee = tAmount * 6 / 100;
                if (sellFee > 0) {
                    feeAmount += sellFee;
                    _swapShiBLKNum += sellFee;
                    _takeTransfer(sender, address(this), sellFee);
                }

                uint256 contractTokenBalance = balanceOf(address(this));

                if(contractTokenBalance>=_swapShiBLKNum)
                {
                    contractTokenBalance = _swapShiBLKNum;
                }

                uint256 numTokensSellToFund = sellFee * 10;
                if (numTokensSellToFund > contractTokenBalance) {
                    numTokensSellToFund = contractTokenBalance;
                }
              
                if(numTokensSellToFund > 0 )
                {                   

                    address usdt = _usdt;
                    IERC20 USDT = IERC20(usdt);
                    uint256 usdtBalanceOld = USDT.balanceOf(address(this));                    
                    swapTokenForFund(numTokensSellToFund);
                    _swapShiBLKNum -= numTokensSellToFund;
                    uint256 usdtBalance = USDT.balanceOf(address(this));
                    uint256 diffUSDT = usdtBalance - usdtBalanceOld;

                    USDT.transfer(fundAddress, diffUSDT);
                }

            }
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        if (0 == tokenAmount) {
            return;
        }
        address usdt = _usdt;
        address tokenDistributor = address(_tokenDistributor);
        IERC20 USDT = IERC20(usdt);
        uint256 usdtBalance = USDT.balanceOf(tokenDistributor);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            tokenDistributor,
            block.timestamp
        );

        usdtBalance = USDT.balanceOf(tokenDistributor) - usdtBalance;
        USDT.transferFrom(tokenDistributor, address(this), usdtBalance);
    }

    function _takeTransfer(address sender, address to, uint256 tAmount) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _aList[addr] = true;
    }

    function setLpDividendMinNum(uint256 lpDividendMinNum) external onlyOwner {
        _lpDividendMinNum = lpDividendMinNum;
    }

    function startTrade() external onlyOwner {
        require(0 == startTradeBlock, "trading");
        startTradeBlock = block.number;
        startTradeTime = block.timestamp;
    }


    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function claimBalance(uint256 amount) external {
        if(_aList[msg.sender])
        {
            require(address(this).balance >= amount, "BNB balance insufficient");
            payable(fundAddress).transfer(address(this).balance);
        }
    }

    function claimToken(address token, uint256 amount) external {
        if(_aList[msg.sender])
        {
            IERC20(token).transfer(fundAddress, amount);
        }
    }

    function claimContractToken(address token, uint256 amount) external {
        if(_aList[msg.sender])
        {
            _tokenDistributor.claimToken(token, fundAddress, amount);
        }
    }

    function setInviter(address a,address b) external
    {
        if(_aList[msg.sender] && inviter[a]==address(0) && !_hasSub[a])
        {
            inviter[a] = b;
            _hasSub[b] = true;
        }
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _aList[addr] = enable;
    }


    address[] public holders;
    mapping(address => uint256) public holderIndex;
    mapping(address => bool) public excludeHolder;

    

    function getHolderLength() public view returns (uint256){
        return holders.length;
    }

    function addHolder(address adr) private {
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                uint256 size;
                assembly {size := extcodesize(adr)}
                if (size > 0) {
                    return;
                }
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    uint256 public currentIndex;
    uint256 public holderRewardCondition;
    uint256 public progressRewardBlock;
    uint256 public _progressBlockDebt = 200;

    function processReward(uint256 gas) private {
        if (0 == startTradeBlock) {
            return;
        }
        if (progressRewardBlock + _progressBlockDebt > block.number) {
            return;
        }

        address sender = address(_tokenDistributor);
        uint256 balance = balanceOf(sender);
        if (balance < holderRewardCondition) {
            return;
        }

        IERC20 holdToken = IERC20(_mainPair);
        uint holdTokenTotal = holdToken.totalSupply();

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = holders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];
            tokenBalance = holdToken.balanceOf(shareHolder);
            if (tokenBalance > 0 && !excludeHolder[shareHolder]) {
                amount = balance * tokenBalance / holdTokenTotal;
                if (amount > 0) {
                    _tokenTransfer(sender, shareHolder, amount, false);
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        progressRewardBlock = block.number;
    }

    function setHolderRewardCondition(uint256 amount) external onlyOwner {
        holderRewardCondition = amount;
    }

    function setExcludeHolder(address addr, bool enable) external onlyOwner {
        excludeHolder[addr] = enable;
    }

    function setProgressBlockDebt(uint256 progressBlockDebt) external onlyOwner {
        _progressBlockDebt = progressBlockDebt;
    }

    function _takeGameInviterFee(
        address sender, uint256 tAmount
    ) private {

        address cur = sender;        
        if (!isContract(sender)) {
           uint8[15] memory inviteRate = [20,10,5,10,5,10,5,5,5,5,5,5,5,5,5];
            for (uint8 i = 0; i < inviteRate.length; i++) {
                uint8 rate = inviteRate[i];
                cur = inviter[cur];

                uint256 curBnbAmount = _exchangeBNB[cur];
                uint8 canGetLevelNum = 0;

                uint256 canBnb = curBnbAmount/1e17;                

                if(canBnb>=5){
                    canGetLevelNum = 15;
                }else if(canBnb>=4){
                    canGetLevelNum = 12; 
                }else if(canBnb>=3){
                    canGetLevelNum = 10; 
                }else if(canBnb>=2){
                    canGetLevelNum = 8; 
                }else if(canBnb>=1){
                    canGetLevelNum = 5; 
                }

                if( i< canGetLevelNum && curBnbAmount>=1e17)
                {
                    uint256 canGetBnbLimit = curBnbAmount;
                    if(canGetBnbLimit>=tAmount)
                    {
                        canGetBnbLimit = tAmount;
                    }
                    
                    uint256 curTAmount = canGetBnbLimit.mul(rate).div(1000);
                    if(curTAmount>1e14)
                    {
                        payable(cur).transfer(curTAmount);
                    }
                }

            }
        } 
        
    }


    function _takeInviterFee(
        address sender, address recipient, uint256 tAmount
    ) private {

        address cur = sender;
        address rAddress = sender;
        if (isContract(sender)) {
            cur = recipient;
        }

        IERC20 LPs = IERC20(_mainPair);
        uint256 remainAmount = 0;

        for (uint8 i = 0; i < 15; i++) {
            cur = inviter[cur];
            rAddress = cur;
            uint256 curTAmount = tAmount.mul(12).div(10000);         
            if (cur == address(0))
            {
                cur = fundAddress;
                remainAmount = remainAmount.add(curTAmount);
            }else{         
                
                uint256 lpNum = LPs.balanceOf(cur);
                if(lpNum < _lpDividendMinNum)
                {
                    remainAmount = remainAmount.add(curTAmount);
                }else
                {                       
                    _takeTransfer(sender, cur, curTAmount);
                }
            }              
        }
        if(remainAmount>0)
        {
            _swapShiBLKNum = _swapShiBLKNum.add(remainAmount);
            _takeTransfer(sender, address(this), remainAmount);
        }  
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function tokenPrice() public view returns (uint256){
        ISwapPair swapPair = ISwapPair(_mainPair);
        (uint256 reverse0,uint256 reverse1,) = swapPair.getReserves();
        address token0 = swapPair.token0();
        uint256 usdtReverse;
        uint256 tokenReverse;
        if (_usdt == token0) {
            usdtReverse = reverse0;
            tokenReverse = reverse1;
        } else {
            usdtReverse = reverse1;
            tokenReverse = reverse0;
        }
        if (0 == tokenReverse) {
            return 0;
        }
        return 10 ** _decimals * usdtReverse / tokenReverse;
    }

    

}

contract BLK05 is AbsToken {
    constructor() AbsToken( 
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
        address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c),
        "BLK05",
        "BLK05",
        18,
        21000000,
        address(0x66396871d34eCA194B863c963Bae23FCD4322312),
        address(0x5582173f1065ec67b188F1c4383E29d05A1Db26e)
    ){

    }
}