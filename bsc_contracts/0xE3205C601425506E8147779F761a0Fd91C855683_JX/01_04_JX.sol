// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC20StandardToken.sol";
import "./Ownable.sol";
import "./IPancake.sol";

interface IDividendPayingToken {
    function distributeDividends(uint256 amount) external;
}
interface IERC721 {
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
}

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

contract TempUSDTPool is Ownable {

    IERC20 public c_usdt;

    function initial(IERC20 c) external onlyOwner {
        c_usdt = c;
        c.approve(owner(), type(uint256).max);
    }

    function updateUSDTallowance() external {
        c_usdt.approve(owner(), type(uint256).max);
    }
}

contract JX is ERC20StandardToken, Ownable {
    IPancakeRouter02 public immutable uniswapV2Router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address private constant usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public immutable usdtPair;
    uint256 public minRemainAmount = 10**12;

    struct UserLPInfo {
        uint256 lpAmountTotalRecord;
        uint256 lpAmountLocked;
    }
    mapping(address => UserLPInfo) private userLPInfos;
    uint256 public immutable startReleaseTime = block.timestamp;
    uint256 public constant oneDaySeconds = 86400;
    uint256 public constant releaseRate = 100;

    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public holdAmountNoLimit;

    uint256 public constant tradingEnabledTimestampWhiteList = 1679497380;
    uint256 public constant tradingEnabledTimestampNormal = 1679497431;
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public lpPool;
    IDividendPayingToken public c_jx;
    IDividendPayingToken public c_lp;

    TempUSDTPool public tempUSDTPool;
    uint256 public constant maxHoldAmount = 10*10**18;

    uint256 public currentIndex;
    uint256 public minPeriod = 600;
    uint256 public dividendAtAmount = 10**18;
    uint256 public lastTimeDividend;
    uint256 public distributorGas = 500000;
    IERC721 public constant c_nft = IERC721(0xAf725aB87a3bF510A4F32BE0bDa6ae53E28E1910);
    uint256 public constant minHoldLP1500 = 1500*10**18;

    mapping(address => uint256) public nftReward;

    constructor(string memory symbol_, string memory name_, uint8 decimals_, uint256 totalSupply_) ERC20StandardToken(symbol_, name_, decimals_, totalSupply_) {
        usdtPair = IPancakeFactory(uniswapV2Router.factory()).createPair(address(this), usdt);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        IERC20(usdt).approve(address(uniswapV2Router), type(uint256).max);
        tempUSDTPool = new TempUSDTPool();
        tempUSDTPool.initial(IERC20(usdt));

        holdAmountNoLimit[address(0)] = true;
        holdAmountNoLimit[address(0x000000000000000000000000000000000000dEaD)] = true;
        holdAmountNoLimit[usdtPair] = true;
        holdAmountNoLimit[0xE4Cf21f1e16AD9C29cf588042915D3F43CB21dc7] = true;
        isExcludedFromFees[0xE4Cf21f1e16AD9C29cf588042915D3F43CB21dc7] = true;
    }

    function setMP(uint256 mp) external onlyOwner {
        minPeriod = mp;
    }
    function setDA(uint256 da) external onlyOwner {
        dividendAtAmount = da;
    }
    function setDG(uint256 dg) external onlyOwner {
        distributorGas = dg;
    }
    function setlpPool(address p, address jxd, address lpd) external onlyOwner {
        lpPool = p;
        c_jx = IDividendPayingToken(jxd);
        c_lp = IDividendPayingToken(lpd);
        holdAmountNoLimit[jxd] = true;
        holdAmountNoLimit[p] = true;
    }
    function setExcludeFee(address a, bool b) external onlyOwner {
        isExcludedFromFees[a] = b;
    }
    function setEMu(address[] calldata addrs, bool b) external onlyOwner {
        uint256 len = addrs.length;
        for(uint256 i; i < len; ++i) {
            isExcludedFromFees[addrs[i]] = b;
        }
    }
    function setH(address a, bool b) external onlyOwner {
        holdAmountNoLimit[a] = b;
        require(a != usdtPair, "cannot limit");
    }

    function initLPAmount(address[] calldata addrs, uint256 lpAmount) external onlyOwner {
        uint256 len = addrs.length;
        for(uint256 i; i < len; ++i) {
            userLPInfos[addrs[i]].lpAmountTotalRecord = lpAmount;
            userLPInfos[addrs[i]].lpAmountLocked = lpAmount;
        }
    }
    function updateLPAmount(address addr, uint256 lpAmountTotalRecord, uint256 lpAmountLocked) external onlyOwner {
        userLPInfos[addr].lpAmountTotalRecord = lpAmountTotalRecord;
        userLPInfos[addr].lpAmountLocked = lpAmountLocked;
    }
    function addLPAmount(address addr, uint256 amount) external {
        require(lpPool == msg.sender, "invalid msgsender");
        userLPInfos[addr].lpAmountTotalRecord += amount;
    }

    function subLPAmount(address addr, uint256 amount) external {
        require(lpPool == msg.sender, "invalid msgsender");
        checkUserLPinfo(addr, amount);
        userLPInfos[addr].lpAmountTotalRecord -= amount;
    }

    function getRealTransferAmount(address from, uint256 amount) public view returns(uint256) {

        if(holdAmountNoLimit[from]) {
            return amount;
        }

        uint256 balance = balanceOf(from);
        uint256 maxTransferAmount;

        if (balance > minRemainAmount) {
            maxTransferAmount = balance - minRemainAmount;
        }else{
            return 0;
        }

        if (maxTransferAmount > amount) {
            return amount;
        }else{
            return maxTransferAmount;
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if(from == address(this) || to == address(this)) {
            super._transfer(from, to, amount);
            return;
        }
        uint256 realTransferAmount = getRealTransferAmount(from, amount);

        bool takeFee = false;
        if(from == usdtPair){
            uint256 lr = irl(realTransferAmount);
            if (lr > 0) {
                checkUserLPinfo(to, lr);
                userLPInfos[to].lpAmountTotalRecord -= lr;
            }else{
                require(block.timestamp >= tradingEnabledTimestampWhiteList, "not open w");
                takeFee = true;
            }
        }else if(to == usdtPair){
            uint256 la = ial(realTransferAmount);
            if (la > 0) {
                userLPInfos[from].lpAmountTotalRecord += la;
            }else{
                require(block.timestamp >= tradingEnabledTimestampWhiteList, "not open w");
                takeFee = true;
            }
        }

        if(isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(takeFee){
            pba(from, to, realTransferAmount);
        }else{
            super._transfer(from, to, realTransferAmount);
        }

        if(!holdAmountNoLimit[to]){
            require(maxHoldAmount >= balanceOf(to), "max hold");
        }

        if (balanceOf(address(this)) >= dividendAtAmount && lastTimeDividend+minPeriod <= block.timestamp) {
            distribute(distributorGas);
        }
    }

    function distribute(uint256 gas) public {
        uint256 contractBalance = balanceOf(address(this));
        uint256 holderCount = c_nft.totalSupply();
        if (holderCount < 3) return;

        uint256 gasUsed;
        uint256 gasLeft = gasleft();
        uint256 iterations;
        uint256 totalPoint = 57+holderCount;
        uint256 ci = currentIndex;

        while (gasUsed < gas && iterations < holderCount) {
            if (ci >= holderCount) {
                ci = 0;
            }

            address curAddr = c_nft.ownerOf(ci);
            uint256 point = 1;
            if(ci < 3){
                point = 20;
            }else if(!holdEnoughLP(curAddr)) {
                point = 0;
            }

            if(point != 0) {
                uint256 amount = contractBalance * point/totalPoint;
                if(maxHoldAmount >= balanceOf(curAddr) + amount ) {
                    super._transfer(address(this), curAddr, amount);
                    nftReward[curAddr] += amount;
                }
            }
            
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
            ++ci;
            ++iterations;
        }
        currentIndex = ci;
        lastTimeDividend = block.timestamp;
    }

    function holdEnoughLP(address addr) public view returns(bool) {
        uint256 lpBalance = IPancakePair(usdtPair).balanceOf(addr);
        (uint256 rOther, , ) = getReserves();

        uint256 t = IPancakePair(usdtPair).totalSupply();
        return lpBalance*rOther >= t*minHoldLP1500;
    }

    function pba(address from, address to, uint256 realTransferAmount) private {
        _subSenderBalance(from, realTransferAmount);
        require(block.timestamp > tradingEnabledTimestampNormal, "not open");
        if(block.timestamp <= tradingEnabledTimestampNormal + 9){
            unchecked{
                uint256 feeAmount = realTransferAmount*99/100;
                _addReceiverBalance(from, deadAddress, feeAmount);
                _addReceiverBalance(from, to, realTransferAmount - feeAmount);
            }
            return;
        }
        if(from == usdtPair){
            uint256 feeAmount = realTransferAmount/100;
            _addReceiverBalance(from, address(c_jx), feeAmount);
            c_jx.distributeDividends(feeAmount);
            _addReceiverBalance(from, address(this), feeAmount);
            _addReceiverBalance(from, to, realTransferAmount - 2*feeAmount);
            return;
        }
        uint256 feeAmount = realTransferAmount/50;
        _addReceiverBalance(from, address(this), feeAmount);
        uint256 liquidity = swapAndLiquify(feeAmount);
        c_lp.distributeDividends(liquidity);
        _addReceiverBalance(from, to, realTransferAmount - feeAmount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private returns(uint256) {
        uint256 half = contractTokenBalance/2;
        uint256 otherHalf = contractTokenBalance - half;
        uint256 usdtAmount = swapTokensForUSDT(half);
        return addLiquidity(otherHalf, usdtAmount);
    }

    function swapTokensForUSDT(uint256 tokenAmount) private returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;

        uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(
            tokenAmount,
            0,
            path,
            address(tempUSDTPool),
            block.timestamp
        );
        IERC20(usdt).transferFrom(address(tempUSDTPool), address(this), amounts[1]);
        return amounts[1];
    }

    function addLiquidity(uint256 token0Amount, uint256 token1Amount) private returns(uint256 liquidity){
        (, , liquidity) = uniswapV2Router.addLiquidity(
            address(this),
            usdt,
            token0Amount,
            token1Amount,
            0,
            0,
            address(c_lp),
            block.timestamp
        );
    }
    function updateUSDTallowance() external {
        IERC20(usdt).approve(address(uniswapV2Router), type(uint256).max);
        tempUSDTPool.updateUSDTallowance();
    }

    function irl(uint256 amount) public view returns (uint256 liquidity){
        (uint256 rOther, , uint256 balanceOther) = getReserves();
        if (balanceOther <= rOther) {
            liquidity = (amount * IPancakePair(usdtPair).totalSupply())/(balanceOf(usdtPair) - amount);
        }
    }

    function checkUserLPinfo(address to, uint256 liquidityRemoved) private view{
        (uint256 lpAmountTotalRecord, uint256 lpAmountLocked, uint256 lpAmountReleased, uint256 lpBalance) = getUserLPInfo(to);
        if (lpAmountLocked > 0) {
            require(lpAmountLocked <= lpBalance + lpAmountReleased, "lock lp");
        }
        require(lpAmountTotalRecord >= liquidityRemoved, "remove other lp");
    }

    function getUserLPInfo(address addr) public view returns(uint256 lpAmountTotalRecord, uint256 lpAmountLocked, uint256 lpAmountReleased, uint256 lpBalance) {
        lpAmountTotalRecord = userLPInfos[addr].lpAmountTotalRecord;
        lpAmountLocked = userLPInfos[addr].lpAmountLocked;
        
        uint256 daysAfterStart = (block.timestamp - startReleaseTime) / oneDaySeconds;
        lpAmountReleased = lpAmountLocked * (1 + daysAfterStart) * releaseRate / 10000;
        if(lpAmountReleased > lpAmountLocked) {
            lpAmountReleased = lpAmountLocked;
        }
        lpBalance = IERC20(usdtPair).balanceOf(addr);
    }

    function ial(uint256 amount) public view returns (uint256 liquidity){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = getReserves();
        uint256 amountOther;
        if (rOther > 0 && rThis > 0) {
            amountOther = amount * rOther / rThis;
        }
        if (balanceOther >= rOther + amountOther) {
            amountOther = balanceOther - rOther;
            liquidity = calLiquidity(amountOther, amount, rOther, rThis);
        }
    }

    function calLiquidity(uint256 amountOther, uint256 amountThis, uint256 rOther, uint256 rThis) public view returns (uint256 liquidity) {
        uint256 t = IPancakePair(usdtPair).totalSupply();
        if (t == 0) {
            liquidity = Math.sqrt(amountOther * amountThis) - 1000;
        } else {
            liquidity = Math.min( (amountOther*t)/rOther, (amountThis*t)/rThis );
        }
    }

    function getReserves() public view returns (uint256 rOther, uint256 rThis, uint256 balanceOther){
        (uint256 r0, uint256 r1,) = IPancakePair(usdtPair).getReserves();
        if (usdt < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }
        balanceOther = IERC20(usdt).balanceOf(usdtPair);
    }
}