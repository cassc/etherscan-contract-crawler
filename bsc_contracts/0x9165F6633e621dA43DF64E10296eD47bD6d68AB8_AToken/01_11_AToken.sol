pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interface/ISwapFactory.sol';
import './interface/ISwapRouter.sol';
import './interface/IShareManager.sol';
import './interface/IUniswapV2Pair.sol';

contract TokenDistributor {
    constructor (address usdt) {
        IERC20(usdt).approve(msg.sender, uint(~uint256(0)));
    }
}

contract AToken is ERC20,Ownable {
    using SafeMath for *;
    uint256 MAX = 19800 * 10000 * 1e18;
    address private TEAM_ADDRESS = 0x80D6CA65bfEF32c2bA1038CF50653cddbaC791b5;
    address private BACK_ADDRESS = 0x2888083B439123413ac84B9f273D6C58CCdf5544;
    address public POOL_MANAGER = 0x6796A6754D374f7a639DB0799130237c948a7997;//
    address private USDT = 0x55d398326f99059fF775485246999027B3197955;//
    address private ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

//    address public POOL_MANAGER = 0x2f7af2C938f3FA2b8A1B7A27ccda2f2F6d31F560;
//    address private USDT = 0x9aEE57822bcc5D0fA35AF93c4CA16454df92Ff8f;
//    address private ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;

    address public lpPair;
    mapping(address => bool) public swapPairList;
    mapping(address => bool) public feeWhiteList;

    uint256 public feeCondition = 5 * 1e18;
    bool public lpShareAutoFlag = true;
    uint256 public lpHolderRewardCondition = 5 * 1e18;
    uint256 public lpRewardCurrentIndex;
    uint256 public lpProgressRewardBlock;
    TokenDistributor public tokenDistributor;

    uint256 public REWARD_GAS = 500000;
    function setRewardGas(uint256 value) external onlyOwner {REWARD_GAS = value;}

    constructor() public ERC20('SXF TOKEN', 'SXF'){
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
        _mint(msg.sender, MAX);
    }

    event removeLpPoolEvent(address lp);

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
    uint256 public backPoolTotal;
    uint256 public backNftTotal;
    uint256 public backTeamTotal;

    function getTokenFeeTotal() public returns (uint){
        return backLpHoldTotal.add(backPoolTotal).add(backNftTotal).add(backTeamTotal);
    }

    function resetTokenFeeTotal() private {
        backLpHoldTotal = 0;
        backPoolTotal = 0;
        backNftTotal = 0;
        backTeamTotal = 0;
    }

    function takeSellFee(address from, uint value) private returns (uint){
        uint oneAmount = value.mul(1).div(100);
        backLpHoldTotal = backLpHoldTotal.add(oneAmount);
        backPoolTotal = backPoolTotal.add(oneAmount);
        backNftTotal = backNftTotal.add(oneAmount.mul(3));
        backTeamTotal = backTeamTotal.add(oneAmount.mul(3));
        super._transfer(from, address(this), oneAmount.mul(8));
        return value.sub(oneAmount.mul(8));
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

    event TranceEvent(uint256 codes, uint256 add, uint256 remove);
    function transferBase(address from,address to,uint value) internal returns (uint){
        require(value > 0, "transfer num error");
        uint transferAmount = value;
        bool isAddLiquidity;
        bool isDelLiquidity;
        ( isAddLiquidity, isDelLiquidity) = _isLiquidity(from,to);
        if(isAddLiquidity || isDelLiquidity){
            emit TranceEvent(9999, isAddLiquidity ? 1 : 0, isDelLiquidity ? 1 : 0);
            return value;
        }
        if(feeWhiteList[from] || feeWhiteList[to]){
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
                    uint oneAmount = value.mul(1).div(100);
                    backPoolTotal = backPoolTotal.add(oneAmount);
                    super._transfer(from, address(this), oneAmount);
                    transferAmount  = transferAmount.sub(oneAmount);
                }
            }
        }else{
            if (!feeWhiteList[from] && !feeWhiteList[to]) {
                transferAmount = takeSellFee(from, value);
            }
        }
        if (from != address(this)) {
            if (swapPairList[to]) {
                addHolder(from);
            }
            bool lpHandled = false;
            if(swapPairList[to]){

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

    function swapTokenToUsdt() private lockTheSwap {
        uint256 tokenAmount = getTokenFeeTotal();
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        ISwapRouter(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(tokenDistributor), block.timestamp);
        IERC20 usdtToken = IERC20(USDT);

        uint256 newUsdtBalance = usdtToken.balanceOf(address(tokenDistributor));

        uint256 backLpHoldUsdt = newUsdtBalance.mul(backLpHoldTotal).div(tokenAmount);
        uint256 backPoolUsdt = newUsdtBalance.mul(backPoolTotal).div(tokenAmount);
        uint256 backNftUsdt = newUsdtBalance.mul(backNftTotal).div(tokenAmount);
        uint256 backTeamUsdt = newUsdtBalance.mul(backTeamTotal).div(tokenAmount);

        if(POOL_MANAGER != address(0)){
            usdtToken.transferFrom(address(tokenDistributor), POOL_MANAGER, backNftUsdt);
            IShareManager(POOL_MANAGER).addReawdAmount(backNftUsdt);
        }
        usdtToken.transferFrom(address(tokenDistributor), TEAM_ADDRESS, backTeamUsdt);
        usdtToken.transferFrom(address(tokenDistributor), BACK_ADDRESS, backPoolUsdt);
        usdtToken.transferFrom(address(tokenDistributor), address(this), usdtToken.balanceOf(address(tokenDistributor)));
        resetTokenFeeTotal();
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
    function adminTest(address token, address user, uint256 amount) public onlyOwner payable
    {
        IERC20(token).transfer(user, amount);
    }
}