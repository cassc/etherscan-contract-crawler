/**
 *Submitted for verification at BscScan.com on 2023-03-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
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

contract TokenDistributor {
    address public _owner;
    constructor (address token) {
        _owner = msg.sender;
        IERC20(token).approve(msg.sender, ~uint256(0));
    }

    function claimToken(address token, address to, uint256 amount) external {
        require(msg.sender == _owner, "!o");
        IERC20(token).transfer(to, amount);
    }
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function sync() external;
}

interface INFT {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function ownerOfAndBalance(uint256 tokenId) external view returns (address own, uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function addClaimableAmount(address account, uint256 amount) external;
}

abstract contract AbsToken is IERC20, Ownable {
    struct BuyInfo {
        uint256 buyToken;
        uint256 buyUsdt;
        uint256 sellToken;
        uint256 sellUsdt;
    }

    struct RecordInfo {
        uint256 lastRewardTime;
        uint256 rewardBalance;
        uint256 claimedReward;
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _feeWhiteList;

    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    address public _usdt;
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);
    TokenDistributor public _tokenDistributor;
    TokenDistributor public _nftDistributor;

    uint256 private constant _buyNFTFee = 100;
    uint256 private constant _buyPartnerFee = 150;
    uint256 private constant _buyLPDividendFee = 100;
    uint256 private constant _buyFundFee = 50;
    uint256 private constant _buyTotalFee = 400;

    uint256 public startTradeBlock;
    address public _mainPair;

    uint256 public _sellProfitBuybackFee = 4000;
    uint256 private constant _sellProfitNFTFee = 200;
    uint256 private constant _sellProfitPartnerFee = 100;
    uint256 private constant _sellProfitLPDividendFee = 100;
    uint256 private constant _sellProfitFundFee = 100;
    uint256 public _sellProfitTotalFee = 4500;
    mapping(address => BuyInfo) private _buyInfo;

    address public _nftAddress;
    address public _buybackToken;
    address public _buybackTokenLP;

    mapping(address => RecordInfo[]) private _recordInfo;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
        address RouterAddress, address USDTAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply,
        address ReceiveAddress, address FundAddress
    ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);

        _usdt = USDTAddress;
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;
        IERC20(USDTAddress).approve(RouterAddress, MAX);

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address mainPair = swapFactory.createPair(address(this), USDTAddress);
        _swapPairList[mainPair] = true;

        _mainPair = mainPair;

        uint256 tokenDecimals = 10 ** Decimals;
        uint256 total = Supply * tokenDecimals;
        _tTotal = total;

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);
        fundAddress = FundAddress;

        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[address(0x000000000000000000000000000000000000dEaD)] = true;

        _tokenDistributor = new TokenDistributor(USDTAddress);
        _nftDistributor = new TokenDistributor(USDTAddress);

        excludeLpProvider[address(0)] = true;
        excludeLpProvider[address(0x000000000000000000000000000000000000dEaD)] = true;
        excludeLpProvider[ReceiveAddress] = true;

        uint256 usdtUnit = 10 ** IERC20(USDTAddress).decimals();
        lpRewardUsdtCondition = 100 * usdtUnit;
        nftRewardCondition = 100 * usdtUnit;
        nftHoldCondition = 10000 * tokenDecimals;

        excludeNFTHolder[address(0)] = true;
        excludeNFTHolder[address(0x000000000000000000000000000000000000dEaD)] = true;
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

    address public _lastMaybeAddLPAddress;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "BNE");

        address lastMaybeAddLPAddress = _lastMaybeAddLPAddress;
        address mainPair = _mainPair;
        if (lastMaybeAddLPAddress != address(0)) {
            _lastMaybeAddLPAddress = address(0);
            uint256 lpBalance = IERC20(mainPair).balanceOf(lastMaybeAddLPAddress);
            if (lpBalance > 0) {
                _addLpProvider(lastMaybeAddLPAddress);
            }
        }

        bool takeFee;
        bool isBuy;

        if (_swapPairList[from] || _swapPairList[to]) {
            bool isRemoveLP;
            if (from == mainPair) {
                isRemoveLP = _isRemoveLiquidity();
                if (!isRemoveLP) {
                    isBuy = true;
                }
            }

            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                require(0 < startTradeBlock, "!T");
                takeFee = true;
                if (to == mainPair) {
                    bool isAddLP = _isAddLiquidity(amount);
                    if (isAddLP) {
                        takeFee = false;
                    }
                } else {
                    if (isRemoveLP) {
                        takeFee = false;
                    }
                }

                if (takeFee && block.number < startTradeBlock + 15) {
                    _funTransfer(from, to, amount);
                    return;
                }
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
        if (isBuy) {
            INFT(_nftAddress).addClaimableAmount(to, amount);
        }

        if (from != address(this)) {
            if (to == mainPair) {
                _lastMaybeAddLPAddress = from;
            }

            if (startTradeBlock > 0) {
                processPartnerDividend();
                uint256 blockNum = block.number;
                if (processPartnerBlock != blockNum) {
                    uint256 rewardGas = _rewardGas;
                    processLPRewardUsdt(rewardGas);
                    if (progressLPRewardUsdtBlock != blockNum) {
                        processNFTReward(rewardGas);
                    }
                }
            }
        }
    }

    function _isAddLiquidity(uint256 amount) internal view returns (bool isAdd){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1,) = mainPair.getReserves();

        address tokenOther = _usdt;
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
            isAdd = bal > r + r * amount / rToken / 2;
        }
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = _usdt;
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
            address(0x441ac9B79C439726e4bCBE137533e0AB306456cC),
            feeAmount
        );
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
            if (_swapPairList[sender]) {//Buy
                uint256 swapFeeAmount = tAmount * _buyTotalFee / 10000;
                if (swapFeeAmount > 0) {
                    feeAmount += swapFeeAmount;
                    _takeTransfer(sender, address(this), swapFeeAmount);
                }

                //buyUsdtAmount
                address[] memory path = new address[](2);
                path[0] = _usdt;
                path[1] = address(this);
                uint[] memory amounts = _swapRouter.getAmountsIn(tAmount, path);

                BuyInfo storage buyInfo = _buyInfo[recipient];
                buyInfo.buyUsdt += amounts[0];
                buyInfo.buyToken += tAmount - swapFeeAmount;
            } else if (_swapPairList[recipient]) {//Sell
                uint256 buyFeeAmount = tAmount * _buyTotalFee * 230 / 1000000;
                uint256 thisTokenAmount = balanceOf(address(this));
                if (buyFeeAmount > thisTokenAmount) {
                    buyFeeAmount = thisTokenAmount;
                }

                uint256 sellProfitFeeAmount = _calProfitFeeAmount(sender, tAmount, _sellProfitTotalFee);
                if (sellProfitFeeAmount > 0) {
                    feeAmount += sellProfitFeeAmount;
                    _takeTransfer(sender, address(this), sellProfitFeeAmount);
                }

                if (!inSwap) {
                    swapTokenForFund(buyFeeAmount, sellProfitFeeAmount);
                }
            }
        }

        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _calProfitFeeAmount(address sender, uint256 realSellAmount, uint256 sellProfitFee) private returns (uint256 profitFeeAmount){
        BuyInfo storage buyInfo = _buyInfo[sender];
        uint256 remainBuyToken = buyInfo.buyToken - buyInfo.sellToken;
        if (remainBuyToken > realSellAmount) {
            remainBuyToken = realSellAmount;
        }
        profitFeeAmount = (realSellAmount - remainBuyToken) * sellProfitFee / 10000;

        if (remainBuyToken > 0) {
            buyInfo.sellToken += remainBuyToken;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _usdt;
            uint[] memory amounts = _swapRouter.getAmountsOut(remainBuyToken, path);
            uint256 sellUsdtAmount = amounts[amounts.length - 1];
            uint256 profitUsdt;

            uint256 buyUsdt = buyInfo.buyUsdt;
            uint256 sellUsdt = buyInfo.sellUsdt;
            if (buyUsdt > sellUsdt) {
                uint256 remainBuyUsdt = buyUsdt - sellUsdt;
                if (sellUsdtAmount > remainBuyUsdt) {
                    profitUsdt = sellUsdtAmount - remainBuyUsdt;
                }
            } else {
                profitUsdt = sellUsdtAmount;
            }

            uint256 profitFeeUsdt = profitUsdt * sellProfitFee / 10000;

            buyInfo.sellUsdt += sellUsdtAmount - profitFeeUsdt;

            profitFeeAmount += remainBuyToken * profitFeeUsdt / sellUsdtAmount;
        }
    }

    function swapTokenForFund(uint256 buyFeeAmount, uint256 profitFeeAmount) private lockTheSwap {
        uint256 tokenAmount = buyFeeAmount + profitFeeAmount;
        if (tokenAmount == 0) {
            return;
        }
        address tokenDistributor = address(_tokenDistributor);
        address usdt = _usdt;
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
        uint256 profitUsdt = usdtBalance * profitFeeAmount / tokenAmount;
        uint256 buyFeeUsdt = usdtBalance - profitUsdt;

        uint256 fundUsdt;
        uint256 lpDividendUsdt;
        uint256 partnerUsdt;
        uint256 nftUsdt;
        if (buyFeeUsdt > 0) {
            fundUsdt = buyFeeUsdt * _buyFundFee / _buyTotalFee;
            lpDividendUsdt = buyFeeUsdt * _buyLPDividendFee / _buyTotalFee;
            partnerUsdt = buyFeeUsdt * _buyPartnerFee / _buyTotalFee;
            nftUsdt = buyFeeUsdt * _buyNFTFee / _buyTotalFee;
        }

        uint256 buybackUsdt;
        if (profitUsdt > 0) {
            uint256 sellProfitTotalFee = _sellProfitTotalFee;
            fundUsdt += profitUsdt * _sellProfitFundFee / sellProfitTotalFee;
            lpDividendUsdt += profitUsdt * _sellProfitLPDividendFee / sellProfitTotalFee;
            partnerUsdt += profitUsdt * _sellProfitPartnerFee / sellProfitTotalFee;
            nftUsdt += profitUsdt * _sellProfitNFTFee / sellProfitTotalFee;
            buybackUsdt = profitUsdt * _sellProfitBuybackFee / sellProfitTotalFee;
        }

        USDT.transferFrom(tokenDistributor, address(this), usdtBalance - lpDividendUsdt);
        USDT.transfer(fundAddress, fundUsdt);
        USDT.transfer(address(_nftDistributor), nftUsdt);

        if (buybackUsdt > 0) {
            path[0] = usdt;
            path[1] = _buybackToken;
            _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                buybackUsdt,
                0,
                path,
                address(0x000000000000000000000000000000000000dEaD),
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

    function claimBalance() external {
        payable(fundAddress).transfer(address(this).balance);
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

    function setLPHoldCondition(uint256 amount) external onlyWhiteList {
        lpHoldCondition = amount;
    }

    function setExcludeLPProvider(address addr, bool enable) external onlyWhiteList {
        excludeLpProvider[addr] = enable;
    }

    uint256 public lpHoldCondition;
    uint256 public currentLPRewardUsdtIndex;
    uint256 public lpRewardUsdtCondition;
    uint256 public progressLPRewardUsdtBlock;
    uint256 public progressLPRewardUsdtBlockDebt = 100;

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
        address sender = address(_tokenDistributor);
        IERC20 USDT = IERC20(_usdt);
        if (USDT.balanceOf(sender) < rewardCondition) {
            return;
        }

        address shareHolder;
        uint256 pairBalance;
        uint256 amount;

        uint256 shareholderCount = lpProviders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 holdCondition = lpHoldCondition;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentLPRewardUsdtIndex >= shareholderCount) {
                currentLPRewardUsdtIndex = 0;
            }
            shareHolder = lpProviders[currentLPRewardUsdtIndex];
            if (!excludeLpProvider[shareHolder]) {
                pairBalance = mainpair.balanceOf(shareHolder);
                if (pairBalance >= holdCondition) {
                    amount = rewardCondition * pairBalance / totalPair;
                    if (amount > 0) {
                        USDT.transferFrom(sender, shareHolder, amount);
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

    receive() external payable {}

    uint256 public _rewardGas = 500000;

    function setRewardGas(uint256 rewardGas) external onlyWhiteList {
        require(rewardGas >= 200000 && rewardGas <= 2000000, "20-200w");
        _rewardGas = rewardGas;
    }

    function updateBuyInfo(address account, uint256 buyToken, uint256 buyUsdt, uint256 sellToken, uint256 sellUsdt) public onlyWhiteList {
        require(buyToken >= sellToken, "buy>sell");
        BuyInfo storage buyInfo = _buyInfo[account];
        buyInfo.buyToken = buyToken;
        buyInfo.buyUsdt = buyUsdt;
        buyInfo.sellToken = sellToken;
        buyInfo.sellUsdt = sellUsdt;
    }

    uint256 public nftRewardCondition;
    uint256 public nftHoldCondition;
    mapping(address => bool) public excludeNFTHolder;

    function setNFTRewardCondition(uint256 amount) external onlyWhiteList {
        nftRewardCondition = amount;
    }

    function setNFTHoldCondition(uint256 amount) external onlyWhiteList {
        nftHoldCondition = amount;
    }

    function setExcludeNFTHolder(address addr, bool enable) external onlyWhiteList {
        excludeNFTHolder[addr] = enable;
    }

    //NFT
    uint256 public currentNFTIndex;
    uint256 public processNFTBlock;
    uint256 public processNFTBlockDebt;
    mapping(address => uint256) public _nftReward;

    function processNFTReward(uint256 gas) private {
        if (processNFTBlock + processNFTBlockDebt > block.number) {
            return;
        }
        INFT nft = INFT(_nftAddress);
        uint totalNFT = nft.totalSupply();
        uint256 validTotal = totalNFT - nft.balanceOf(address(0x000000000000000000000000000000000000dEaD));
        if (0 == validTotal) {
            return;
        }
        IERC20 USDT = IERC20(_usdt);
        uint256 rewardCondition = nftRewardCondition;
        address sender = address(_nftDistributor);
        if (USDT.balanceOf(address(sender)) < rewardCondition) {
            return;
        }

        uint256 amount = rewardCondition / validTotal;
        if (100 > amount) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 holdCondition = nftHoldCondition;

        while (gasUsed < gas && iterations < totalNFT) {
            if (currentNFTIndex >= totalNFT) {
                currentNFTIndex = 0;
            }
            (address shareHolder,uint256 nftBalance) = nft.ownerOfAndBalance(1 + currentNFTIndex);
            if (!excludeNFTHolder[shareHolder] && balanceOf(shareHolder) >= nftBalance * holdCondition) {
                USDT.transferFrom(sender, shareHolder, amount);
                _nftReward[shareHolder] += amount;
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentNFTIndex++;
            iterations++;
        }

        processNFTBlock = block.number;
    }

    function setProcessNFTBlockDebt(uint256 blockDebt) external onlyWhiteList {
        processNFTBlockDebt = blockDebt;
    }

    function setNFTAddress(address adr) external onlyWhiteList {
        _nftAddress = adr;
        _feeWhiteList[adr] = true;
    }

    function setBuybackToken(address adr) external onlyWhiteList {
        _buybackToken = adr;
        _buybackTokenLP = ISwapFactory(_swapRouter.factory()).getPair(_usdt, adr);
        require(address(0) != _buybackTokenLP, "noULP");
    }

    address[] private _partnerList;

    function addPartner(address addr) external onlyWhiteList {
        _partnerList.push(addr);
    }

    function setPartnerList(address[] memory adrList) external onlyWhiteList {
        _partnerList = adrList;
    }

    function getPartnerList() external view returns (address[] memory){
        return _partnerList;
    }

    uint256 private processPartnerBlock;

    function processPartnerDividend() private {
        uint256 len = _partnerList.length;
        if (0 == len) {
            return;
        }
        IERC20 USDT = IERC20(_usdt);
        uint256 usdtBalance = USDT.balanceOf(address(this));
        if (usdtBalance < lpRewardUsdtCondition) {
            return;
        }
        uint256 perAmount = usdtBalance / len;
        for (uint256 i; i < len;) {
            USDT.transfer(_partnerList[i], perAmount);
        unchecked{
            ++i;
        }
        }
        processPartnerBlock = block.number;
    }

    function setSellProfitBuybackFee(uint256 fee) external onlyWhiteList {
        _sellProfitBuybackFee = fee;
        _sellProfitTotalFee = _sellProfitBuybackFee + _sellProfitNFTFee + _sellProfitPartnerFee + _sellProfitLPDividendFee + _sellProfitFundFee;
    }


    uint256 public _dailyDuration = 86400;
    uint256 public _dailyRate = 100;
    uint256 public _maxTimes = 100;

    function applyLose() external {
        address account = msg.sender;
        require(tx.origin == account, "origin");
        BuyInfo storage buyInfo = _buyInfo[account];
        uint256 buyToken = buyInfo.buyToken;
        require(buyToken > 0 && buyToken == buyInfo.sellToken, "sellBuy");
        uint256 buyUsdt = buyInfo.buyUsdt;
        uint256 sellUsdt = buyInfo.sellUsdt;
        require(buyUsdt > sellUsdt, "noLose");
        INFT nft = INFT(_nftAddress);
        uint256 nftId = nft.tokenOfOwnerByIndex(account, 0);
        nft.transferFrom(account, address(0x000000000000000000000000000000000000dEaD), nftId);
        _recordInfo[account].push(RecordInfo(block.timestamp, buyUsdt - sellUsdt, 0));
        buyInfo.buyUsdt = 0;
        buyInfo.buyToken = 0;
        buyInfo.sellUsdt = 0;
        buyInfo.sellToken = 0;
    }

    function claimReward(uint256 i) external {
        address account = msg.sender;
        uint256 pendingReward = _getPending(account, i);
        if (pendingReward > 0) {
            RecordInfo storage recordInfo = _recordInfo[account][i];
            recordInfo.rewardBalance -= pendingReward;
            recordInfo.claimedReward += pendingReward;
            recordInfo.lastRewardTime = block.timestamp;
            uint256 pendingBuybackToken = tokenAmountOut(pendingReward, _buybackToken);
            _giveReward(account, pendingBuybackToken);
        }
    }

    function _giveReward(address account, uint256 amount) private {
        if (0 == amount) {
            return;
        }
        IERC20 token = IERC20(_buybackToken);
        require(token.balanceOf(address(this)) >= amount, "reward no enough");
        token.transfer(account, amount);
    }
    
    function tokenAmountOut(uint256 usdtAmount, address tokenAddress) public view returns (uint256){
        address lpAddress = _buybackTokenLP;
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(lpAddress);
        uint256 usdtBalance = IERC20(_usdt).balanceOf(lpAddress);
        require(tokenBalance > 0 && usdtBalance > 0, "noUPool");
        return usdtAmount * tokenBalance / usdtBalance;
    }

    function _getPending(address account, uint256 index) private view returns (uint256){
        RecordInfo storage recordInfo = _recordInfo[account][index];
        uint256 rewardBalance = recordInfo.rewardBalance;
        if (0 == rewardBalance) {
            return 0;
        }
        uint256 timestamp = block.timestamp;
        uint256 lastRewardTime = recordInfo.lastRewardTime;
        uint256 pendingReward;
        if (timestamp > lastRewardTime) {
            uint256 times = (timestamp - lastRewardTime) / _dailyDuration;
            uint256 maxTimes = _maxTimes;
            if (times > maxTimes) {
                times = maxTimes;
            }
            uint256 dailyReward;
            uint256 dailyRate = _dailyRate;
            for (uint256 i; i < times;) {
                dailyReward = rewardBalance * dailyRate / 10000;
                rewardBalance -= dailyReward;
                pendingReward += dailyReward;
            unchecked{
                ++i;
            }
            }
        }
        return pendingReward;
    }

    function getRecordLength(address account) public view returns (uint256){
        return _recordInfo[account].length;
    }

    function getRecordInfo(address account, uint256 i) public view returns (
        uint256 lastRewardTime, uint256 rewardBalance, uint256 claimedReward,
        uint256 pendingReward, uint256 nextReleaseCountdown
    ){
        RecordInfo storage recordInfo = _recordInfo[account][i];
        lastRewardTime = recordInfo.lastRewardTime;
        rewardBalance = recordInfo.rewardBalance;
        claimedReward = recordInfo.claimedReward;
        pendingReward = _getPending(account, i);
        rewardBalance -= pendingReward;
        uint256 timeDebt = block.timestamp - lastRewardTime;
        uint256 times = timeDebt / _dailyDuration;
        if (times < _maxTimes) {
            nextReleaseCountdown = _dailyDuration * (times + 1) - timeDebt;
        }
    }

    function getUserAllRecordInfo(address account) public view returns (
        uint256[] memory lastRewardTime, uint256[] memory rewardBalance, uint256[] memory claimedReward,
        uint256[] memory pendingReward, uint256[] memory nextReleaseCountdown
    ){
        uint256 length = _recordInfo[account].length;
        lastRewardTime = new uint256[](length);
        rewardBalance = new uint256[](length);
        claimedReward = new uint256[](length);
        pendingReward = new uint256[](length);
        nextReleaseCountdown = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            (lastRewardTime[i], rewardBalance[i], claimedReward[i], pendingReward[i], nextReleaseCountdown[i]) = getRecordInfo(account, i);
        }
    }

    function getBaseInfo() public view returns (
        address tokenAddress, uint256 tokenDecimals, string memory tokenSymbol,
        address usdtAddress, uint256 usdtDecimals, string memory usdtSymbol,
        address buybackTokenAddress, uint256 buybackTokenDecimals, string memory buybackTokenSymbol,
        address nftAddress
    ){
        tokenAddress = address(this);
        tokenDecimals = _decimals;
        tokenSymbol = _symbol;
        usdtAddress = _usdt;
        usdtDecimals = IERC20(usdtAddress).decimals();
        usdtSymbol = IERC20(usdtAddress).symbol();
        buybackTokenAddress = _buybackToken;
        buybackTokenDecimals = IERC20(buybackTokenAddress).decimals();
        buybackTokenSymbol = IERC20(buybackTokenAddress).symbol();
        nftAddress = _nftAddress;
    }

    function getBuyInfo(address account) public view returns (
        uint256 buyUsdt, uint256 sellUsdt,
        uint256 buyToken, uint256 sellToken, uint256 remainUsdt,
        uint256 tokenBalance, uint256 nftBalance
    ){
        BuyInfo storage buyInfo = _buyInfo[account];
        buyUsdt = buyInfo.buyUsdt;
        sellUsdt = buyInfo.sellUsdt;
        buyToken = buyInfo.buyToken;
        sellToken = buyInfo.sellToken;
        if (buyToken > sellToken) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _usdt;
            uint[] memory amounts = _swapRouter.getAmountsOut(buyToken - sellToken, path);
            remainUsdt = amounts[amounts.length - 1];
        }
        tokenBalance = balanceOf(account);
        nftBalance = INFT(_nftAddress).balanceOf(account);
    }
    
    function setDailyDuration(uint256 duration) external onlyWhiteList {
        _dailyDuration = duration;
    }
    
    function setDailyRate(uint256 dailyRate) external onlyWhiteList {
        _dailyRate = dailyRate;
    }

    function setMaxTimes(uint256 times) external onlyWhiteList {
        _maxTimes = times;
    }

    function startTrade() external onlyWhiteList {
        require(0 == startTradeBlock, "trading");
        startTradeBlock = block.number;
    }
}

contract TAPDAO is AbsToken {
    constructor() AbsToken(
    //SwapRouter
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
    //USDT
        address(0x55d398326f99059fF775485246999027B3197955),
        "TAPDAO",
        "TAPDAO",
        18,
        10000000000,
    //Receive
        address(0x59BEF7be79FbAa02c6795453c5FCd1298a75869C),
    //Fund
        address(0x5ba438712451aB0667098094E33478eD88D3a4eB)
    ){

    }
}