pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interface/ISwapFactory.sol';
import './interface/ISwapRouter.sol';
import './interface/IPoolManager.sol';

contract TokenDistributor {
    constructor (address usdt) {
        //        IERC20(token).approve(msg.sender, uint(~uint256(0)));
        IERC20(usdt).approve(msg.sender, uint(~uint256(0)));
    }
}

contract AToken is ERC20,Ownable {
    using SafeMath for *;
    uint256 MAX = 19800 * 10000 * 1e18;
    address private TEAM_ADDRESS = 0x80D6CA65bfEF32c2bA1038CF50653cddbaC791b5;
    address private BACK_ADDRESS = 0x2888083B439123413ac84B9f273D6C58CCdf5544;
    address private TRANCE_ADDRESS = 0xaC1f1F1B2f40084c1413D6b7CAe7E0DBC5E5F4ee;
    address public POOL_MANAGER = 0x6796A6754D374f7a639DB0799130237c948a7997;

    address private USDT = 0x55d398326f99059fF775485246999027B3197955;
    address private ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public lpPair;
    mapping(address => bool) public swapPairList;
    mapping(address => bool) public feeWhiteList;

    uint256 public tokenFeeTotal;
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

    function transferBase(address from,address to,uint value) internal returns (uint){
        require(value > 0, "transfer num error");
        uint transferAmount = value;
        if (swapPairList[from] || swapPairList[to]) {
            if (!feeWhiteList[from] && !feeWhiteList[to]) {
                //SELL
                if(swapPairList[to]){
                    uint bornAmount = value.mul(1).div(100);
                    uint teamAmount = value.mul(3).div(100);
                    uint toUAmount = bornAmount.add(teamAmount);

                    super._transfer(from, BACK_ADDRESS, bornAmount);
                    tokenFeeTotal = tokenFeeTotal.add(toUAmount);
                    super._transfer(from, address(this), toUAmount);

                    super._transfer(from, TEAM_ADDRESS, teamAmount);
                    transferAmount  = transferAmount.sub(toUAmount.mul(2));
                }
                //BUY
                if(swapPairList[from]){
                    uint teamAmount = value.mul(1).div(100);
                    super._transfer(from, BACK_ADDRESS, teamAmount);
                    transferAmount  = transferAmount.sub(teamAmount);
                }
            }
        }else{
            if (!feeWhiteList[from] && !feeWhiteList[to]) {
                uint teamAmount = value.mul(8).div(100);
                super._transfer(from, TRANCE_ADDRESS, teamAmount);
                transferAmount  = transferAmount.sub(teamAmount);
            }
        }
        if (from != address(this)) {
            if (swapPairList[to]) {
                addHolder(from);
            }
            bool lpHandled = false;
            if(swapSwitch && swapPairList[to]){
                if(tokenFeeTotal >= feeCondition){
                    swapTokenToUsdt(tokenFeeTotal);
                    tokenFeeTotal = 0;
                }

                IERC20 usdtToken = IERC20(USDT);
                uint256 lpShareUsdtBalance = usdtToken.balanceOf(address(this));
                if (lpShareAutoFlag && lpShareUsdtBalance >= lpHolderRewardCondition && block.number > lpProgressRewardBlock + 20) {
                    processHoldLpReward(REWARD_GAS);
                    lpHandled = true;
                }
            }
            if(lpSwitch && !lpHandled){
                if(POOL_MANAGER != address(0)){
                    IPoolManager(POOL_MANAGER).sendNftReward();
                }
            }
        }
        return transferAmount;
    }

    bool public swapSwitch = true;
    function setSwapSwitch(bool value) external onlyOwner {swapSwitch = value;}
    bool public lpSwitch = true;
    function setLpSwitch(bool value) external onlyOwner {lpSwitch = value;}

    function swapTokenToUsdt(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDT;
        ISwapRouter(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(tokenDistributor), block.timestamp);
        IERC20 usdtToken = IERC20(USDT);

        uint256 lpShareUsdtBalance = usdtToken.balanceOf(address(tokenDistributor));
        uint256 teamAmount = lpShareUsdtBalance.mul(3).div(4);
        IPoolManager(POOL_MANAGER).addReawdAmount(teamAmount);
        usdtToken.transferFrom(address(tokenDistributor), address(this), lpShareUsdtBalance.sub(teamAmount));
        usdtToken.transferFrom(address(tokenDistributor), POOL_MANAGER, teamAmount);
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
        swapTokenToUsdt(tokenFeeTotal);
        tokenFeeTotal = 0;
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

}