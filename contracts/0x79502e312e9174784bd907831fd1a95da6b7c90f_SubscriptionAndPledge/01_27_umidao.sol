// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./utils/OracleLibrary.sol";
import "./utils/IERC20.sol";
import "./utils/SafeMath.sol";
import "./utils/SafeERC20.sol";
import "./utils/Ownable.sol";
import "./utils/PoolAddress.sol";
import "./utils/univ3api.sol";
import "./utils/Math.sol";
import "./utils/IERC721.sol";
import "./utils/IERC721Receiver.sol";

interface xynft{
    function addWhiteList(address _addr) external;
    function isWhiteList(address _user) external view returns (bool) ;
}

struct BondInfo {
    uint256 takedAmount;
    uint256 startDay;
    uint256 origAmount;
    uint256   discount;
    bool    isLP;
}

struct LpStakeInfo {
    uint256 tokenid;
    uint256 lockedAmount;
    uint256 startDay;
    uint8 stakePeriod; 
}

contract LPTokenWrapper is IERC721Receiver {
    using SafeMath for uint256;
    IERC721 public uniSwapNft;
    uint256[4] _totalSupply;
    mapping(address=>mapping(uint8=>LpStakeInfo[])) lpStakeInfos;

    uint8 constant ONE_MONTH_TYPE = 0;
    uint8 constant THREE_MONTH_TYPE = 1;
    uint8 constant SIX_MONTH_TYPE = 2;
    uint8 constant ONE_YEAR_TYPE = 3;
    event OnNFTTokenReceived(address indexed _operator, address indexed _from, uint256 _tokenId, bytes _data);
    event TokenSingleStaked(address indexed _from, uint256 _amount, uint16 _period);
    event LpStaked(address indexed _from, uint256 _tokenId, uint8 _period, uint256 _amount1, uint256 _amount2);
    event Bonded(address indexed _from, uint256 _amount);
    event EthBonded(address indexed _from, uint256 _amount);
    event WithdrawAllLP(address indexed _from, uint256 _amount);
    event WithdrawAndLP(address indexed _from, uint256 _amount);
    event WithdrawBond(address indexed _from, uint256 _amount);
    
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) override external returns (bytes4) {

        emit OnNFTTokenReceived(operator, from, tokenId, data);

        return IERC721Receiver.onERC721Received.selector;
    }

    function getLpInfos(address _holder, uint8 _lockType) public view returns (LpStakeInfo[] memory) {
        return lpStakeInfos[_holder][_lockType];
    }

    function totalSupply() public view returns (uint256[4] memory) {
        return _totalSupply;
    }

    function balanceOf(address account, uint8 _lockType) public view returns (uint256) {
        uint256 balance = 0;
        for(uint256 i = 0;i < lpStakeInfos[account][_lockType].length; i ++) {
            balance = balance.add(lpStakeInfos[account][_lockType][i].lockedAmount);
        }
        return balance;
    }

    function toUint128(uint256 x) internal pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }
}

struct LockInfo {
    uint256 totalReward;
    uint256 daoStartDay;
}

