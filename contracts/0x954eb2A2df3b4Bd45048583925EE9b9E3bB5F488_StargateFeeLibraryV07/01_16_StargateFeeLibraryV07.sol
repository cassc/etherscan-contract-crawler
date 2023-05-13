// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/IStargateFeeLibrary.sol";
import "../Pool.sol";
import "../Factory.sol";
import "../interfaces/IStargateLPStaking.sol";
import "../chainlink/interfaces/AggregatorV3Interface.sol";
import "../lzApp/LzApp.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

///@notice Stargate fee library maintains the fees it costs to go from one pool to another across chains
/// The price feeds are eagerly updated by off-chain actors who watch the shouldCallUpdateTokenPrices() and call updateTokenPrice() if required
contract StargateFeeLibraryV07 is LzApp, IStargateFeeLibrary {
    using SafeMath for uint256;

    //---------------------------------------------------------------------------
    // VARIABLES

    // equilibrium func params. all in BPs * 10 ^ 2, i.e. 1 % = 10 ^ 6 units
    uint256 public constant DENOMINATOR = 1e18;
    uint256 public constant DELTA_1 = 6000 * 1e14;
    uint256 public constant DELTA_2 = 500 * 1e14;
    uint256 public constant LAMBDA_1 = 40 * 1e14;
    uint256 public constant LAMBDA_2 = 9960 * 1e14;

    // fee/reward bps
    uint256 public constant LP_FEE = 1 * 1e14;
    uint256 public constant LP_FEE_WITH_EQ_REWARD = 34 * 1e12;
    uint256 public constant PROTOCOL_FEE = 9 * 1e14;
    uint256 public constant PROTOCOL_FEE_FOR_SAME_TOKEN = 5 * 1e14;
    uint256 public constant PROTOCOL_FEE_WITH_EQ_REWARD = 166 * 1e12;
    uint256 public constant EQ_REWARD_CAP = 50 * 1e14;
    uint256 public constant EQ_REWARD_THRESHOLD = 6 * 1e14;
    uint256 public constant PROTOCOL_SUBSIDY = 3 * 1e13;

    uint256 public constant FIFTY_PERCENT = 5 * 1e17;
    uint256 public constant SIXTY_PERCENT = 6 * 1e17;

    // price and state thresholds, may be configurable in the future
    uint8 public constant PRICE_SHARED_DECIMALS = 8; // for price normalization
    uint256 public constant ONE_BPS_PRICE_CHANGE_THRESHOLD = 1 * 1e14;
    uint256 public constant TEN_BPS_PRICE_CHANGE_THRESHOLD = 10 * 1e14;
    uint256 public constant PRICE_DRIFT_THRESHOLD = 10 * 1e14; // 10 bps
    uint256 public constant PRICE_DEPEG_THRESHOLD = 150 * 1e14; // 150 bps

    
    mapping(address => bool) public whitelist;
    mapping(uint256 => uint256) public poolIdToLpId; // poolId -> index of the pool in the lpStaking contract

    Factory public immutable factory;

    // srcPoolId => dstPoolId => PricePair
    mapping(uint256 => mapping(uint256 => PricePair)) public srcPoolIdToDstPoolPrice;

    mapping(uint256 => mapping(uint256 => bool)) public sameToken; // only for protocol fee, poolId -> poolId -> bool
    mapping(uint16 => bytes) public defaultAdapterParams; // for price sync, chainId -> params
    mapping(uint256 => address) public stargatePoolIdToLPStaking;

    enum PriceDeviationState {
        Normal,
        Drift,
        Depeg
    }

    struct PricePair {
        PriceDeviationState state; // default is Normal
        address srcPriceFeedAddress;
        
        address dstPriceFeedAddress; // price feed address of the dstPoolId
        
        uint128 dstCurrentPriceSD; // price of the dstPoolId token in USD
        uint128 srcCurrentPriceSD; // price of the srcPoolId token in USD
        
        uint16[] remoteChainIds; // chainIds of the pools that are connected to the pool
    }

    event PriceUpdated(uint256 indexed srcPoolId, uint256 indexed dstPoolId, uint256 srcPriceSD, uint256 dstPriceSD, PriceDeviationState state);
    event PriceFeedUpdated(uint256 indexed srcPoolId, uint256 indexed dstPoolId, address srcPriceFeedAddress, address dstPriceFeedAddress, uint16[] remoteChainIds);

    modifier notDepeg(uint256 _srcPoolId, uint256 _dstPoolId) {
        if (_srcPoolId != _dstPoolId) {
            require(srcPoolIdToDstPoolPrice[_srcPoolId][_dstPoolId].state != PriceDeviationState.Depeg, "FeeLibrary: _srcPoolId depeg");
        }
        _;
    }

    constructor(
        address _factory,
        address _endpoint
    ) LzApp(_endpoint) {
        require(_factory != address(0x0), "FeeLibrary: Factory cannot be 0x0");
        require(_endpoint != address(0x0), "FeeLibrary: Endpoint cannot be 0x0");

        factory = Factory(_factory);
    }

    // --------------------- ONLY OWNER ---------------------
    function whiteList(address _from, bool _whiteListed) external onlyOwner {
        whitelist[_from] = _whiteListed;
    }

    function setPoolToLpId(uint256 _poolId, uint256 _lpId) external onlyOwner {
        poolIdToLpId[_poolId] = _lpId;
    }

    function setInitPrices(uint128 _srcPoolId, uint128 _dstPoolId, uint128 price) external onlyOwner {
        require(price > 0, "FeeLibrary: _basePriceSD cannot be 0");
        // reset current price and state
        srcPoolIdToDstPoolPrice[_srcPoolId][_dstPoolId].dstCurrentPriceSD = price;
        srcPoolIdToDstPoolPrice[_srcPoolId][_dstPoolId].srcCurrentPriceSD = price; 
        srcPoolIdToDstPoolPrice[_srcPoolId][_dstPoolId].state = PriceDeviationState.Normal;
    }

    // for those chains where to get the price from oracle and sync to other chains
    function setTokenPriceFeeds(
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address _srcPriceFeedAddress,
        address _dstPriceFeedAddress,
        uint16[] calldata _remoteChainIds
    ) external onlyOwner {
        srcPoolIdToDstPoolPrice[_srcPoolId][_dstPoolId].srcPriceFeedAddress = _srcPriceFeedAddress;
        srcPoolIdToDstPoolPrice[_srcPoolId][_dstPoolId].dstPriceFeedAddress = _dstPriceFeedAddress;
        srcPoolIdToDstPoolPrice[_srcPoolId][_dstPoolId].remoteChainIds = _remoteChainIds; 
        emit PriceFeedUpdated(_srcPoolId, _dstPoolId, _srcPriceFeedAddress, _dstPriceFeedAddress, _remoteChainIds);
    }

    function setStargatePoolIdToLPStakingAddress(uint256 _poolId, address _lpStaking) external onlyOwner {
        stargatePoolIdToLPStaking[_poolId] = _lpStaking;
    }

    function setSameToken(uint256 _poolId1, uint256 _poolId2, bool _isSame) external onlyOwner {
        require(_poolId1 != _poolId2, "FeeLibrary: _poolId1 cannot be the same as _poolId2");
        if (_poolId1 < _poolId2) {
            sameToken[_poolId1][_poolId2] = _isSame;
        } else {
            sameToken[_poolId2][_poolId1] = _isSame;
        }
    }

    function setDefaultAdapterParams(uint16 _remoteChainId, bytes calldata _adapterParams) external onlyOwner {
        defaultAdapterParams[_remoteChainId] = _adapterParams;
    }

    // Override the renounce ownership inherited by zeppelin ownable
    function renounceOwnership() public override onlyOwner {}

    // --------------------- PUBLIC FUNCTIONS ---------------------
    ///@notice update the stored token price pair for the associated pool pair
    ///@dev anyone can update and sync price at any time even though the price is not changed
    ///@param _srcPoolId the poolId of the source pool
    ///@param _dstPoolId the poolId of the destination pool
    function updateTokenPrice(uint256 _srcPoolId, uint256 _dstPoolId) external payable {
        PricePair storage currentSrcPriceObj = srcPoolIdToDstPoolPrice[_srcPoolId][_dstPoolId];
        // get new prices from price feed
        (uint256 updatedSrcCurrentPriceSD, uint256 updatedDstCurrentPriceSD) = _getLatestPriceSDFromPriceFeeds(currentSrcPriceObj);
        
        (PriceDeviationState newState,)= _getPriceDeviationStateAndDiff(updatedSrcCurrentPriceSD, updatedDstCurrentPriceSD);
        
        // update price and state
        _updatePricePair(_srcPoolId, _dstPoolId, updatedSrcCurrentPriceSD, updatedDstCurrentPriceSD, newState);

        // sync the price to remote pools
        uint16[] memory remoteChainIds = currentSrcPriceObj.remoteChainIds;
        bytes memory payload = abi.encode(_srcPoolId, _dstPoolId, updatedSrcCurrentPriceSD, updatedDstCurrentPriceSD, newState); 
        
        for (uint256 i = 0; i < remoteChainIds.length; i++) {
            uint16 remoteChainId = remoteChainIds[i];
            address refundAddress = i == remoteChainIds.length - 1? msg.sender : address(this); // refund to msg.sender only for the last call
            
            _lzSend(remoteChainId, payload, payable(refundAddress), address(0), defaultAdapterParams[remoteChainId], address(this).balance);
        }
    }

    // --------------------- VIEW FUNCTIONS ---------------------
    ///@notice get the fees for a swap. typically called from the router via the pool
    function getFees(
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        uint16 _dstChainId,
        address _from,
        uint256 _amountSD
    ) external view override notDepeg(_srcPoolId, _dstPoolId) returns (Pool.SwapObj memory s) {
        // calculate the equilibrium reward
        bool whitelisted = whitelist[_from];
        (s.eqReward, s.protocolFee) = getEqReward(_srcPoolId, _amountSD, whitelisted); // protocol fee is 0 if whitelisted

        // calculate the equilibrium fee
        bool hasEqReward = s.eqReward > 0;
        uint256 protocolSubsidy;
        (s.eqFee, protocolSubsidy) = getEquilibriumFee(_srcPoolId, _dstPoolId, _dstChainId, _amountSD, whitelisted, hasEqReward);

        // calculate protocol and lp fee
        (uint256 protocolFee, uint256 lpFee) = getProtocolAndLpFee(_srcPoolId, _dstPoolId, _dstChainId, _amountSD, protocolSubsidy, whitelisted, hasEqReward);
        s.protocolFee = s.protocolFee.add(protocolFee);
        s.lpFee = lpFee;

        // calculate drift fee
        uint256 driftFee = getDriftFee(_srcPoolId, _dstPoolId, _amountSD, whitelisted);
        s.protocolFee = s.protocolFee.add(driftFee);

        if (_amountSD < s.lpFee.add(s.eqFee).add(s.protocolFee)) {
            s.protocolFee = _amountSD.sub(s.lpFee).sub(s.eqFee);
        }

        return s;
    }

    ///@notice quote fee for price update and sync to remote chains
    ///@dev call this for value to attach to call to update token prices
    function quoteFeeForPriceUpdate(uint256 _srcPoolId, uint256 _dstPoolId) external view returns (uint256) {
        uint256 total = 0;
        uint16[] memory remoteChainIds = srcPoolIdToDstPoolPrice[_srcPoolId][_dstPoolId].remoteChainIds;
        bytes memory payload = abi.encode(_srcPoolId, uint256(0), uint256(0), uint256(0), PriceDeviationState.Normal); // mock the payload
        
        for (uint256 i = 0; i < remoteChainIds.length; i++) {
            uint16 remoteChainId = remoteChainIds[i];
            (uint256 fee, ) = lzEndpoint.estimateFees(remoteChainId, address(this), payload, false, defaultAdapterParams[remoteChainId]);
            total = total.add(fee);
        }
        return total;
    }

    function getEqReward(
        uint256 _srcPoolId,
        uint256 _amountSD,
        bool _whitelisted
    ) public view returns (uint256 eqReward, uint256 protocolFee) {
        Pool pool = factory.getPool(_srcPoolId);
        uint256 currentAssetSD = _getPoolBalanceSD(pool);
        uint256 lpAsset = pool.totalLiquidity();
        uint256 rewardPoolSize = pool.eqFeePool();

        if (lpAsset <= currentAssetSD) {
            return (0, 0);
        }

        uint256 poolDeficit = lpAsset.sub(currentAssetSD);
        uint256 rate = rewardPoolSize.mul(DENOMINATOR).div(poolDeficit);

        if (rate <= EQ_REWARD_THRESHOLD && !_whitelisted) {
            return (0, 0);
        }

        eqReward = _amountSD.mul(rate).div(DENOMINATOR);
        eqReward = eqReward > rewardPoolSize ? rewardPoolSize : eqReward;

        if (_whitelisted) {
            return (eqReward, 0);
        }

        uint256 rewardBps = eqReward.mul(DENOMINATOR).div(_amountSD);
        if (rewardBps > EQ_REWARD_CAP) {
            uint256 cap = _amountSD.mul(EQ_REWARD_CAP).div(DENOMINATOR);
            protocolFee = eqReward.sub(cap);
        } else {
            protocolFee = 0;
        }
    }

    function getEquilibriumFee(
        uint256 srcPoolId,
        uint256 dstPoolId,
        uint16 dstChainId,
        uint256 amountSD,
        bool whitelisted,
        bool hasEqReward
    ) public view returns (uint256, uint256) {
        if (whitelisted) {
            return (0, 0);
        }

        Pool.ChainPath memory chainPath = factory.getPool(srcPoolId).getChainPath(dstChainId, dstPoolId);
        uint256 idealBalance = chainPath.idealBalance;
        uint256 beforeBalance = chainPath.balance;

        require(beforeBalance >= amountSD, "FeeLibrary: not enough balance");
        uint256 afterBalance = beforeBalance.sub(amountSD);

        uint256 safeZoneMax = idealBalance.mul(DELTA_1).div(DENOMINATOR);
        uint256 safeZoneMin = idealBalance.mul(DELTA_2).div(DENOMINATOR);

        uint256 eqFee = 0;
        uint256 protocolSubsidy = 0;
        uint256 amountSD_ = amountSD; // stack too deep

        if (afterBalance >= safeZoneMax) {
            // no fee zone, protocol subsidize it.
            eqFee = amountSD_.mul(PROTOCOL_SUBSIDY).div(DENOMINATOR);
            // no subsidy if has eqReward
            if (!hasEqReward) {
                protocolSubsidy = eqFee;
            }
        } else if (afterBalance >= safeZoneMin) {
            // safe zone
            uint256 proxyBeforeBalance = beforeBalance < safeZoneMax ? beforeBalance : safeZoneMax;
            eqFee = _getTrapezoidArea(LAMBDA_1, 0, safeZoneMax, safeZoneMin, proxyBeforeBalance, afterBalance);
        } else {
            // danger zone
            if (beforeBalance >= safeZoneMin) {
                // across 2 or 3 zones
                // part 1
                uint256 proxyBeforeBalance = beforeBalance < safeZoneMax ? beforeBalance : safeZoneMax;
                eqFee = eqFee.add(_getTrapezoidArea(LAMBDA_1, 0, safeZoneMax, safeZoneMin, proxyBeforeBalance, safeZoneMin));
                // part 2
                eqFee = eqFee.add(_getTrapezoidArea(LAMBDA_2, LAMBDA_1, safeZoneMin, 0, safeZoneMin, afterBalance));
            } else {
                // only in danger zone
                // part 2 only
                uint256 beforeBalance_ = beforeBalance; // Stack too deep
                eqFee = eqFee.add(_getTrapezoidArea(LAMBDA_2, LAMBDA_1, safeZoneMin, 0, beforeBalance_, afterBalance));
            }
        }
        return (eqFee, protocolSubsidy);
    }

    function getProtocolAndLpFee(
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        uint16, // _dstChainId
        uint256 _amountSD,
        uint256 _protocolSubsidy,
        bool _whitelisted,
        bool _hasEqReward
    ) public view returns (uint256, uint256) {
        if (_whitelisted) {
            return (0, 0);
        }

        uint256 protocolFeeBps = _hasEqReward ? PROTOCOL_FEE_WITH_EQ_REWARD :
            isSameToken(_srcPoolId, _dstPoolId) ? PROTOCOL_FEE_FOR_SAME_TOKEN : PROTOCOL_FEE;
        uint256 lpFeeBps = _hasEqReward ? LP_FEE_WITH_EQ_REWARD : LP_FEE;

        uint256 amountSD = _amountSD; // Stack too deep
        uint256 srcPoolId = _srcPoolId;

        uint256 protocolFee = amountSD.mul(protocolFeeBps).div(DENOMINATOR).sub(_protocolSubsidy);
        uint256 lpFee = amountSD.mul(lpFeeBps).div(DENOMINATOR);

        // when there are active emissions, give the lp fee to the protocol
        // lookup LPStaking[Time] address. If it
        address lpStakingAddr = stargatePoolIdToLPStaking[srcPoolId];
        if(lpStakingAddr != address(0x0)){
            IStargateLPStaking lpStaking = IStargateLPStaking(lpStakingAddr);
            (, uint256 allocPoint, , ) = lpStaking.poolInfo(poolIdToLpId[srcPoolId]);
            if (allocPoint > 0) {
                protocolFee = protocolFee.add(lpFee);
                lpFee = 0;
            }
        }
        return (protocolFee, lpFee);
    }

    function getDriftFee(
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        uint256 _amountSD,
        bool _whitelisted
    ) public view returns (uint256) {
        if (_srcPoolId == _dstPoolId || _whitelisted) {
            return 0;
        }
        
        uint256 srcPriceSD = _getTokenPriceSD(_srcPoolId, _dstPoolId);
        uint256 dstPriceSD = srcPoolIdToDstPoolPrice[_srcPoolId][_dstPoolId].dstCurrentPriceSD;
        
        // get absolute difference between srcPriceSD and dstPriceSD
        if (srcPriceSD > dstPriceSD) {            
            return _amountSD.mul(srcPriceSD).div(dstPriceSD).sub(_amountSD);
            
        } 
        return 0;       
    }

    ///@notice offchain function to check if update token prices should be called
    ///@dev typically called by an off-chain watcher and if returns turn updateTokenPrice is called
    ///@param _srcPoolId the source pool id
    ///@param _dstPoolId the destination pool id
    ///@return bool true if updateTokenPrice should be called, false otherwise 
    function shouldCallUpdateTokenPrices(uint256 _srcPoolId, uint256 _dstPoolId) external view returns (bool){ 
        PricePair storage currentSrcToDstPricePair = srcPoolIdToDstPoolPrice[_srcPoolId][_dstPoolId];
        
        (uint256 updatedSrcCurrentPriceSD, uint256 updatedDstCurrentPriceSD) = _getLatestPriceSDFromPriceFeeds(currentSrcToDstPricePair);

        (PriceDeviationState newState,) = _getPriceDeviationStateAndDiff(updatedSrcCurrentPriceSD, updatedDstCurrentPriceSD);

        return _priceUpdateRequired(currentSrcToDstPricePair, newState, updatedSrcCurrentPriceSD, updatedDstCurrentPriceSD);
    }

    function isSameToken(uint256 _poolId1, uint256 _poolId2) public view returns (bool) {
        if (_poolId1 == _poolId2) {
            return true;
        }
        return _poolId1 < _poolId2 ? sameToken[_poolId1][_poolId2] : sameToken[_poolId2][_poolId1];
    }

    function getRemoteChainIds(uint256 _poolId, uint256 _dstPoolId) external view returns (uint16[] memory) {
        return srcPoolIdToDstPoolPrice[_poolId][_dstPoolId].remoteChainIds;
    }

    function getVersion() external pure override returns (string memory) {
        return "7.0.0";
    }

    // --------------------- INTERNAL FUNCTIONS ---------------------
    function _getTrapezoidArea(
        uint256 lambda,
        uint256 yOffset,
        uint256 xUpperBound,
        uint256 xLowerBound,
        uint256 xStart,
        uint256 xEnd
    ) internal pure returns (uint256) {
        require(xEnd >= xLowerBound && xStart <= xUpperBound, "FeeLibrary: balance out of bound");
        uint256 xBoundWidth = xUpperBound.sub(xLowerBound);

        // xStartDrift = xUpperBound.sub(xStart);
        uint256 yStart = xUpperBound.sub(xStart).mul(lambda).div(xBoundWidth).add(yOffset);

        // xEndDrift = xUpperBound.sub(xEnd)
        uint256 yEnd = xUpperBound.sub(xEnd).mul(lambda).div(xBoundWidth).add(yOffset);

        // compute the area
        uint256 deltaX = xStart.sub(xEnd);
        return yStart.add(yEnd).mul(deltaX).div(2).div(DENOMINATOR);
    }

    function _blockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal override {
        (uint256 _srcPoolId, uint256 _dstPoolId, uint256 newSrcCurrentPrice, uint256 newDstCurrentPrice, PriceDeviationState state) = abi.decode(_payload, (uint16, uint256, uint256, uint256, PriceDeviationState));
        _updatePricePair(_dstPoolId, _srcPoolId, newDstCurrentPrice, newSrcCurrentPrice, state); // the switching of the ordering of newDstCurrentPrice and newSrcCurrentPrice here is intentional
    }

    ///@notice calls the price feed to get the latest prices for the price pair and returns their scaled values
    function _getLatestPriceSDFromPriceFeeds(PricePair storage _priceObj) internal view returns (uint256, uint256) {
        return  (_callPriceFeed(_priceObj.srcPriceFeedAddress), _callPriceFeed(_priceObj.dstPriceFeedAddress));
    }

    ///@notice does an external call to the price feed address supplied and returns the scaled price
    function _callPriceFeed(address priceFeedAddress) internal view returns(uint256){
        // get the latest price from the oracle
        require(priceFeedAddress != address(0x0), "FeeLibrary: price feed not set");
        uint8 decimals = AggregatorV3Interface(priceFeedAddress).decimals();
        (, int256 price, , , ) = AggregatorV3Interface(priceFeedAddress).latestRoundData();
        require(price >= 0, "FeeLibrary: price is negative");
        return _scalePrice(uint256(price), decimals);
    }
    
    ///@notice indicates if the price deviation has changed so much to warrant a state update
    function _priceUpdateRequired(PricePair storage currentSrcToDstPricePair, PriceDeviationState newState, uint256 _newSrcPrice, uint256 _newDstPrice)
        internal view returns(bool) {
        
        // if price state is depegged no need to further update the oracle
        if (currentSrcToDstPricePair.state == PriceDeviationState.Depeg && newState == PriceDeviationState.Depeg) {
            return false;
        }
        // if state has changed then price update is required
        if(newState != currentSrcToDstPricePair.state){
            return true;
        }
        uint256 newSrcDiff = _getAbsoluteDiffAsBps(currentSrcToDstPricePair.srcCurrentPriceSD, _newSrcPrice);
        uint256 newDstDiff = _getAbsoluteDiffAsBps(currentSrcToDstPricePair.dstCurrentPriceSD, _newDstPrice);
        uint256 threshold = newState == PriceDeviationState.Drift? ONE_BPS_PRICE_CHANGE_THRESHOLD : TEN_BPS_PRICE_CHANGE_THRESHOLD;
        uint256 maxNewAbsDiff = newSrcDiff > newDstDiff ? newSrcDiff : newDstDiff;
        
        return maxNewAbsDiff >= threshold ? true : false;
    }

    function _getTokenPriceSD(uint256 _srcPoolId, uint256 _dstPoolId) internal view returns (uint256) {
        PricePair storage priceObj = srcPoolIdToDstPoolPrice[_srcPoolId][_dstPoolId];
        return priceObj.state == PriceDeviationState.Normal? _safeGetDstCurrentPriceSD(priceObj) : priceObj.srcCurrentPriceSD;
    }

    ///@notice simply storages the price pair state and emits an event
    function _updatePricePair(uint256 _srcPoolId, uint _dstPoolId, uint256 _srcPriceSD, uint256 _dstPriceSD, PriceDeviationState _newState) internal {
        PricePair storage priceObj = srcPoolIdToDstPoolPrice[_srcPoolId][_dstPoolId];
        
        priceObj.srcCurrentPriceSD = uint128(_srcPriceSD); // todo: consider using safe cast here
        priceObj.dstCurrentPriceSD = uint128(_dstPriceSD);

        if (_newState != priceObj.state) {
            priceObj.state = _newState;
        }
        emit PriceUpdated(_srcPoolId, _dstPoolId, _srcPriceSD, _dstPriceSD, _newState);
    }

    ///@notice looks at the src and dst current prices and determines if the state of the pair is normal, depeg or drift
    function _getPriceDeviationStateAndDiff(uint256 _srcCurrentPriceSD, uint256 _dstCurrentPriceSD) internal pure returns (PriceDeviationState, uint256) {
        // get absolute difference between src current price and dst current price
        uint256 diff = _getAbsoluteDiffAsBps(_srcCurrentPriceSD, _dstCurrentPriceSD);

        if (diff <= PRICE_DRIFT_THRESHOLD) {
            return (PriceDeviationState.Normal, diff);
        } else if (diff >= PRICE_DEPEG_THRESHOLD) {
            return (PriceDeviationState.Depeg, diff);
        } else {
            return (PriceDeviationState.Drift, diff);
        }
    }

    function _scalePrice(uint256 _price, uint8 _decimals) internal pure returns (uint256) {
        if (_decimals == PRICE_SHARED_DECIMALS) {
            return _price;
        }

        uint256 rate = _scaleRate(_decimals, PRICE_SHARED_DECIMALS);
        return _decimals < PRICE_SHARED_DECIMALS ? _price.mul(rate) : _price.div(rate);
    }

    function _getAbsoluteDiffAsBps(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a > _b) {
            return _a.sub(_b).mul(DENOMINATOR).div(_a);
        } 
        else if(_a == _b){
            return 0;
        }
        else {
            return _b.sub(_a).mul(DENOMINATOR).div(_b);
        }
    }

    function _scaleRate(uint8 _decimals, uint8 _sharedDecimals) internal pure returns (uint256) {
        uint256 diff = _decimals > _sharedDecimals? _decimals - _sharedDecimals : _sharedDecimals - _decimals;
        require(diff <= 20, "FeeLibrary: diff of decimals is too large");
        return 10 ** diff;
    }

    function _getPoolBalanceSD(Pool _pool) internal view returns (uint256) {
        return IERC20(_pool.token()).balanceOf(address(_pool)).div(_pool.convertRate());
    }

    function _safeGetDstCurrentPriceSD(PricePair storage _priceObj) internal view returns (uint256 priceSD) {
        priceSD = _priceObj.dstCurrentPriceSD;
        require(priceSD > 0, "FeeLibrary: base price not set"); // todo - do we still need this? since now we are always comparing to the dst token price
    }

    receive() external payable {} // receive ETH from lz endpoint
}