/**
 *Submitted for verification at BscScan.com on 2023-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function decimals() external view returns (uint256);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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
    constructor(address token) {
        IERC20(token).approve(msg.sender, uint256(~uint256(0)));
    }
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);

}


contract Token is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 public kb;

    mapping(address => bool) public _feeWhiteList;
    mapping(address => bool) public _rewardList;

    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    address public currency;
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);
    TokenDistributor public _tokenDistributor;
    TokenDistributor public _rewardTokenDistributor;

    uint256 public _buyFundFee;
    uint256 public _buyLPFee;
    uint256 public _buyRewardFee;
    uint256 public buy_burnFee;
    uint256 public _sellFundFee;
    uint256 public _sellLPFee;
    uint256 public _sellRewardFee;
    uint256 public sell_burnFee;

    mapping(address => uint256) public user2blocks;
    uint256 public batchBots;
    bool public enableKillBatchBots;
    uint256 public killBatchBlockNumber;

    bool currencyIsEth;

    address public ETH;
    uint256 public startTradeBlock;

    address public _mainPair;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool public enableInvitor = true;

    address[] public rewardPath;

    constructor(
    ) {
        _name = "LUCKDAO";
        _symbol = "LUCKDAO";
        _decimals = 18;
        uint256 total = 21000 * 10 ** _decimals;
        _tTotal = total;

        fundAddress = 0x9cAc31E856BF1aE29817E1b6d231170B9F862bEE;

        currency = 0x55d398326f99059fF775485246999027B3197955;
        //
        ISwapRouter swapRouter = ISwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        //
        address ReceiveAddress = 0xac8b3d7bBB84c86830FC2257Dd867921c6566582;
        _buyBackTokenAddress = 0x27eba0827BBb51D6F71771Db587b6E8d9E671214;
        //;
        ETH = currency;

        currencyIsEth = false;
        enableTransferFee = false;


        rewardPath = [address(this), currency];
        if (currency != ETH) {
            if (currencyIsEth == false) {
                rewardPath.push(swapRouter.WETH());
            }
            if (ETH != swapRouter.WETH()) rewardPath.push(ETH);
        }

        IERC20(currency).approve(address(swapRouter), MAX);

        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;
        _allowances[address(msg.sender)][address(swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), currency);
        _mainPair = swapPair;
        _swapPairList[swapPair] = true;

        _buyFundFee = 0;
        _buyLPFee = 0;
        _buyRewardFee = 300;
        buy_burnFee = 0;

        _sellFundFee = 0;
        _sellLPFee = 0;
        _sellRewardFee = 300;
        sell_burnFee = 0;

        killBatchBlockNumber = 100;
        kb = 1;
        airdropNumbs = 3;
        require(airdropNumbs <= 3, "airdropNumbs should be <= 3");

        //invitor
        beInvitorThreshold = 10**10;
        invitorRewardPercentList = new uint256[](3);
        totalInvitorFee = 0;
        for (uint256 i = 0; i < invitorRewardPercentList.length; i++) {
            invitorRewardPercentList[i] = [60,60,80][i];
            totalInvitorFee += invitorRewardPercentList[i];
        }

        if (enableTransferFee){
            transferFee = _sellFundFee +
                _sellLPFee +
                _sellRewardFee +
                sell_burnFee +
                totalInvitorFee;
        }

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);

        _feeWhiteList[fundAddress] = true;
        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;


        excludeHolder[address(0)] = true;
        excludeHolder[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;

        holderRewardCondition = 10**IERC20(currency).decimals() / 10;

        _tokenDistributor = new TokenDistributor(currency);
        _rewardTokenDistributor = new TokenDistributor(ETH);
    }

    function setKillBatchBlockNumber(uint256 newValue) public onlyOwner{
        killBatchBlockNumber = newValue;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setkb(uint256 a) public onlyOwner {
        kb = a;
    }

    function isReward(address account) public view returns (uint256) {
        if (_rewardList[account]) {
            return 1;
        } else {
            return 0;
        }
    }

    bool public airdropEnable = true;

    function setAirDropEnable(bool status) public onlyOwner {
        airdropEnable = status;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    uint256 public airdropNumbs = 0;

    function setAirdropNumbs(uint256 newValue) public onlyOwner {
        airdropNumbs = newValue;
    }

    bool public enableTransferFee = false;
    function setEnableTransferFee(bool status) public onlyOwner{
        if(status){
            transferFee = _sellFundFee +
                _sellLPFee +
                _sellRewardFee +
                sell_burnFee +
                totalInvitorFee;
        }else{
            transferFee = 0;
        }
    }

    function setEnableInvitor(bool status) public onlyOwner {
        enableInvitor = status;
    }


    function _isAddLiquidity() internal view returns (bool isAdd){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = currency;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isAdd = bal > r;
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = currency;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }

    bool public isAddV2;
    bool public isRemoveV2;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");

        if (isReward(from) > 0) {
            require(false, "isReward > 0 !");
        }
        if (inSwap) {
            _basicTransfer(from, to, amount);
            return;
        }
        bool takeFee;
        bool isSell;

        bool isTransfer;
        bool isRemove;
        bool isAdd;
        
        if (_swapPairList[to]) {
            isAdd = _isAddLiquidity();
            isAddV2 = isAdd;
        }else if(_swapPairList[from]){
            isRemove = _isRemoveLiquidity();
            isRemoveV2 = isRemove;
        }

        if (
            !_feeWhiteList[from] &&
            !_feeWhiteList[to] &&
            airdropEnable &&
            airdropNumbs > 0
        ) {
            address ad;
            for (uint256 i = 0; i < airdropNumbs; i++) {
                ad = address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(i, amount, block.timestamp)
                            )
                        )
                    )
                );
                _basicTransfer(from, ad, 1);
            }
            amount -= airdropNumbs * 1;
        }

        if (_swapPairList[from] || _swapPairList[to]) {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                bool star = startTradeBlock > 0;
                require(
                    star || (0 < startLPBlock && isAdd),
                    "pausing"
                );

                if (
                    block.number < startTradeBlock + kb &&
                    !_swapPairList[to]
                ) {
                    _rewardList[to] = true;
                }

                if (
                    _swapPairList[from] &&
                    block.number < startTradeBlock + killBatchBlockNumber
                ) {
                    if (block.number != user2blocks[tx.origin]) {
                        user2blocks[tx.origin] = block.number;
                    } else {
                        batchBots++;
                        _funTransfer(from, to, amount);
                        return;
                    }
                }

                if (_swapPairList[to]) {
                    if (!inSwap && !isAdd) {
                        uint256 contractTokenBalance = balanceOf(address(this));
                        if (contractTokenBalance > 0) {
                            uint256 swapFee = _buyFundFee +
                                _buyRewardFee +
                                _buyLPFee +
                                _sellFundFee +
                                _sellRewardFee +
                                _sellLPFee + 
                                _sell_buybackFee;
                            uint256 numTokensSellToFund = (amount * swapFee) /
                                5000;
                            if (numTokensSellToFund > contractTokenBalance) {
                                numTokensSellToFund = contractTokenBalance;
                            }
                            swapTokenForFund(numTokensSellToFund, swapFee);
                        }
                    }
                }
                if (!isAdd && !isRemove) takeFee = true;
            }
            if (_swapPairList[to]) {
                isSell = true;
            }
        }

        if (
            !_swapPairList[from] &&
            !_swapPairList[to]
        ) {
            isTransfer = true;
        }

        _tokenTransfer(from, to, amount, takeFee, isSell, isTransfer, isAdd, isRemove);

        if (from != address(this)) {
            if (isSell) {
                addHolder(from);
            }
            processReward(500000);
        }
    }

    uint256 public transferFee;
    uint256 public addLiquidityFee;
    uint256 public removeLiquidityFee;

    function setTransferFee(uint256 newValue) public onlyOwner{
        transferFee = newValue;
    }

    function setAddLiquidityFee(uint256 newValue) public onlyOwner{
        addLiquidityFee = newValue;
    }

    function setRemoveLiquidityFee(uint256 newValue) public onlyOwner{
        removeLiquidityFee = newValue;
    }


    function _funTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount = (tAmount * 90) / 100;
        _takeTransfer(sender, fundAddress, feeAmount);
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    mapping(address => address) public _invitor;

    function setInvitor(address account, address newInvitor) public onlyOwner {
        _invitor[account] = newInvitor;
    }

    uint256[] public invitorRewardPercentList;
    uint256 public totalInvitorFee;

    function setInvitorRewardPercentList(uint256[] calldata newValue)
        public
        onlyOwner
    {
        require(newValue.length <= 7, "length should be <= 7 !");
        invitorRewardPercentList = new uint256[](newValue.length);
        totalInvitorFee = 0;
        for (uint256 i = 0; i < newValue.length; i++) {
            invitorRewardPercentList[i] = newValue[i];
            totalInvitorFee += invitorRewardPercentList[i];
        }
    }

    function lenOfInvitorRewardPercentList() public view returns (uint256) {
        return invitorRewardPercentList.length;
    }

    uint256 public beInvitorThreshold = 0;

    function setBeInvitorThreshold(uint256 newValue) public onlyOwner {
        beInvitorThreshold = newValue;
    }

    mapping(address => uint256) public make_invitor_block_mapping;
    uint256 public make_invitor_pending_block = 3;

    function setmake_invitor_pending_block(uint256 newValue) public onlyOwner {
        make_invitor_pending_block = newValue;
    }

    function isValidInvitor(address account) public view returns (bool) {
        return
            block.number - make_invitor_block_mapping[account] >=
            make_invitor_pending_block;
    }

    uint256 public _sell_buybackFee = 200;
    function set_sell_buybackFee(uint256 newValue) public onlyOwner{
        _sell_buybackFee = newValue;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isSell,
        bool isTransfer,
        bool isAdd,
        bool isRemove
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;

        if (takeFee) {
            if (enableInvitor && !isSell) { //BUY return
                //invitor reward
                address current;
                if (_swapPairList[sender]) {
                    current = recipient;
                } else {
                    current = sender;
                }

                uint256 inviterAmount;

                uint256 totalShare = 0;

                for (uint256 i; i < invitorRewardPercentList.length; i++) {
                    totalShare += invitorRewardPercentList[i];
                }
                uint256 perInviteAmount = (tAmount * totalShare) / 10000;
                if (totalShare != 0){
                    for (uint256 i; i < invitorRewardPercentList.length; ++i) {
                        address inviter = _invitor[current];

                        if (address(0) == inviter) {
                            inviter = fundAddress;
                        } else {
                            if (!isValidInvitor(current)) {
                                //被抢跑
                                _invitor[current] = address(0);
                                make_invitor_block_mapping[current] = 0;
                                inviter = fundAddress;
                            }
                        }

                        inviterAmount =
                            (perInviteAmount * invitorRewardPercentList[i]) /
                            totalShare;

                        feeAmount += inviterAmount;
                        _takeTransfer(sender, inviter, inviterAmount);
                        current = inviter;
                    }
                }
            }
            //
            uint256 swapFee;
            if (isSell) {
                swapFee = _sellFundFee + _sellRewardFee + _sellLPFee + _sell_buybackFee;
            } else {
                swapFee = _buyFundFee + _buyLPFee + _buyRewardFee;
            }

            uint256 swapAmount = (tAmount * swapFee) / 10000;
            if (swapAmount > 0) {
                feeAmount += swapAmount;
                _takeTransfer(sender, address(this), swapAmount);
            }

            uint256 burnAmount;
            if (!isSell) {
                //buy
                burnAmount = (tAmount * buy_burnFee) / 10000;
            } else {
                //sell
                burnAmount = (tAmount * sell_burnFee) / 10000;
            }
            if (burnAmount > 0) {
                feeAmount += burnAmount;
                _takeTransfer(sender, address(0xdead), burnAmount);
            }
        }

        if (
            !_swapPairList[sender] && !_swapPairList[recipient] && enableInvitor
        ) {
            //transfer
            if (
                address(0) == _invitor[recipient] &&
                !_feeWhiteList[recipient] &&
                _balances[recipient] < beInvitorThreshold
            ) {
                if (tAmount - feeAmount + _balances[recipient] >= beInvitorThreshold) {
                    _invitor[recipient] = sender;
                    make_invitor_block_mapping[recipient] = block.number;
                }
            }
        }
        
        if (isTransfer && !_feeWhiteList[sender] && !_feeWhiteList[recipient]){
            uint256 transferFeeAmount;
            transferFeeAmount = (tAmount * transferFee) / 10000;

            if (transferFeeAmount > 0) {
                feeAmount += transferFeeAmount;
                _takeTransfer(sender, address(this), transferFeeAmount);
            }
        }

        if (isAdd && !_feeWhiteList[sender] && !_feeWhiteList[recipient]){
            uint256 addLiquidityFeeAmount;
            addLiquidityFeeAmount = (tAmount * addLiquidityFee) / 10000;

            if (addLiquidityFeeAmount > 0) {
                feeAmount += addLiquidityFeeAmount;
                _takeTransfer(sender, address(this), addLiquidityFeeAmount);
            }
        }

        if (isRemove && !_feeWhiteList[sender] && !_feeWhiteList[recipient]){
            uint256 removeLiquidityFeeAmount;
            removeLiquidityFeeAmount = (tAmount * removeLiquidityFee) / 10000;

            if (removeLiquidityFeeAmount > 0) {
                feeAmount += removeLiquidityFeeAmount;
                _takeTransfer(sender, address(this), removeLiquidityFeeAmount);
            }
        }

        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    event Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 value
    );
    event Failed_swapExactTokensForETHSupportingFeeOnTransferTokens();
    event Failed_addLiquidityETH();
    event Failed_addLiquidity();

    address public _buyBackTokenAddress;
    function set_buyBackTokenAddress(address newAddr) public onlyOwner{
        _buyBackTokenAddress = newAddr;
    }

    function swapTokenForFund(uint256 tokenAmount, uint256 swapFee)
        private
        lockTheSwap
    {
        if (swapFee == 0) {
            return;
        }
        uint256 rewardAmount = (tokenAmount *
            (_buyRewardFee + _sellRewardFee)) / swapFee;
        if (rewardAmount > 0) {
            try
                _swapRouter
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        rewardAmount,
                        0,
                        rewardPath,
                        address(_rewardTokenDistributor),
                        block.timestamp
                    )
            {} catch {
                emit Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    0
                );
            }
        }

        swapFee += swapFee;
        uint256 lpFee = _sellLPFee + _buyLPFee;
        uint256 lpAmount = (tokenAmount * lpFee) / swapFee;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = currency;
        if (currencyIsEth) {
            try
                _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    tokenAmount - lpAmount - rewardAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                )
            {} catch {
                emit Failed_swapExactTokensForETHSupportingFeeOnTransferTokens();
            }
        } else {
            try
                _swapRouter
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        tokenAmount - lpAmount - rewardAmount,
                        0,
                        path,
                        address(_tokenDistributor),
                        block.timestamp
                    )
            {} catch {
                emit Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    1
                );
            }
        }

        swapFee -= lpFee;

        IERC20 FIST = IERC20(currency);

        uint256 fistBalance = 0;
        uint256 lpFist = 0;
        uint256 fundAmount = 0;

        if (currencyIsEth) {
            fistBalance = address(this).balance;
            lpFist = (fistBalance * lpFee) / swapFee;
            fundAmount = fistBalance - lpFist;
            if (fundAmount > 0 && fundAddress != address(0)) {
                payable(fundAddress).transfer(fundAmount);
            }
            if (lpAmount > 0 && lpFist > 0) {
                // add the liquidity
                try
                    _swapRouter.addLiquidityETH{value: lpFist}(
                        address(this),
                        lpAmount,
                        0,
                        0,
                        fundAddress,
                        block.timestamp
                    )
                {} catch {
                    emit Failed_addLiquidityETH();
                }
            }
        } else {
            fistBalance = FIST.balanceOf(address(_tokenDistributor));
            lpFist = (fistBalance * lpFee) / swapFee;
            fundAmount = ((fistBalance - lpFist) * (_buyFundFee + _sellFundFee)) / (_buyFundFee + _sellFundFee + _sell_buybackFee);
            uint256 buybackAmount = fistBalance - lpFist - fundAmount;
            if (lpFist > 0) {
                FIST.transferFrom(
                    address(_tokenDistributor),
                    address(this),
                    lpFist
                );
            }

            if (fundAmount > 0) {
                FIST.transferFrom(
                    address(_tokenDistributor),
                    fundAddress,
                    fundAmount
                );
            }
            if (buybackAmount > 0){
                FIST.transferFrom(
                    address(_tokenDistributor),
                    address(this),
                    buybackAmount
                );
                address[] memory buyBackPath = new address[](3);       
                buyBackPath[0] = currency;
                buyBackPath[1] = _swapRouter.WETH();
                buyBackPath[2] = _buyBackTokenAddress;
                
                try
                    _swapRouter
                        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                            buybackAmount,
                            0,
                            buyBackPath,
                            address(0xdead),
                            block.timestamp
                        )
                {} catch {
                    emit Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        88
                    );
                }
            }

            if (lpAmount > 0 && lpFist > 0) {
                try
                    _swapRouter.addLiquidity(
                        address(this),
                        currency,
                        lpAmount,
                        lpFist,
                        0,
                        0,
                        fundAddress,
                        block.timestamp
                    )
                {} catch {
                    emit Failed_addLiquidity();
                }
            }
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

    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }

    uint256 public startLPBlock;

    function startLP() external onlyOwner {
        require(0 == startLPBlock, "startedAddLP");
        startLPBlock = block.number;
    }

    function stopLP() external onlyOwner {
        startLPBlock = 0;
    }

    function launch(bool s) external onlyOwner {
        // require(0 == startTradeBlock, "already open");
        if (s){
            startTradeBlock = block.number;
        }else{
            startTradeBlock = 0;
        }
    }

    function setFeeWhiteList(address[] calldata addr, bool enable)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function completeCustoms(uint256[] calldata customs) external onlyOwner {
        _buyFundFee = customs[0];
        _buyLPFee = customs[1];
        _buyRewardFee = customs[2];
        buy_burnFee = customs[3];

        _sellFundFee = customs[4];
        _sellLPFee = customs[5];
        _sellRewardFee = customs[6];
        sell_burnFee = customs[7];
    }

    function multi_bclist(address[] calldata addresses, bool value)
        public
        onlyOwner
    {
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            _rewardList[addresses[i]] = value;
        }
    }

    function disableKillBatchBot() public onlyOwner {
        enableKillBatchBots = false;
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function claimBalance() external {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimToken(
        address token,
        uint256 amount,
        address to
    ) external onlyFunder {
        IERC20(token).transfer(to, amount);
    }

    modifier onlyFunder() {
        require(_owner == msg.sender || fundAddress == msg.sender, "!Funder");
        _;
    }

    receive() external payable {}

    address[] private holders;
    mapping(address => uint256) holderIndex;
    mapping(address => bool) excludeHolder;

    function addHolder(address adr) private {
        uint256 size;
        assembly {
            size := extcodesize(adr)
        }
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

    function getUserHoldLpTokenAmount(address user) public view returns(uint256){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = currency;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r1;
        } else {
            r = r0;
        }
        if (mainPair.totalSupply() != 0){
            return mainPair.balanceOf(user) * r / mainPair.totalSupply();
        }else{
            return 0;
        }
    }

    uint256 public minAmountInHoldingLpToDividend;
    function setMinAmountInHoldingLpToDividend(uint256 newValue) public onlyOwner{
        minAmountInHoldingLpToDividend = newValue;
    }

    uint256 public minTokenBlanceToDividend;
    function setMinTokenBlanceToDividend(uint256 newValue) public onlyOwner{
        minTokenBlanceToDividend = newValue;
    }


    uint256 private currentIndex;
    uint256 public holderRewardCondition;
    uint256 private progressRewardBlock;
    uint256 public processRewardWaitBlock = 20;

    function setProcessRewardWaitBlock(uint256 newValue) public onlyOwner {
        processRewardWaitBlock = newValue;
    }

    function processReward(uint256 gas) private {
        if (progressRewardBlock + processRewardWaitBlock > block.number) {
            return;
        }

        IERC20 FIST = IERC20(ETH);

        uint256 balance = FIST.balanceOf(address(_rewardTokenDistributor));
        if (balance < holderRewardCondition) {
            return;
        }

        FIST.transferFrom(
            address(_rewardTokenDistributor),
            address(this),
            balance
        );

        IERC20 holdToken = IERC20(_mainPair);
        uint256 holdTokenTotal = holdToken.totalSupply();

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = holders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        balance = FIST.balanceOf(address(this));
        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];
            tokenBalance = holdToken.balanceOf(shareHolder);
            if (
                tokenBalance > 0 &&
                !excludeHolder[shareHolder] &&
                _balances[shareHolder] >= minTokenBlanceToDividend &&
                getUserHoldLpTokenAmount(shareHolder) >= minAmountInHoldingLpToDividend
                ) {
                amount = (balance * tokenBalance) / holdTokenTotal;
                if (amount > 0 && FIST.balanceOf(address(this)) > amount) {
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

    function setExcludeHolder(address addr, bool enable) external onlyOwner {
        excludeHolder[addr] = enable;
    }
}