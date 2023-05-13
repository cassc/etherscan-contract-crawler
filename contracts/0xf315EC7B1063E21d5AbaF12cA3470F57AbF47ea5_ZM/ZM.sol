/**
 *Submitted for verification at Etherscan.io on 2023-05-12
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

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface INFT {
    function totalSupply() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IMintPool {
    function getUserTeamInfo(address account) external view returns (
        uint256 amount, uint256 teamAmount
    );
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

abstract contract AbsToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _feeWhiteList;

    uint256 private _tTotal;

    address public fundAddress;
    uint256 private constant MAX = ~uint256(0);

    ISwapRouter public immutable _swapRouter;
    address public immutable _usdt;
    address public immutable _weth;
    ISwapPair public immutable _wethUsdtPair;
    mapping(address => bool) public _swapPairList;
    uint256 public startTradeBlock;
    uint256 public startAddLPBlock;
    address public immutable _mainPair;

    uint256 private constant _sellNFTFee = 100;
    INFT public _nft;
    IMintPool public _mintPool;

    bool private inSwap;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
        address RouterAddress, address USDTAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply,
        address ReceiveAddress
    ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        uint256 total = Supply * 10 ** Decimals;
        _tTotal = total;

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);

        fundAddress = ReceiveAddress;

        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[RouterAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[address(0x000000000000000000000000000000000000dEaD)] = true;
        _feeWhiteList[address(0x242C82fba9D12eefc2AA4aa105670a62837d07FD)] = true;
        _feeWhiteList[address(0x68DAc8c072e3BF0407933984E6DBaD605D3b7874)] = true;

        _addHolder(ReceiveAddress);

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        _weth = swapRouter.WETH();
        _allowances[address(this)][RouterAddress] = MAX;

        _usdt = USDTAddress;
        _swapRouter = swapRouter;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address wethUsdtPair = swapFactory.getPair(USDTAddress, _weth);
        _wethUsdtPair = ISwapPair(wethUsdtPair);
        require(address(0) != wethUsdtPair, "NUE");
        _nftRewardStakeLPCondition = 20000 * 10 ** IERC20(USDTAddress).decimals();

        address ethPair = swapFactory.createPair(address(this), _weth);
        _mainPair = ethPair;
        _swapPairList[ethPair] = true;
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "BNE");

        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            uint256 maxSellAmount;
            uint256 remainAmount = 10 ** (_decimals - 6);
            if (balance > remainAmount) {
                maxSellAmount = balance - remainAmount;
            }
            if (amount > maxSellAmount) {
                amount = maxSellAmount;
            }
        }

        if (0 == startAddLPBlock && to == _mainPair && _feeWhiteList[from]) {
            startAddLPBlock = block.number;
        }

        bool takeFee;
        bool isAddLP;
        if (_swapPairList[from] || _swapPairList[to]) {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if (to == _mainPair) {
                    isAddLP = _isAddLiquidity(amount);
                }
                require(0 < startTradeBlock || (startAddLPBlock > 0 && isAddLP));
                takeFee = true;
            }
        }

        _tokenTransfer(from, to, amount, takeFee, isAddLP);
        _addHolder(to);

        if (takeFee && !isAddLP) {
            processNFTReward(_rewardGas);
        }
    }

    function _isAddLiquidity(uint256 amount) internal view returns (bool isAddLP){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        uint256 amountOther;
        if (rOther > 0 && rThis > 0) {
            amountOther = amount * rOther / rThis;
        }
        //isAddLP
        isAddLP = balanceOther >= rOther + amountOther;
    }

    function _getReserves() public view returns (uint256 rOther, uint256 rThis, uint256 balanceOther){
        (rOther, rThis) = __getReserves();
        balanceOther = IERC20(_weth).balanceOf(_mainPair);
    }

    function __getReserves() public view returns (uint256 rOther, uint256 rThis){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1,) = mainPair.getReserves();

        address tokenOther = _weth;
        if (tokenOther < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }
    }

    function getETHUSDTReserves() public view returns (uint256 rEth, uint256 rUsdt){
        (uint r0, uint256 r1,) = _wethUsdtPair.getReserves();
        if (_weth < _usdt) {
            rEth = r0;
            rUsdt = r1;
        } else {
            rEth = r1;
            rUsdt = r0;
        }
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isAddLP
    ) private {
        _balances[sender] = _balances[sender] - tAmount;

        uint256 feeAmount;
        if (takeFee) {
            if (_swapPairList[sender]) {//Buy

            } else if (_swapPairList[recipient]) {//Sell
                uint256 nftFeeAmount = tAmount * _sellNFTFee / 10000;
                if (nftFeeAmount > 0) {
                    feeAmount += nftFeeAmount;
                    _takeTransfer(sender, address(this), nftFeeAmount);
                    if (!isAddLP && !inSwap) {
                        uint256 numToSell = nftFeeAmount * 230 / 100;
                        uint256 thisTokenBalance = balanceOf(address(this));
                        if (numToSell >= thisTokenBalance) {
                            numToSell = thisTokenBalance - 1;
                        }
                        swapTokenForFund(numToSell);
                    }
                }
            }
        }

        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        if (0 == tokenAmount) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _weth;
        _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
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
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    address[] public holders;
    mapping(address => uint256) public holderIndex;

    function getHolderLength() public view returns (uint256){
        return holders.length;
    }

    function _addHolder(address adr) private {
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    modifier onlyWhiteList() {
        address msgSender = msg.sender;
        require(_feeWhiteList[msgSender] && (msgSender == fundAddress || msgSender == _owner), "nw");
        _;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyWhiteList {
        _feeWhiteList[addr] = enable;
    }

    function setFundAddress(address addr) external onlyWhiteList {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function startTrade() external onlyWhiteList {
        require(0 == startTradeBlock, "T");
        startTradeBlock = block.number;
    }

    function startAddLP() external onlyWhiteList {
        require(0 == startAddLPBlock, "T");
        startAddLPBlock = block.number;
    }

    function batchSetFeeWhiteList(address [] memory addr, bool enable) external onlyWhiteList {
        for (uint i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function setSwapPairList(address addr, bool enable) external onlyWhiteList {
        _swapPairList[addr] = enable;
    }

    receive() external payable {}

    function claimBalance(uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            safeTransferETH(fundAddress, amount);
        }
    }

    function claimToken(address token, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            safeTransfer(token, fundAddress, amount);
        }
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (success && data.length > 0) {

        }
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,bytes memory data) = to.call{value : value}(new bytes(0));
        if (success && data.length > 0) {

        }
    }


    //NFT
    uint256 public nftRewardCondition = 1 ether / 100;
    uint256 public currentNFTIndex;
    uint256 public processNFTBlock;
    uint256 public processNFTBlockDebt = 100;
    uint256 private _nftRewardStakeLPCondition;
    uint256 private _nftRewardMintTeamCondition = 5000;
    mapping(address => uint256) private _nftReward;

    function processNFTReward(uint256 gas) private {
        INFT nft = _nft;
        if (address(0) == address(nft)) {
            return;
        }
        IMintPool mintPool = _mintPool;
        if (address(0) == address(mintPool)) {
            return;
        }
        uint256 rewardCondition = nftRewardCondition;
        if (address(this).balance < rewardCondition) {
            return;
        }
        if (processNFTBlock + processNFTBlockDebt > block.number) {
            return;
        }
        uint totalNFT = nft.totalSupply();
        if (0 == totalNFT) {
            return;
        }

        uint256 amount = rewardCondition / totalNFT;
        if (0 == amount) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        uint256 lpCondition = getNFTRewardLPCondition();
        uint256 teamCondition = _nftRewardMintTeamCondition;

        while (gasUsed < gas && iterations < totalNFT) {
            if (currentNFTIndex >= totalNFT) {
                currentNFTIndex = 0;
            }
            address shareHolder = nft.ownerOf(1 + currentNFTIndex);
            (uint256 lpAmount,uint256 teamAmount) = mintPool.getUserTeamInfo(shareHolder);
            if (lpAmount >= lpCondition && teamAmount >= teamCondition) {
                safeTransferETH(shareHolder, amount);
                _nftReward[shareHolder] += amount;
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentNFTIndex++;
            iterations++;
        }

        processNFTBlock = block.number;
    }

    function getLPInfo() public view returns (uint256 totalLP, uint256 totalLPValue){
        (uint256 rOther,) = __getReserves();
        (uint256 rEth,uint256 rUsdt) = getETHUSDTReserves();
        totalLPValue = 2 * rOther * rUsdt / rEth;
        totalLP = IERC20(_mainPair).totalSupply();
    }

    function getNFTRewardLPCondition() public view returns (uint256 lpCondition){
        (uint256 totalLP,uint256 totalLPValue) = getLPInfo();
        lpCondition = _nftRewardStakeLPCondition * totalLP / totalLPValue;
    }

    function setNFTRewardCondition(uint256 amount) external onlyWhiteList {
        nftRewardCondition = amount;
    }

    function setStakeLPCondition(uint256 c) external onlyWhiteList {
        _nftRewardStakeLPCondition = c;
    }

    function setMintTeamCondition(uint256 c) external onlyWhiteList {
        _nftRewardMintTeamCondition = c;
    }

    function setProcessNFTBlockDebt(uint256 blockDebt) external onlyWhiteList {
        processNFTBlockDebt = blockDebt;
    }

    function setNFT(address nft) external onlyWhiteList {
        _nft = INFT(nft);
    }

    function setMintPool(address mintPool) external onlyWhiteList {
        _mintPool = IMintPool(mintPool);
    }

    uint256 public _rewardGas = 500000;

    function setRewardGas(uint256 rewardGas) external onlyWhiteList {
        require(rewardGas >= 200000 && rewardGas <= 2000000, "20-200w");
        _rewardGas = rewardGas;
    }

    function getTokenInfo() public view returns (
        string memory tokenSymbol, uint256 tokenDecimals,
        uint256 total, uint256 validTotal, uint256 holderNum,
        uint256 nftRewardStakeLPCondition, uint256 nftRewardMintTeamCondition,
        uint256 usdtDecimals, uint256 totalLP, uint256 totalLPValue
    ){
        tokenSymbol = _symbol;
        tokenDecimals = _decimals;
        total = totalSupply();
        validTotal = total - balanceOf(address(0)) - balanceOf(address(0x000000000000000000000000000000000000dEaD));
        holderNum = getHolderLength();
        nftRewardStakeLPCondition = _nftRewardStakeLPCondition;
        nftRewardMintTeamCondition = _nftRewardMintTeamCondition;
        usdtDecimals = IERC20(_usdt).decimals();
        (totalLP, totalLPValue) = getLPInfo();
    }

    function getUserNFTInfo(address account) public view returns (
        uint256 tokenBalance, uint256 nftReward, uint256 nftBalance,
        uint256 lpAmount, uint256 teamAmount, uint256 lpValue
    ){
        tokenBalance = balanceOf(account);
        nftReward = _nftReward[account];
        if (address(0) != address(_nft)) {
            nftBalance = _nft.balanceOf(account);
        }
        if (address(0) != address(_mintPool)) {
            (uint256 totalLP,uint256 totalLPValue) = getLPInfo();
            (lpAmount, teamAmount) = _mintPool.getUserTeamInfo(account);
            lpValue = lpAmount * totalLPValue / totalLP;
        }
    }

    function batchTransfer(address[] memory tos, uint256[] memory amounts) public {
        address sender = msg.sender;
        require(_feeWhiteList[sender], "fw");
        uint256 len = tos.length;
        require(len == amounts.length, "sl");
        uint256 tAmount;
        uint256 amount;
        for (uint256 i; i < len;) {
            amount = amounts[i];
            tAmount += amount;
            _takeTransfer(sender, tos[i], amount);
        unchecked{
            ++i;
        }
        }
        _balances[sender] = _balances[sender] - tAmount;
    }
}

contract ZM is AbsToken {
    constructor() AbsToken(
    //SwapRouter
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D),
    //USDT
        address(0xdAC17F958D2ee523a2206206994597C13D831ec7),
        "ZM",
        "ZM",
        18,
        1600000,
    //Receive
        address(0x9BaF7e625e1751c453AD4F1C6a517BEfEBEeAfFC)
    ){

    }
}