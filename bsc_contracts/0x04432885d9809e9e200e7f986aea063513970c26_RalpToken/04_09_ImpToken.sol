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
    mapping(address => address) public inviter;

    address public fundAddress;
    address public marketingAddress = address(0x21b6eA91C9A2B345E636de440309D7e830Eb2944);
    address public _fist;
    address public _weth;
    address public _mainPair;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public ZERO = 0x0000000000000000000000000000000000000000;
    address public inviterDefault = address(0x65eeb5DA7072B902A1a3d7177e835A706a11638A);

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    TokenDistributor public _tokenDistributor;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public liquifyEnabled = false;

    uint256 public _buyFundFee = 100;
    uint256 public _sellFundFee = 100;
    uint256 public _buyMarketingFee = 100;
    uint256 public _sellMarketingFee = 100;
    uint256 public _buyInviterFee = 100;
    uint256 public _sellInviterFee = 100;
    uint256 public _buyFInviterFee = 100;
    uint256 public _sellFInviterFee = 100;
    uint256 public _buySInviterFee = 100;
    uint256 public _sellSInviterFee = 100;
    uint256 public _buyLPDividendFee = 100;
    uint256 public _sellLPDividendFee = 100;
    uint256 public _buyBurnFee = 100;
    uint256 public _sellBurnFee = 100;
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

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SetSwapPairList(address indexed addr, bool indexed enable);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (
        address RouterAddress, address WETHAddress, address FISTAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply, uint256 MinNum, uint256 Reward,
        address FundAddress, address ReceiveAddress
    ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;
        numTokensSellToAddToLiquidity = MinNum * 10 ** uint256(_decimals);

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        IERC20(FISTAddress).approve(address(swapRouter), MAX);
        IERC20(WETHAddress).approve(address(swapRouter), MAX);

        _fist = FISTAddress;
        _weth = WETHAddress;
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), WETHAddress);
        _mainPair = swapPair;
        _swapPairList[swapPair] = true;

        uint256 total = Supply * 10 ** uint256(_decimals);
        _tTotal = total;

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);

        fundAddress = FundAddress;

        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[marketingAddress] = true;
        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;

        excludeHolder[address(ZERO)] = true;
        excludeHolder[address(DEAD)] = true;

        holderRewardCondition = Reward * 10 ** IERC20(FISTAddress).decimals();

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

    function setLiquifyEnabled(bool _enabled) public onlyOwner {
        liquifyEnabled = _enabled;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
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

        bool shouldSetInviter = _balances[to] == 0 && inviter[to] == address(0) && 
                                !isContract(from) && !isContract(to) && 
                                from != owner() && to != owner();

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
                    swapTokenForFund(contractTokenBalance, swapFee);
                }

                takeFee = true;
            }
            if (_swapPairList[to]) {
                isSell = true;
            }
        }
        
        _tokenTransfer(from, to, amount, takeFee, isSell);

        if (shouldSetInviter) {
            inviter[to] = from;
        }

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
        uint256 marketingAmount;
        uint256 inviterAmount;
        uint256 burnAmount;

        _balances[sender] = _balances[sender].sub(tAmount);

        if (takeFee) {
            uint256 swapFee;
            if (isSell) {
                swapFee = _sellFundFee.add(_sellLPDividendFee).add(_sellLPFee);
                inviterAmount = tAmount.mul(_sellInviterFee).div(10000);
                burnAmount = tAmount.mul(_sellBurnFee).div(10000);
                feeAmount = feeAmount.add(inviterAmount).add(burnAmount);
                _takeTransfer(sender, DEAD, burnAmount);
            } else {
                swapFee = _buyFundFee.add(_buyLPDividendFee).add(_buyLPFee);
                marketingAmount = tAmount.mul(_buyMarketingFee).div(10000);
                inviterAmount = tAmount.mul(_buyInviterFee).div(10000);
                feeAmount = feeAmount.add(marketingAmount).add(inviterAmount);
                _takeTransfer(sender, marketingAddress, marketingAmount);
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
            _takeInviter(sender,recipient,tAmount,isSell);
        }

        _takeTransfer(sender, recipient, tAmount.sub(feeAmount));
    }

    function _takeInviter(
        address sender,
        address recipient,
        uint256 tAmount,
        bool isSell
    ) private {
        if (_buyInviterFee == 0 && _sellInviterFee == 0) return;

        address cur = sender;
        if (_swapPairList[sender]) {
            cur = recipient;
        } else if (_swapPairList[recipient]) {
            cur = sender;
        }
        if (cur == address(0)) {
            return;
        }

        for (int256 i = 0; i < 2; i++) {
            uint256 rate;
            if(isSell) {
                if (i == 0) {
                    rate = _sellFInviterFee;
                } else if (i == 1) {
                    rate = _sellSInviterFee;
                } 
            } else {
                if (i == 0) {
                    rate = _buyFInviterFee;
                } else if (i == 1) {
                    rate = _buySInviterFee;
                }
            }
            cur = inviter[cur];
            if (cur == address(0)) {
                cur = inviterDefault;
            }
            uint256 curTAmount = tAmount.mul(rate).div(10000);
            _takeTransfer(sender,cur,curTAmount);
        }
    }

    function swapTokenForFund(uint256 tokenAmount, uint256 swapFee) private lockTheSwap {
        
        uint256 lpFee = _sellLPFee.add(_buyLPFee);
        uint256 lpAmount = tokenAmount.mul(lpFee).div(swapFee);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _fist;

        _approve(address(this), address(_swapRouter), _tTotal);

        // make the swap
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount.sub(lpAmount),
            0, // accept any amount of dividend token
            path,
            address(_tokenDistributor),
            block.timestamp
        );
        
        swapFee = swapFee.sub(lpFee);

        IERC20 FIST = IERC20(_fist);
        uint256 fistBalance = FIST.balanceOf(address(_tokenDistributor));
        uint256 fundAmount = fistBalance.mul(_buyFundFee.add(_sellFundFee)).div(swapFee);
        if(fundAmount > 0) {
            FIST.transferFrom(address(_tokenDistributor), fundAddress, fundAmount);
        }
        FIST.transferFrom(address(_tokenDistributor), address(this), fistBalance.sub(fundAmount));

        if (lpAmount > 0) {
            uint256 addNumber = lpAmount;
            uint256 half = addNumber.div(2);
            uint256 otherHalf = addNumber.sub(half);

            uint256 initialBalance = address(this).balance;

            // swap tokens for ETH
            swapTokensForEth(half); // <- this breaks the ETH -> Token swap when swap+liquify is triggered

            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);
            
            // add liquidity to uniswap
            if (liquifyEnabled) {
                addLiquidity(otherHalf, newBalance);    
            }
            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_swapRouter), tokenAmount);

        // add the liquidity
        _swapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            payable(address(fundAddress)),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _swapRouter.WETH();

        _approve(address(this), address(_swapRouter), tokenAmount);

        // make the swap
        _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
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

    function setMarketingAddress(address addr) external onlyFunder {
        marketingAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function setInviterDefault(address addr) external onlyFunder {
        inviterDefault = addr;
        _feeWhiteList[addr] = true;
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

    function setBuyMarketingFee(uint256 marketingFee) external onlyOwner {
        _buyMarketingFee = marketingFee;
    }

    function setBuyInviterFee(uint256 inviterFee) external onlyOwner {
        _buyInviterFee = inviterFee;
    }

    function setBuyFInviterFee(uint256 inviterFFee) external onlyOwner {
        _buyFInviterFee = inviterFFee;
    }

    function setBuySInviterFee(uint256 inviterSFee) external onlyOwner {
        _buySInviterFee = inviterSFee;
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

    function setSellMarketingFee(uint256 marketingFee) external onlyOwner {
        _sellMarketingFee = marketingFee;
    }

    function setSellInviterFee(uint256 inviterFee) external onlyOwner {
        _sellInviterFee = inviterFee;
    }

    function setSellFInviterFee(uint256 inviterFFee) external onlyOwner {
        _sellFInviterFee = inviterFFee;
    }

    function setSellSInviterFee(uint256 inviterSFee) external onlyOwner {
        _sellSInviterFee = inviterSFee;
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

    function isContract(address account) internal view returns (bool) {
        uint256 addressFlag;
        assembly {
            addressFlag := extcodesize(account)
        }
        return addressFlag > 0;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyFunder {
        _feeWhiteList[addr] = enable;
    }

    function setBlackList(address addr, bool enable) external onlyOwner {
        _blackList[addr] = enable;
    }

    function setSwapPairList(address addr, bool enable) external onlyFunder {
        require(addr != _mainPair, "BEP20: The Main pair cannot be removed from swapPairList");
        _setSwapPairList(addr, enable);
    }

    function _setSwapPairList(address addr, bool enable) private {
        require(_swapPairList[addr] != enable, "BEP20: swapPairList is already set to that enable");
        _swapPairList[addr] = enable;
        emit SetSwapPairList(addr, enable);
    }

    function claimBalance() external onlyFunder {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount, address to) external onlyFunder {
        IERC20(token).transfer(to, amount);
    }

    modifier onlyFunder() {
        require(owner() == msg.sender || fundAddress == msg.sender, "BEP20: caller is not owner or Funder");
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