contract SubscriptionAndPledge is LPTokenWrapper, univ3sdk, Ownable{
    
    address public uniswapV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address public _quoteToken ;
    address public _baseToken ;
    address public _wethToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public _pool;

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IERC20 outToken;
    IERC20 usdcToken;
    address pool1;
    LockInfo public lockinfo;

    uint8 BONDS_RATE = 9;
    uint8 BONDS_LP_RATE = 18;

    uint256 constant Day30Duration = 86400 * 30;
    uint256 constant Day90Duration = 86400 * 90;
    uint256[3] daoDiscount = [90, 95, 98];

    uint16[4]  periods = [30, 90, 182, 365];
    uint8[4]   lprates = [9, 12, 15, 20];

    uint256 benefit = 100 * 10 ** 8; 
    uint256 MaxStakeAmount = 50000 * 10 ** 8; 
    uint256 minStakeAmount = 1000 * 10 ** 8;
    uint256 minBondAmount = 2000 * 10 ** 8;
    uint256 highBondAmount = 5000 * 10 ** 8;
    uint256 maxBondAmount = 50000 * 10 ** 8;
    uint256 public totalBondAmount = 0;
    uint32 constant period = 1000;

    mapping(address=>BondInfo) bondInfos; 
    xynft public daoNFT = xynft(0x8E22d541dEe9CcF303a6870f775C3A5d4A2D8A7D);

    constructor(address _quote, address _base) {
        uniSwapNft = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
        _quoteToken = _quote;
        _baseToken  = _base; 
        outToken = IERC20(_quoteToken);
        usdcToken = IERC20(_baseToken);
        _pool = PoolAddress.computeAddress(PoolAddress.getPoolKey(_quoteToken, _baseToken, 3000));
        
    }

    function getDaoNFT() public view returns (address) {
        return address(daoNFT);
    }

    function updateUsdc(address _usdc) public onlyOwner {
        _baseToken = _usdc;
        usdcToken  = IERC20(_usdc);
    }

    function updateQuote(address _quote) public onlyOwner {
        _quoteToken = _quote;
        outToken = IERC20(_quoteToken);
    }

    function updateNFT(address _nft) public onlyOwner {
        daoNFT = xynft(_nft);
    }

    function updateDaoDiscount(uint256 _dis1, uint256 _dis2, uint256 _dis3) public onlyOwner {
        daoDiscount[0] = _dis1;
        daoDiscount[1] = _dis2;
        daoDiscount[2] = _dis3;
    }

    function getDaoDiscount() public view returns(uint256, uint256, uint256) {
        return (daoDiscount[0], daoDiscount[1], daoDiscount[2]);
    }

    function updateLpRate(uint8 _r1, uint8 _r2, uint8 _r3, uint8 _r4) public onlyOwner  {
        lprates = [_r1, _r2, _r3, _r4];
    }

    function getLpRates() public view returns (uint8[4] memory) {
        return lprates;
    }

    function exchange(uint32 _period, address _inToken, uint128 _inAmount, address _outToken) public view  returns (uint256) {
        int24 tick;
        uint128 harmonicMeanLiquidity;
        (tick,harmonicMeanLiquidity) = OracleLibrary.consult(_pool, _period);
        return OracleLibrary.getQuoteAtTick(tick, _inAmount, _inToken, _outToken);
    }

    function generalExchange(uint32 _period, address _inToken, uint128 _inAmount, address _outToken) public view  returns (uint256) {
        int24 tick;
        uint128 harmonicMeanLiquidity;
        address weth2usdcPool = PoolAddress.computeAddress(PoolAddress.getPoolKey(_outToken, _inToken, 3000));
        
        (tick,harmonicMeanLiquidity) = OracleLibrary.consult(weth2usdcPool, _period);
        return OracleLibrary.getQuoteAtTick(tick, _inAmount, _inToken, _outToken);
    }

    function setBenefitAmount(uint256 _amount) public onlyOwner {
        benefit = _amount * 10 ** 8;
    }

    function setMaxStakeAmount(uint256 _amount) public onlyOwner {
        MaxStakeAmount = _amount * 10 ** 8;
    }

    function setBondAmount(uint256 _min, uint256 _high) public onlyOwner {
        minBondAmount = _min * 10 ** 8;
        highBondAmount = _high * 10 ** 8;
    }

    function notifyRewardAmount(uint256 _reward, address _pool1)
    external
    onlyOwner
    {
        require(_reward > 0, "_reward is zero");
        lockinfo.totalReward = _reward * 1e8;
        lockinfo.daoStartDay = block.timestamp;
        pool1  = _pool1;
        outToken.safeTransferFrom(msg.sender, address(this), _reward * 1e8);
    }
    
    function withdrawFunds(uint256 _amount) public onlyOwner {
        require(outToken.balanceOf(address(this)) > 0, "contract does'nt have enough token");
        outToken.transfer(msg.sender, _amount);
    }

    function _bonds(uint128 _amount, bool isU) private returns (uint256)  {
        require(bondInfos[msg.sender].origAmount <= 0, "user already bonded");
        require(lockinfo.daoStartDay > 0 && block.timestamp > lockinfo.daoStartDay, "dao does't start");
        require(_amount >= minBondAmount, "usdc token transferd less than min");
        require(_amount <= maxBondAmount, "usdc token transferd out of range");
        require(usdcToken.balanceOf(msg.sender) >= _amount, "user's usdc not enough!");
        uint256 umiAmount = _amount;

        if(isU) {
            usdcToken.safeTransferFrom(msg.sender, pool1, _amount);
        }
        
        uint256 durationDays = block.timestamp - lockinfo.daoStartDay;

        uint256 discount = 0;
        if(durationDays <= Day30Duration) {
            discount = daoDiscount[0];

        } else if (durationDays > Day30Duration && durationDays <= Day90Duration) {
            discount = daoDiscount[1];
        } else {
            discount = daoDiscount[2];
        }
        umiAmount = umiAmount.mul(100);
        umiAmount = umiAmount.div(discount).mul(1e8).div(quote2usdc(100000000)).mul(109).div(100).add(benefit);

        BondInfo memory bondinfo = BondInfo(0, block.timestamp, umiAmount, discount, false);
        bondInfos[msg.sender] = bondinfo;

        totalBondAmount = totalBondAmount.add(umiAmount);
        _addWhiteList(msg.sender);
        emit Bonded(msg.sender,  _amount);

        return discount;
    }

    function bonds(uint128 _amount) public returns (bool) {
        _bonds(_amount, true);
        return true;
    }

    function _bondsLP(uint128 _amount, bool isU) private returns (uint256)  {
        require(bondInfos[msg.sender].origAmount <= 0, "user already bonded");
        require(lockinfo.daoStartDay > 0 && block.timestamp > lockinfo.daoStartDay, "dao does't start");
        require(_amount >= highBondAmount, "usdc token transferd less than min");
        require(_amount <= maxBondAmount, "usdc token transferd out of range");
        require(usdcToken.balanceOf(msg.sender) >= _amount, "user's usdc not enough!");
        uint256 umiAmount = _amount;
        uint256 durationDays = block.timestamp - lockinfo.daoStartDay;
        uint256 discount = 0;
        if(durationDays <= Day30Duration) {
            discount = daoDiscount[0];
        } else if (durationDays > Day30Duration && durationDays <= Day90Duration) {
            discount = daoDiscount[1];
        } else {
            discount = daoDiscount[2];
        }
        umiAmount = umiAmount.mul(2).mul(118).mul(1e8).div(quote2usdc(100000000).mul(discount.add(100))).add(benefit);
        BondInfo memory bondinfo = BondInfo(0, block.timestamp, umiAmount, discount, true);
        bondInfos[msg.sender] = bondinfo;
        if(isU) {
            usdcToken.safeTransferFrom(msg.sender, pool1, _amount);
        }
        totalBondAmount = totalBondAmount.add(umiAmount);
        _addWhiteList(msg.sender);

        emit Bonded(msg.sender,  _amount);

        return discount;
    }
    function bondsLP(uint128 _amount) public returns (bool) {
        _bondsLP(_amount, true);
        return true;
    }

    function getBonds(address _holder) public view returns (BondInfo memory) {
        return bondInfos[_holder];
    }

    function queryLpByTokenId(uint256 _tokenId) public view returns (uint256, uint256) {
        return getAmountsForLiquidityNew(_tokenId);
    }

    function stakeLP(uint256 _tokenId, uint8 _lockType) public returns (bool) {
        require(_tokenId > 0, "0 amount can not stake");
        require(_lockType == SIX_MONTH_TYPE || _lockType == ONE_YEAR_TYPE, "LP stake only support 6 month or 12 month");
        
        (uint256 usdcAmount, uint256 umiAmount) = getAmountsForLiquidityNew(_tokenId);

        uniSwapNft.safeTransferFrom(msg.sender, address(this), _tokenId, "");
        uint256 _amount = usdc2quote(toUint128(usdcAmount));
        LpStakeInfo memory stakeinfo = LpStakeInfo(_tokenId, _amount.add(umiAmount), block.timestamp, _lockType);
        lpStakeInfos[msg.sender][_lockType].push(stakeinfo);
        _totalSupply[_lockType] = _totalSupply[_lockType].add(_amount.add(umiAmount));

        _addWhiteList(msg.sender);
        emit LpStaked(msg.sender, _tokenId, _lockType, umiAmount, usdcAmount);

        return true;
    }

    function stakeSingle(uint256 _amount, uint8 _lockType) public returns (bool) {
        require(_amount >= minStakeAmount, "token for stake not enough");
        require(_amount <= outToken.balanceOf(msg.sender), "user' balance not enough");
        require(_lockType == ONE_MONTH_TYPE || _lockType == THREE_MONTH_TYPE, "singe token stake's type must 0 or 1");
        LpStakeInfo memory stakeinfo = LpStakeInfo(0, _amount, block.timestamp, _lockType);
        lpStakeInfos[msg.sender][_lockType].push(stakeinfo);

        outToken.safeTransferFrom(msg.sender, address(this), _amount);
        _totalSupply[_lockType] = _totalSupply[_lockType].add(_amount);

        emit TokenSingleStaked(msg.sender, _amount, periods[_lockType]);
        return true;
    }

    function withdrawLP(uint8 _lockType) public returns (bool) {
        require(_lockType <= 3, "lock type out of range");
        return _withdrawLP(_lockType);
    }

    function canWithDrawLP(uint8 _lockType, uint256 _stakeDays) internal view returns (bool) {
        if(_lockType == SIX_MONTH_TYPE || _lockType == ONE_YEAR_TYPE) {
            if(_stakeDays < periods[_lockType]) {
                return false;
            }
        }
        return true;
    }

    function _withdrawLP(uint8 _lockType) private returns (bool) {
        LpStakeInfo[] storage stakeinfos = lpStakeInfos[msg.sender][_lockType];
        
        uint256 unlockAmount = 0;
        uint256 rewardAmount = 0;
        for(uint256 i = 0; i < stakeinfos.length; i ++) {
            uint256 stakeDays = getStakeDays(stakeinfos[i].startDay);
            require(canWithDrawLP(_lockType, stakeDays),  "LP' duration not enough!");
            if(stakeinfos[i].tokenid > 0) {
                if(stakeinfos[i].lockedAmount > 0) {
                    uniSwapNft.safeTransferFrom(address(this), msg.sender, stakeinfos[i].tokenid);
                }
            } else {
                unlockAmount = unlockAmount.add(stakeinfos[i].lockedAmount); 
            }
            if(stakeDays >= periods[stakeinfos[i].stakePeriod]) {
                rewardAmount = stakeinfos[i].lockedAmount.mul(lprates[stakeinfos[i].stakePeriod]).mul(stakeDays).div(365).div(100).add(rewardAmount);

            } 
        }
        delete lpStakeInfos[msg.sender][_lockType];
        outToken.safeTransfer(msg.sender, rewardAmount.add(unlockAmount));

        emit WithdrawAllLP(msg.sender, rewardAmount.add(unlockAmount));
        return true;
    }

    function withdrawLPandLP(uint8 _lockType) public returns (bool) {
        return _withdrawLPandLP(_lockType);
    }

    function _withdrawLPandLP(uint8 _lockType) private returns (bool) {
        LpStakeInfo[] storage stakeinfos = lpStakeInfos[msg.sender][_lockType];
        
        uint256 rewardAmount = 0;
        for(uint256 i = 0; i < stakeinfos.length; i ++) {
            uint256 stakeDays = getStakeDays(stakeinfos[i].startDay);

            if(stakeinfos[i].lockedAmount > 0) {
                if(stakeDays >= periods[stakeinfos[i].stakePeriod]) {
                    rewardAmount = stakeinfos[i].lockedAmount.mul(lprates[stakeinfos[i].stakePeriod]).mul(stakeDays).div(365).div(100).add(rewardAmount);
                }
                stakeinfos[i].startDay = block.timestamp;
            }
            
            
        }
        outToken.safeTransfer(msg.sender, rewardAmount);
        emit WithdrawAndLP(msg.sender, rewardAmount);
        return true;
    }

    function withdrawBonds() public returns (bool) {
        _withdrawBonds();

        return true;
    }

    function _withdrawBonds() private  {
        BondInfo storage bondinfo = bondInfos[msg.sender];
        (uint256 unlockAmount,  ) = _getBondsReward(bondinfo);
        bondinfo.takedAmount = bondinfo.takedAmount.add(unlockAmount);
        outToken.safeTransfer(msg.sender, unlockAmount);
        emit WithdrawBond(msg.sender, unlockAmount);
    }

    function getStakeDays(uint256 _start) private view returns (uint256) {
        if(block.timestamp <= _start) {
            return 0;
        } 
        return block.timestamp.sub(_start) .div( 86400);
    }

    function getLpLineReward(address _holder, uint8 _lockType) public view returns (uint256[4] memory stakedAmount, uint256[4] memory realRewardAmount, uint256[4] memory targetRewardAmount, uint256 startDay, uint8 lockType) {
        require(_lockType <= 3, "lock type out of range");
        LpStakeInfo[] memory stakeinfos = lpStakeInfos[_holder][_lockType];
        
        for(uint256 i = 0; i < stakeinfos.length; i ++) {
            uint256 stakeDays = getStakeDays(stakeinfos[i].startDay);
            stakedAmount[stakeinfos[i].stakePeriod] = stakedAmount[stakeinfos[i].stakePeriod].add(stakeinfos[i].lockedAmount);

            if(stakeDays >= periods[stakeinfos[i].stakePeriod]) {

                realRewardAmount[stakeinfos[i].stakePeriod] = stakeinfos[i].lockedAmount.mul(lprates[stakeinfos[i].stakePeriod]).mul(stakeDays).div(365).div(100).add(realRewardAmount[stakeinfos[i].stakePeriod]);
            } 

            uint256 targetDays = Math.max(stakeDays, periods[stakeinfos[i].stakePeriod]);
            targetRewardAmount[stakeinfos[i].stakePeriod] = stakeinfos[i].lockedAmount.mul(lprates[stakeinfos[i].stakePeriod]).mul(targetDays).div(365).div(100).add(targetRewardAmount[stakeinfos[i].stakePeriod]);
            startDay = stakeinfos[i].startDay;
            lockType = stakeinfos[i].stakePeriod;
        }
    }

    function _getBondsReward(BondInfo memory bondinfo) private view returns (uint256 unlockAmount,  uint256 leftAmount) {
       
        uint256 stakeDays = getStakeDays(bondinfo.startDay);

        if(bondinfo.isLP == false) {
            unlockAmount = 0;
            if(stakeDays >= 182 && stakeDays < 182 + 120) {
                unlockAmount = stakeDays.sub(182).div(30).mul(bondinfo.origAmount).div(10).add(bondinfo.origAmount.mul(40).div(100));
            } else if(stakeDays >= 182 + 120) {
                unlockAmount = bondinfo.origAmount;
            }
            leftAmount = bondinfo.origAmount.sub(unlockAmount);
            unlockAmount = unlockAmount.sub(bondinfo.takedAmount);
            

        } else if(bondinfo.isLP == true) {
            unlockAmount = 0;
            if(stakeDays >= 182 && stakeDays < 182 + 120) {
                unlockAmount = stakeDays.sub(182).div(30).mul(bondinfo.origAmount).div(10).add(bondinfo.origAmount.mul(40).div(100));
            } else if(stakeDays >= 182 + 120) {
                unlockAmount = bondinfo.origAmount;
            }
            leftAmount = bondinfo.origAmount.sub(unlockAmount);
            unlockAmount = unlockAmount.sub(bondinfo.takedAmount);
        }
        
    }

    function getBondsReward(address _holder) public view returns (uint256 unlockAmount,  uint256 leftAmount, uint256 takedAmount, uint256 origAmount, uint256 discount, uint256 startDay, bool isLP){
        BondInfo memory bondinfo = bondInfos[_holder];
        (unlockAmount, leftAmount) = _getBondsReward(bondinfo);
        takedAmount = bondinfo.takedAmount;
        origAmount  = bondinfo.origAmount;
        discount    = bondinfo.discount;
        startDay    = bondinfo.startDay;
        isLP        = bondinfo.isLP;
    }


    function usdc2quote(uint128 _inAmount) public view returns (uint256) {

        return exchange(period, _baseToken, _inAmount, _quoteToken); 
    }

    function quote2usdc(uint128 _inAmount) public view returns (uint256) {
        return exchange(period, _quoteToken, _inAmount, _baseToken); 
    }
    
    function weth2usdc(uint128 _inAmount) public view returns (uint256) {
        return generalExchange(period, _wethToken, _inAmount, _baseToken); 
    }

    function getAmountsForLiquidityNew(uint256 tokenId) public view override returns(uint256 amount0, uint256 amount1){
        (
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
        ) = getLiquidty(tokenId);
        if(token0 == _quoteToken) {
            (amount1, amount0) = getAmountsForLiquidity(token0,token1,fee,tickLower,tickUpper,liquidity);
        } else {
            (amount0, amount1) = getAmountsForLiquidity(token0,token1,fee,tickLower,tickUpper,liquidity);
        }
    }
    
    function _addWhiteList(address _sender) private {
        daoNFT.addWhiteList(_sender);
    }
}