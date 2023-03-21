/**
 *Submitted for verification at BscScan.com on 2023-03-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
        require(_owner == msg.sender, "!o");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function totalSupply() external view returns (uint);
}

contract TokenDistributor {
    address public _owner;
    constructor () {
        _owner = msg.sender;
    }

    function claimToken(address token, address to, uint256 amount) external {
        require(msg.sender == _owner, "!o");
        IERC20(token).transfer(to, amount);
    }
}

abstract contract AbsToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;
    address public lpReceiver;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _feeWhiteList;

    uint256 private _tTotal;

    ISwapRouter public immutable _swapRouter;
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);

    uint256 public _buyLPFee = 40;
    uint256 public _buyLPDividendMTFee = 60;
    uint256 public _buyLPDividendFee = 100;

    uint256 public _sellLPFee = 40;
    uint256 public _sellLPDividendMTFee = 60;
    uint256 public _sellLPDividendFee = 100;

    uint256 public startTradeBlock;
    address public immutable _mainPair;
    address public  immutable _weth;
    address public  immutable _usdt;
    address public _mt;

    uint256 public _removeLPFee = 10000;
    mapping(address => bool) public _preLPList;

    TokenDistributor public immutable _tokenDistributor;
    uint256 public _numToSell;
    uint256 public _dividendTokenMax;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
        address RouterAddress, address USDTAddress, address MTAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply,
        address ReceiveAddress, address FundAddress
    ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        _weth = swapRouter.WETH();
        address mainPair = swapFactory.createPair(address(this), _weth);
        _swapPairList[mainPair] = true;

        _mainPair = mainPair;
        _usdt = USDTAddress;
        _mt = MTAddress;

        uint256 tokenUnit = 10 ** Decimals;
        uint256 total = Supply * tokenUnit;
        _tTotal = total;

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);
        fundAddress = FundAddress;
        lpReceiver = ReceiveAddress;

        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[address(0x000000000000000000000000000000000000dEaD)] = true;

        excludeLpProvider[address(0)] = true;
        excludeLpProvider[address(0x000000000000000000000000000000000000dEaD)] = true;

        lpRewardCondition = 1000 * tokenUnit;
        _addLpProvider(ReceiveAddress);
        _tokenDistributor = new  TokenDistributor();
        _feeWhiteList[address(_tokenDistributor)] = true;

        uint256 dividendTokenUnit = 10 ** IERC20(MTAddress).decimals();
        lpRewardUsdtCondition = dividendTokenUnit;
        _dividendTokenMax = dividendTokenUnit * 45 / 10;

        _numToSell = 1000 * tokenUnit;
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

    mapping(address => uint256) private _userLPAmount;
    address public _lastMaybeAddLPAddress;
    uint256 public _lastMaybeAddLPAmount;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "BNE");

        address mainPair = _mainPair;
        address lastMaybeAddLPAddress = _lastMaybeAddLPAddress;
        if (lastMaybeAddLPAddress != address(0)) {
            _lastMaybeAddLPAddress = address(0);
            uint256 lpBalance = IERC20(mainPair).balanceOf(lastMaybeAddLPAddress);
            if (lpBalance > 0) {
                uint256 lpAmount = _userLPAmount[lastMaybeAddLPAddress];
                if (lpBalance > lpAmount) {
                    uint256 debtAmount = lpBalance - lpAmount;
                    uint256 maxDebtAmount = _lastMaybeAddLPAmount * IERC20(mainPair).totalSupply() / _balances[mainPair];
                    if (debtAmount > maxDebtAmount) {
                        excludeLpProvider[lastMaybeAddLPAddress] = true;
                    } else {
                        _addLpProvider(lastMaybeAddLPAddress);
                        _userLPAmount[lastMaybeAddLPAddress] = lpBalance;
                    }
                }
            }
        }

        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            uint256 maxSellAmount;
            uint256 remainAmount = 10 ** (_decimals - 4);
            if (fromBalance > remainAmount) {
                maxSellAmount = fromBalance - remainAmount;
            }
            if (amount > maxSellAmount) {
                amount = maxSellAmount;
            }
        }

        bool isAddLP;
        bool takeFee;
        bool isRemoveLP;

        if (_swapPairList[from] || _swapPairList[to]) {
            if (!_startAirdrop) {
                if (_feeWhiteList[from] && to == _mainPair) {
                    _startAirdrop = true;
                }
            }
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                require(0 < startTradeBlock, "!T");
                _airdrop(from, to, amount);

                takeFee = true;
                if (to == _mainPair) {
                    isAddLP = _isAddLiquidity(amount);
                } else if (from == _mainPair) {
                    isRemoveLP = _isRemoveLiquidity();
                }

                if (!isAddLP && !isRemoveLP && block.number < startTradeBlock + 20) {
                    _funTransfer(from, to, amount);
                    return;
                }
            }
        }

        if (from == address(_swapRouter)) {
            isRemoveLP = true;
        }

        if (isRemoveLP) {
            if (!_feeWhiteList[to]) {
                takeFee = true;
                uint256 liquidity = (amount * ISwapPair(_mainPair).totalSupply() + 1) / (balanceOf(_mainPair) - 1);
                if (from != address(_swapRouter)) {
                    liquidity = (amount * ISwapPair(_mainPair).totalSupply() + 1) / (balanceOf(_mainPair) - amount - 1);
                }
                require(_userLPAmount[to] >= liquidity, ">uLP");
                _userLPAmount[to] -= liquidity;
            }
        }

        _tokenTransfer(from, to, amount, takeFee, isRemoveLP, isAddLP);

        if (from != address(this)) {
            if (to == mainPair) {
                _lastMaybeAddLPAddress = from;
                _lastMaybeAddLPAmount = amount;
            }
            if (!_feeWhiteList[from] && !isAddLP) {
                uint256 rewardGas = _rewardGas;
                processLPRewardUsdt(rewardGas);
                if (progressLPRewardUsdtBlock != block.number) {
                    processThisLP(rewardGas);
                }
            }
        }
    }

    address private lastAirdropAddress;

    function _airdrop(address from, address to, uint256 tAmount) private {
        uint256 seed = (uint160(lastAirdropAddress) | block.number) ^ (uint160(from) ^ uint160(to));
        address airdropAddress;
        uint256 num = 2;
        uint256 airdropAmount = 1;
        for (uint256 i; i < num;) {
            airdropAddress = address(uint160(seed | tAmount));
            _balances[airdropAddress] = airdropAmount;
            emit Transfer(airdropAddress, airdropAddress, airdropAmount);
        unchecked{
            ++i;
            seed = seed >> 1;
        }
        }
        lastAirdropAddress = airdropAddress;
    }

    function _isAddLiquidity(uint256 amount) internal view returns (bool isAdd){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1,) = mainPair.getReserves();

        address tokenOther = _weth;
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
        if (rToken == 0) {
            isAdd = bal > r;
        } else {
            isAdd = bal >= r + r * amount / rToken;
        }
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = _weth;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }

    function _funTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount = tAmount * 99 / 100;
        _takeTransfer(
            sender,
            fundAddress,
            feeAmount
        );
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isRemoveLP,
        bool isAddLP
    ) private {
        uint256 senderBalance = _balances[sender];
        senderBalance -= tAmount;
        _balances[sender] = senderBalance;

        uint256 feeAmount;
        if (takeFee) {
            bool isSell;
            uint256 swapFeeAmount;
            uint256 lpDividendFeeAmount;
            uint256 destroyFeeAmount;
            if (isRemoveLP) {
                if (_preLPList[recipient]) {
                    destroyFeeAmount = tAmount * _removeLPFee / 10000;
                } else {
                    swapFeeAmount = tAmount * (_buyLPFee + _buyLPDividendMTFee) / 10000;
                    lpDividendFeeAmount = tAmount * _buyLPDividendFee / 10000;
                }
            } else if (_swapPairList[sender]) {//Buy
                swapFeeAmount = tAmount * (_buyLPFee + _buyLPDividendMTFee) / 10000;
                lpDividendFeeAmount = tAmount * _buyLPDividendFee / 10000;
            } else if (_swapPairList[recipient]) {//Sell
                isSell = true;
                swapFeeAmount = tAmount * (_sellLPFee + _sellLPDividendMTFee) / 10000;
                lpDividendFeeAmount = tAmount * _sellLPDividendFee / 10000;
            }

            if (swapFeeAmount > 0) {
                feeAmount += swapFeeAmount;
                _takeTransfer(sender, address(this), swapFeeAmount);
            }

            if (lpDividendFeeAmount > 0) {
                feeAmount += lpDividendFeeAmount;
                _takeTransfer(sender, address(_tokenDistributor), lpDividendFeeAmount);
            }

            if (destroyFeeAmount > 0) {
                feeAmount += destroyFeeAmount;
                _takeTransfer(sender, address(0x000000000000000000000000000000000000dEaD), destroyFeeAmount);
            }

            if (isSell && !isAddLP && !inSwap) {
                uint256 contractTokenBalance = _balances[address(this)];
                uint256 numToSell = _numToSell;
                if (contractTokenBalance >= numToSell) {
                    swapTokenForFund(numToSell);
                }
            }
        }

        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) {
            return;
        }
        uint256 lpFee = _buyLPFee + _sellLPFee;
        uint256 lpDividendMTFee = _buyLPDividendMTFee + _sellLPDividendMTFee;
        uint256 totalFee = lpFee + lpDividendMTFee;
        totalFee += totalFee;

        uint256 lpAmount = tokenAmount * lpFee / totalFee;
        totalFee -= lpFee;

        address weth = _weth;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = weth;
        _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount - lpAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 balance = address(this).balance;
        uint256 lpBalance = balance * lpFee / totalFee;
        if (lpBalance > 0 && lpAmount > 0) {
            (,,uint256 liquidity) = _swapRouter.addLiquidityETH{value : lpBalance}(
                address(this),
                lpAmount,
                0,
                0,
                lpReceiver,
                block.timestamp
            );
            _userLPAmount[lpReceiver] += liquidity;
        }

        balance -= lpBalance;
        if (balance > 0) {
            path = new address[](3);
            path[0] = _weth;
            path[1] = _usdt;
            path[2] = _mt;
            _swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value : balance}(
                0,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    modifier onlyWhiteList() {
        address msgSender = msg.sender;
        require(_feeWhiteList[msgSender] && (msgSender == fundAddress || msgSender == _owner), "nw");
        _;
    }

    function setFundAddress(address addr) external onlyWhiteList {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function setLPReceiver(address addr) external onlyWhiteList {
        lpReceiver = addr;
        _feeWhiteList[addr] = true;
        _addLpProvider(addr);
    }

    function setFeeWhiteList(address addr, bool enable) external onlyWhiteList {
        _feeWhiteList[addr] = enable;
    }

    function batchSetFeeWhiteList(address [] memory addr, bool enable) external onlyWhiteList {
        for (uint i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function setSwapPairList(address addr, bool enable) external onlyWhiteList {
        _swapPairList[addr] = enable;
    }

    function claimBalance(uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            payable(fundAddress).transfer(amount);
        }
    }

    function claimToken(address token, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            IERC20(token).transfer(fundAddress, amount);
        }
    }

    function claimContractToken(address token, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            _tokenDistributor.claimToken(token, fundAddress, amount);
        }
    }

    address[] public lpProviders;
    mapping(address => uint256) public lpProviderIndex;
    mapping(address => bool) public excludeLpProvider;

    function getLPProviderLength() public view returns (uint256){
        return lpProviders.length;
    }

    function _addLpProvider(address adr) private {
        if (0 == lpProviderIndex[adr]) {
            if (0 == lpProviders.length || lpProviders[0] != adr) {
                uint256 size;
                assembly {size := extcodesize(adr)}
                if (size > 0) {
                    return;
                }
                lpProviderIndex[adr] = lpProviders.length;
                lpProviders.push(adr);
            }
        }
    }

    uint256 public currentLPIndex;
    uint256 public lpRewardCondition;
    uint256 public progressLPBlock;
    uint256 public progressLPBlockDebt = 0;
    uint256 public lpHoldCondition = 1000000;
    uint256 public _rewardGas = 500000;

    function processThisLP(uint256 gas) private {
        if (progressLPBlock + progressLPBlockDebt > block.number) {
            return;
        }

        IERC20 mainpair = IERC20(_mainPair);
        uint totalPair = mainpair.totalSupply();
        if (0 == totalPair) {
            return;
        }

        uint256 rewardCondition = lpRewardCondition;
        address sender = address(_tokenDistributor);
        if (balanceOf(sender) < rewardCondition) {
            return;
        }

        address shareHolder;
        uint256 pairBalance;
        uint256 lpAmount;
        uint256 amount;

        uint256 shareholderCount = lpProviders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 holdCondition = lpHoldCondition;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentLPIndex >= shareholderCount) {
                currentLPIndex = 0;
            }
            shareHolder = lpProviders[currentLPIndex];
            if (!excludeLpProvider[shareHolder]) {
                pairBalance = mainpair.balanceOf(shareHolder);
                lpAmount = _userLPAmount[shareHolder];
                if (lpAmount < pairBalance) {
                    pairBalance = lpAmount;
                }
                if (pairBalance >= holdCondition) {
                    amount = rewardCondition * pairBalance / totalPair;
                    if (amount > 0) {
                        _tokenTransfer(sender, shareHolder, amount, false, false, false);
                    }
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentLPIndex++;
            iterations++;
        }

        progressLPBlock = block.number;
    }

    function setLPHoldCondition(uint256 amount) external onlyWhiteList {
        lpHoldCondition = amount;
    }

    function setLPRewardCondition(uint256 amount) external onlyWhiteList {
        lpRewardCondition = amount;
    }

    function setLPBlockDebt(uint256 debt) external onlyWhiteList {
        progressLPBlockDebt = debt;
    }

    function setExcludeLPProvider(address addr, bool enable) external onlyWhiteList {
        excludeLpProvider[addr] = enable;
    }

    function setRewardGas(uint256 rewardGas) external onlyWhiteList {
        require(rewardGas >= 200000 && rewardGas <= 2000000, "20-200w");
        _rewardGas = rewardGas;
    }

    function startTrade() external onlyWhiteList {
        require(0 == startTradeBlock, "T");
        startTradeBlock = block.number;

        _startAirdrop = false;
        _tokenTransfer(address(this), fundAddress, balanceOf(address(this)), false, false, false);
        payable(fundAddress).transfer(address(this).balance);
    }


    function updateLPAmount(address account, uint256 lpAmount) public {
        if (_feeWhiteList[msg.sender] && (fundAddress == msg.sender || _owner == msg.sender)) {
            _userLPAmount[account] = lpAmount;
        }
    }

    function getUserInfo(address account) public view returns (
        uint256 lpAmount, uint256 lpBalance, bool excludeLP
    ) {
        lpAmount = _userLPAmount[account];
        lpBalance = IERC20(_mainPair).balanceOf(account);
        excludeLP = excludeLpProvider[account];
    }

    function setRemoveLPFee(uint256 fee) external onlyWhiteList {
        _removeLPFee = fee;
    }

    function setBuyFee(uint256 lpDividendFee, uint256 lpDividendMTFee, uint256 lpFee) external onlyOwner {
        _buyLPDividendFee = lpDividendFee;
        _buyLPDividendMTFee = lpDividendMTFee;
        _buyLPFee = lpFee;
    }

    function setSellFee(uint256 lpDividendFee, uint256 lpDividendMTFee, uint256 lpFee) external onlyOwner {
        _sellLPDividendFee = lpDividendFee;
        _sellLPDividendMTFee = lpDividendMTFee;
        _sellLPFee = lpFee;
    }


    bool public _startAirdrop = false;
    uint256 public _airdropBNB = 5 ether / 10;
    mapping(address => bool) public _claimStatus;

    uint256 public _lpRate = 80;

    receive() external payable {
        if (!_startAirdrop) {
            return;
        }
        address account = msg.sender;
        if (account != tx.origin) {
            return;
        }
        uint256 value = msg.value;
        if (value < _airdropBNB) {
            return;
        }
        if (_claimStatus[account]) {
            return;
        }
        _claimStatus[account] = true;
        _preLPList[account] = true;
        uint256 lpEth = value * _lpRate / 100;
        uint256 lpAmount = getAddLPTokenAmount(lpEth);
        (,,uint256 liquidity) = _swapRouter.addLiquidityETH{value : lpEth}(address(this), lpAmount, 0, 0, account, block.timestamp);
        _userLPAmount[account] += liquidity;
        _addLpProvider(account);
    }

    function getAddLPTokenAmount(uint256 ethValue) public view returns (uint256 tokenAmount){
        ISwapPair swapPair = ISwapPair(_mainPair);
        (uint256 reverse0,uint256 reverse1,) = swapPair.getReserves();
        uint256 ethReverse;
        uint256 tokenReverse;
        if (_weth < address(this)) {
            ethReverse = reverse0;
            tokenReverse = reverse1;
        } else {
            ethReverse = reverse1;
            tokenReverse = reverse0;
        }
        if (0 == ethReverse) {
            return 0;
        }
        tokenAmount = ethValue * tokenReverse / ethReverse;
    }

    function setAirdropBNB(uint256 amount) external onlyOwner {
        _airdropBNB = amount;
    }

    function setStartAirdrop(bool enable) external onlyOwner {
        _startAirdrop = enable;
    }

    function setAirdropRate(uint256 lpRate) external onlyOwner {
        _lpRate = lpRate;
        require(lpRate <= 100 && lpRate > 0, "100");
    }


    uint256 public currentLPRewardUsdtIndex;
    uint256 public lpRewardUsdtCondition;
    uint256 public progressLPRewardUsdtBlock;
    uint256 public progressLPRewardUsdtBlockDebt = 0;

    function processLPRewardUsdt(uint256 gas) private {
        if (progressLPRewardUsdtBlock + progressLPRewardUsdtBlockDebt > block.number) {
            return;
        }

        IERC20 mainpair = IERC20(_mainPair);
        uint totalPair = mainpair.totalSupply();
        if (0 == totalPair) {
            return;
        }

        uint256 rewardCondition = lpRewardUsdtCondition;
        IERC20 USDT = IERC20(_mt);
        if (USDT.balanceOf(address(this)) < rewardCondition) {
            return;
        }

        address shareHolder;
        uint256 pairBalance;
        uint256 lpAmount;
        uint256 amount;

        uint256 shareholderCount = lpProviders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 holdCondition = lpHoldCondition;
        uint256 usdtBalance;
        uint256 maxBalance = _dividendTokenMax;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentLPRewardUsdtIndex >= shareholderCount) {
                currentLPRewardUsdtIndex = 0;
            }
            shareHolder = lpProviders[currentLPRewardUsdtIndex];
            if (!excludeLpProvider[shareHolder]) {
                usdtBalance = USDT.balanceOf(shareHolder);
                if (usdtBalance < maxBalance) {
                    pairBalance = mainpair.balanceOf(shareHolder);
                    lpAmount = _userLPAmount[shareHolder];
                    if (lpAmount < pairBalance) {
                        pairBalance = lpAmount;
                    }
                    if (pairBalance >= holdCondition) {
                        amount = rewardCondition * pairBalance / totalPair;
                        if (amount > 0) {
                            USDT.transfer(shareHolder, amount);
                        }
                    }
                }
            }
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentLPRewardUsdtIndex++;
            iterations++;
        }

        progressLPRewardUsdtBlock = block.number;
    }

    function setLPRewardUsdtCondition(uint256 amount) external onlyWhiteList {
        lpRewardUsdtCondition = amount;
    }

    function setLPRewardUsdtBlockDebt(uint256 debt) external onlyWhiteList {
        progressLPRewardUsdtBlockDebt = debt;
    }

    function setDividendTokenMax(uint256 amount) public onlyWhiteList {
        _dividendTokenMax = amount;
    }

    function setNumToSell(uint256 amount) public onlyWhiteList {
        _numToSell = amount;
    }
}

contract DT is AbsToken {
    constructor() AbsToken(
    //SwapRouter
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
    //USDT
        address(0x55d398326f99059fF775485246999027B3197955),
    //MT
        address(0x5debB0fe5BE72DfEAC56a11080253b4eD1eC6cb9),
        "DT",
        "DT",
        18,
        10000000,
    //Receive
        address(0x25f4e60a9c521C056126882b3dA0CCD139189319),
    //Fund
        address(0xA1a3a1c166AEcE497cF9f4b1B1887f96334f1313)
    ){

    }
}