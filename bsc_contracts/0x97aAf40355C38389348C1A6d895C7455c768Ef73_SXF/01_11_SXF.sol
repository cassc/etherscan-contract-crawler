pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interface/ISwapFactory.sol';
import './interface/ISwapRouter.sol';
import './interface/IUniswapV2Pair.sol';
import './interface/IShareManager.sol';

contract TokenDistributor {
    constructor (address usdt) {
        IERC20(usdt).approve(msg.sender, uint(~uint256(0)));
    }
}

contract SXF is ERC20,Ownable {
    using SafeMath for *;
    uint256 MAX = 19800 * 10000 * 1e18;
    address private TEAM_ADDRESS = 0xBbbE23fa9238B6467640056badC006328E4443EE;
    address private CRETER_ADDRESS = 0x5dFA774a1A9d1f13867a4C41ad5CA8A5dDc58b5c;
    address private SELL_ADDRESS = 0xe78Ded7233Cd25046b214640228bc76051B54C3A;

    address private USDT = 0x55d398326f99059fF775485246999027B3197955;
    address private ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address public POOL_MANAGER;
//    address public USDT = 0x9aEE57822bcc5D0fA35AF93c4CA16454df92Ff8f;
//    address public ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;

    address public lpPair;
    mapping(address => bool) public swapPairList;
    mapping(address => bool) public feeWhiteList;

    uint256 public feeCondition = 5 * 1e17;
    bool public lpShareAutoFlag = true;
    uint256 public lpHolderRewardCondition = 10 * 1e17;
    uint256 public lpRewardCurrentIndex;
    uint256 public lpProgressRewardBlock;
    TokenDistributor public tokenDistributor;

    uint256 public REWARD_GAS = 500000;
    function setRewardGas(uint256 value) external onlyOwner {REWARD_GAS = value;}

    constructor() public ERC20('SXF', 'SXF'){
        ISwapRouter swapRouter = ISwapRouter(ROUTER);
        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        lpPair = swapFactory.createPair(address(this), USDT);
        swapPairList[lpPair] = true;

        IERC20(USDT).approve(ROUTER, MAX);
        _approve(address(this), ROUTER, MAX);
        tokenDistributor = new TokenDistributor(USDT);

        feeWhiteList[owner()] = true;
        feeWhiteList[address(this)] = true;
        feeWhiteList[address(tokenDistributor)] = true;
        feeWhiteList[ROUTER] = true;

        feeWhiteList[msg.sender] = true;
        feeWhiteList[0x0000000000000000000000000000000000000001] = true;
        _mint(msg.sender, MAX);
    }

    function burn(uint value) public {
        _burn(msg.sender, value);
    }

    event removeLpPoolEvent(address lp);
    event SwapEvent(uint256 types, uint256 values);
    event TranceEvent(uint256 codes, uint256 add, uint256 remove);

    function transfer(address to, uint value) public override returns (bool) {
        uint transferAmount = transferBase(msg.sender,to,value);
        super.transfer(to, transferAmount);
        return true;
    }

    function transferFrom(address from, address to, uint value) public override returns (bool) {
        uint transferAmount = transferBase(from,to,value);
        super.transferFrom(from, to, transferAmount);
        return true;
    }

    uint256 public backLpHoldTotal;
    uint256 public backCreateTotal;
    uint256 public backSellTotal;
    uint256 public backNftTotal;
    uint256 public backTeamTotal;

    function getTokenFeeTotal() private returns (uint){
        return backLpHoldTotal.add(backCreateTotal).add(backSellTotal).add(backNftTotal).add(backTeamTotal);
    }

    function resetTokenFeeTotal() private {
        backLpHoldTotal = 0;
        backCreateTotal = 0;
        backSellTotal = 0;
        backNftTotal = 0;
        backTeamTotal = 0;
    }

    function takeSellFee(address from, uint value) private returns (uint){
        uint oneAmount = value.mul(1).div(100);
        backLpHoldTotal = backLpHoldTotal.add(oneAmount.mul(2));
        backCreateTotal = backCreateTotal.add(oneAmount);
        backSellTotal = backSellTotal.add(oneAmount);
        backNftTotal = backNftTotal.add(oneAmount);
        backTeamTotal = backTeamTotal.add(oneAmount);
        super._transfer(from, address(this), oneAmount.mul(6));
        return value.sub(oneAmount.mul(6));
    }

    function transferBase(address from,address to,uint value) internal returns (uint){
        require(value > 0, "transfer num error");
        uint transferAmount = value;
        bool isAddLiquidity;
        bool isDelLiquidity;
        ( isAddLiquidity, isDelLiquidity) = _isLiquidity(from,to);
        if(isAddLiquidity || isDelLiquidity){
            emit TranceEvent(999, isAddLiquidity ? 1 : 0, isDelLiquidity ? 1 : 0);
            return value;
        }

        if (swapPairList[from] || swapPairList[to]) {

            if (!feeWhiteList[from] && !feeWhiteList[to]) {
                //SELL
                if(swapPairList[to]){
                    transferAmount = takeSellFee(from, value);
                }
                //BUY
                if(swapPairList[from]){
                    transferAmount = takeSellFee(from, value);
                }
            }
        }else{
            if (!feeWhiteList[from] && !feeWhiteList[to]) {

            }
        }
        if (from != address(this)) {
            if (swapPairList[to]) {
                addHolder(from);
            }
            bool lpHandled = false;
            if(!swapPairList[from]){
                if(getTokenFeeTotal() >= feeCondition){
                    swapTokenToUsdt();
                }

                IERC20 usdtToken = IERC20(USDT);
                uint256 lpShareUsdtBalance = usdtToken.balanceOf(address(this));
                if (lpShareAutoFlag && lpShareUsdtBalance >= lpHolderRewardCondition && block.number > lpProgressRewardBlock + 20) {
                    processHoldLpReward(REWARD_GAS);
                    lpHandled = true;
                }
            }
            if(!lpHandled){
                if(POOL_MANAGER != address(0)){
                    IShareManager(POOL_MANAGER).sendNftReward();
                }
            }
        }
        return transferAmount;
    }

    uint public addPriceTokenAmount = 100;
    function setAddPriceTokenAmount(uint value) public onlyOwner {
        addPriceTokenAmount = value;
    }

    function _isLiquidity(address from,address to)internal view returns(bool isAdd,bool isDel){
        address token0 = IUniswapV2Pair(lpPair).token0();
        (uint r0,,) = IUniswapV2Pair(lpPair).getReserves();
        uint bal0 = IERC20(token0).balanceOf(lpPair);
        if( swapPairList[to] ){
            if( token0 != address(this) && bal0 > r0 ){
                isAdd = bal0 - r0 > addPriceTokenAmount;
            }
        }
        if( swapPairList[from] ){
            if( token0 != address(this) && bal0 < r0 ){
                isDel = r0 - bal0 > 0;
            }
        }
    }

    function swapTokenToUsdt() private lockTheSwap {
        bool hasLiquidity = IERC20(lpPair).totalSupply() > 1000;
        if(!hasLiquidity){
            return;
        }
        uint256 tokenAmount = getTokenFeeTotal();

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        ISwapRouter(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(tokenDistributor), block.timestamp);
        IERC20 usdtToken = IERC20(USDT);

        uint256 newUsdtBalance = usdtToken.balanceOf(address(tokenDistributor));
        emit SwapEvent(7, newUsdtBalance);

        uint256 backLpHoldUsdt = newUsdtBalance.mul(backLpHoldTotal).div(tokenAmount);
        uint256 backCreateUsdt = newUsdtBalance.mul(backCreateTotal).div(tokenAmount);
        uint256 backSellUsdt = newUsdtBalance.mul(backSellTotal).div(tokenAmount);
        uint256 backNftUsdt = newUsdtBalance.mul(backNftTotal).div(tokenAmount);
        uint256 backTeamUsdt = newUsdtBalance.mul(backTeamTotal).div(tokenAmount);

        if(POOL_MANAGER != address(0)){
            usdtToken.transferFrom(address(tokenDistributor), POOL_MANAGER, backNftUsdt);
            IShareManager(POOL_MANAGER).addReawdAmount(backNftUsdt);
        }else{
            usdtToken.transferFrom(address(tokenDistributor), address(owner()), backNftUsdt);
        }
        usdtToken.transferFrom(address(tokenDistributor), TEAM_ADDRESS, backTeamUsdt);
        usdtToken.transferFrom(address(tokenDistributor), CRETER_ADDRESS, backCreateUsdt);
        usdtToken.transferFrom(address(tokenDistributor), SELL_ADDRESS, backSellUsdt);
        usdtToken.transferFrom(address(tokenDistributor), address(this), usdtToken.balanceOf(address(tokenDistributor)));
        resetTokenFeeTotal();
    }

    function approveAddLiq() public onlyOwner {
        _approve(address(this), ROUTER, uint(~uint256(0)));
        IERC20(USDT).approve(ROUTER, uint(~uint256(0)));
    }

    bool private inSwap;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    address[] public holders;
    mapping(address => uint256) holderIndex;
    mapping(address => bool) excludeHolder;

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

    function processHoldLpReward(uint256 gas) private {
        IERC20 usdtToken = IERC20(USDT);
        uint256 lpShareUsdtBalance = usdtToken.balanceOf(address(this));
        uint256 shareholderCount = holders.length;
        IERC20 holdToken = IERC20(lpPair);
        uint holdTokenTotal = holdToken.totalSupply();
        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        while (gasUsed < gas && iterations < shareholderCount) {
            if (lpRewardCurrentIndex >= shareholderCount) {
                lpRewardCurrentIndex = 0;
            }
            shareHolder = holders[lpRewardCurrentIndex];
            tokenBalance = holdToken.balanceOf(shareHolder);

            if (tokenBalance > 0 && !excludeHolder[shareHolder]) {
                amount = lpShareUsdtBalance * tokenBalance / holdTokenTotal;
                if (amount > 0) {
                    usdtToken.transfer(shareHolder, amount);
                }
            }
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            lpRewardCurrentIndex++;
            iterations++;
        }
        lpProgressRewardBlock = block.number;
    }

    function adminProcessHoldLpReward() public onlyOwner {
        swapTokenToUsdt();
    }

    function adminProcessHoldLpReward2(uint256 gas) public onlyOwner {
        processHoldLpReward(gas);
    }

    function setLpShareAutoFlag(bool enable) external onlyOwner {
        lpShareAutoFlag = enable;
    }

    function setFeeCondition(uint256 value) external onlyOwner {
        feeCondition = value;
    }

    function setLpHolderRewardCondition(uint256 value) external onlyOwner {
        lpHolderRewardCondition = value;
    }

    function setPoolManager(address value) external onlyOwner {
        POOL_MANAGER = value;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        feeWhiteList[addr] = enable;
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        swapPairList[addr] = enable;
    }

    function sendTokenTo(address token, address user, uint256 amount) public onlyOwner payable
    {
        IERC20(token).transfer(user, amount);
    }

//    function sendLpBatchTest(address[] memory userList) public onlyOwner payable
//    {
//        uint256 balance = IERC20(lpPair).balanceOf(address(this));
//        uint256 amount = balance.div(userList.length);
//        for(uint256 i = 0; i < userList.length; i++) {
//            addHolder(userList[i]);
//            IERC20(lpPair).transfer(userList[i], amount);
//        }
//    }
}