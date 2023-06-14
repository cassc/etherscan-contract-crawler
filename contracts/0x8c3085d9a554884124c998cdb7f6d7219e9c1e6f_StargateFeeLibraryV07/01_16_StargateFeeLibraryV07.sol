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
/// The price feeds are eagerly updated by off-chain actors who watch the shouldCallUpdateTokenPrices() and call updateTokenPrices() if required
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
    uint256 public constant PROTOCOL_FEE = 9 * 1e14;
    uint256 public constant PROTOCOL_FEE_FOR_SAME_TOKEN = 5 * 1e14;
    uint256 public constant EQ_REWARD_THRESHOLD = 6 * 1e14;
    uint256 public constant PROTOCOL_SUBSIDY = 3 * 1e13;

    // price and state thresholds, may be configurable in the future
    uint8 public constant PRICE_SHARED_DECIMALS = 8; // for price normalization
    uint256 public constant ONE_BPS_PRICE_CHANGE_THRESHOLD = 1 * 1e14;
    uint256 public constant PRICE_DRIFT_THRESHOLD = 10 * 1e14; // 10 bps
    uint256 public constant PRICE_DEPEG_THRESHOLD = 150 * 1e14; // 150 bps

    mapping(address => bool) public whitelist;
    mapping(uint256 => uint256) public poolIdToLpId; // poolId -> index of the pool in the lpStaking contract

    Factory public immutable factory;

    mapping(uint256 => address) public poolIdToPriceFeed; // poolId -> priceFeed
    // poolId1 -> poolId2 -> remoteChainIds, poolId1 < poolId2
    mapping(uint256 => mapping(uint256 => uint16[])) internal poolPairToRemoteChainIds;
    mapping(uint256 => uint256) public poolIdToPriceSD; // poolId -> price in shared decimals
    mapping(uint16 => bytes) public defaultAdapterParams; // for price sync, chainId -> params
    mapping(uint256 => address) public stargatePoolIdToLPStaking;

    enum PriceDeviationState {
        Normal,
        Drift,
        Depeg
    }

    event PriceUpdated(uint256 indexed poolId, uint256 priceSD);

    modifier notSamePool(uint256 _poolId1, uint256 _poolId2) {
        require(_poolId1 != _poolId2, "FeeLibrary: _poolId1 == _poolId2");
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

    // for those chains where to get the price from oracle and sync to other chains
    function setTokenPriceFeed(uint256 _poolId, address _priceFeedAddress) external onlyOwner {
        poolIdToPriceFeed[_poolId] = _priceFeedAddress;
    }

    function setStargatePoolIdToLPStakingAddress(uint256 _poolId, address _lpStaking) external onlyOwner {
        stargatePoolIdToLPStaking[_poolId] = _lpStaking;
    }

    function initTokenPrice(uint256 _poolId, uint256 _priceSD) external onlyOwner {
        poolIdToPriceSD[_poolId] = _priceSD;
        emit PriceUpdated(_poolId, _priceSD);
    }

    function setRemoteChains(
        uint256 _poolId1,
        uint256 _poolId2,
        uint16[] calldata _remoteChainIds
    ) external onlyOwner notSamePool(_poolId1, _poolId2) {
        if (_poolId1 < _poolId2) {
            poolPairToRemoteChainIds[_poolId1][_poolId2] = _remoteChainIds;
        } else {
            poolPairToRemoteChainIds[_poolId2][_poolId1] = _remoteChainIds;
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
    ///@param _poolId1 one pool id of the pool pair
    ///@param _poolId2 the other pool id of the pool pair
    function updateTokenPrices(uint256 _poolId1, uint256 _poolId2) external payable notSamePool(_poolId1, _poolId2) {
        // get new prices from price feed
        uint256 newPrice1 = _getLatestPriceSDFromPriceFeed(_poolId1);
        uint256 newPrice2 = _getLatestPriceSDFromPriceFeed(_poolId2);

        // store the new prices
        poolIdToPriceSD[_poolId1] = newPrice1;
        poolIdToPriceSD[_poolId2] = newPrice2;
        emit PriceUpdated(_poolId1, newPrice1);
        emit PriceUpdated(_poolId2, newPrice2);

        // sync the prices to remote pools
        uint16[] memory remoteChainIds = getRemoteChains(_poolId1, _poolId2);
        require(remoteChainIds.length > 0, "FeeLibrary: invalid pool pair");

        bytes memory payload = abi.encode(_poolId1, newPrice1, _poolId2, newPrice2);
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
    ) external view override returns (Pool.SwapObj memory s) {
        // calculate the equilibrium reward
        bool whitelisted = whitelist[_from];
        s.eqReward = getEqReward(_srcPoolId, _amountSD, whitelisted); // protocol fee is 0 if whitelisted

        // calculate the equilibrium fee
        bool hasEqReward = s.eqReward > 0;
        uint256 protocolSubsidy;
        (s.eqFee, protocolSubsidy) = getEquilibriumFee(_srcPoolId, _dstPoolId, _dstChainId, _amountSD, whitelisted, hasEqReward);

        // calculate protocol and lp fee
        (s.protocolFee, s.lpFee) = getProtocolAndLpFee(_srcPoolId, _dstPoolId, _dstChainId, _amountSD, protocolSubsidy, whitelisted);

        // cap the reward at the sum of protocol fee and lp fee by increasing the protocol fee
        if (!whitelisted) {
            uint256 rewardCap = s.protocolFee.add(s.lpFee);
            if (s.eqReward > rewardCap) {
                uint256 diff = s.eqReward.sub(rewardCap);
                s.protocolFee = s.protocolFee.add(diff);
            }
        }

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
    function quoteFeeForPriceUpdate(uint256 _poolId1, uint256 _poolId2) external view notSamePool(_poolId1, _poolId2) returns (uint256) {
        uint256 total = 0;
        uint16[] memory remoteChainIds = getRemoteChains(_poolId1, _poolId2);
        require(remoteChainIds.length > 0, "FeeLibrary: invalid pool pair");
        bytes memory payload = abi.encode(_poolId1, uint256(0), _poolId2, uint256(0)); // mock the payload
        for (uint256 i = 0; i < remoteChainIds.length; i++) {
            uint16 remoteChainId = remoteChainIds[i];
            (uint256 fee, ) = lzEndpoint.estimateFees(remoteChainId, address(this), payload, false, defaultAdapterParams[remoteChainId]);
            total = total.add(fee);
        }
        return total;
    }

    ///@notice function to check if update token prices should be called
    ///@dev typically called by an off-chain watcher and if returns true updateTokenPrices is called
    ///@param _poolId1 one pool id of the pool pair
    ///@param _poolId2 the other pool id of the pool pair
    ///@return bool true if updateTokenPrice should be called, false otherwise
    function shouldCallUpdateTokenPrices(uint256 _poolId1, uint256 _poolId2) external view notSamePool(_poolId1, _poolId2) returns (bool) {
        // current price and state
        uint256 currentPriceSD1 = poolIdToPriceSD[_poolId1];
        uint256 currentPriceSD2 = poolIdToPriceSD[_poolId2];
        (PriceDeviationState currentState, uint256 currentDiff, bool currentLt) = _getPriceDiffAndDeviationState(currentPriceSD1, currentPriceSD2);

        // new price and state
        uint256 newPriceSD1 = _getLatestPriceSDFromPriceFeed(_poolId1);
        uint256 newPriceSD2 = _getLatestPriceSDFromPriceFeed(_poolId2);
        (PriceDeviationState newState, uint256 newDiff, bool newLt) = _getPriceDiffAndDeviationState(newPriceSD1, newPriceSD2);

        // if state has changed then price update is required
        if (currentState != newState) {
            return true;
        }

        // 1. if state keeps normal, then no need to update
        // 2. if state is drift or depeg, but the token with higher price has changed, then update is required
        // 3. if state is depeg and the token with higher price has not changed, then no need to update
        if (newState == PriceDeviationState.Normal) {
            return false;
        } else if (currentLt != newLt) {
            return true;
        } else if (newState == PriceDeviationState.Depeg) {
            return false;
        }

        // if state is drift and the difference is not less than 1bps, then update is required
        uint256 diffDelta = newDiff > currentDiff ? newDiff.sub(currentDiff) : currentDiff.sub(newDiff);
        return diffDelta >= ONE_BPS_PRICE_CHANGE_THRESHOLD;
    }

    function getEqReward(
        uint256 _srcPoolId,
        uint256 _amountSD,
        bool _whitelisted
    ) public view returns (uint256) {
        Pool pool = factory.getPool(_srcPoolId);
        uint256 currentAssetSD = _getPoolBalanceSD(pool);
        uint256 lpAsset = pool.totalLiquidity();
        uint256 rewardPoolSize = pool.eqFeePool();

        if (lpAsset <= currentAssetSD) {
            return 0;
        }

        uint256 poolDeficit = lpAsset.sub(currentAssetSD);
        uint256 rate = rewardPoolSize.mul(DENOMINATOR).div(poolDeficit);

        if (rate <= EQ_REWARD_THRESHOLD && !_whitelisted) {
            return 0;
        }

        uint256 eqReward = _amountSD.mul(rate).div(DENOMINATOR);
        eqReward = eqReward > rewardPoolSize ? rewardPoolSize : eqReward;

        return eqReward;
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
        bool _whitelisted
    ) public view returns (uint256, uint256) {
        if (_whitelisted) {
            return (0, 0);
        }

        uint256 protocolFeeBps = _srcPoolId == _dstPoolId ? PROTOCOL_FEE_FOR_SAME_TOKEN : PROTOCOL_FEE;
        uint256 amountSD = _amountSD; // Stack too deep
        uint256 srcPoolId = _srcPoolId;

        uint256 protocolFee = amountSD.mul(protocolFeeBps).div(DENOMINATOR).sub(_protocolSubsidy);
        uint256 lpFee = amountSD.mul(LP_FEE).div(DENOMINATOR);

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
        if (_srcPoolId == _dstPoolId) {
            return 0;
        }

        // get current prices and state
        uint256 srcPriceSD = poolIdToPriceSD[_srcPoolId];
        uint256 dstPriceSD = poolIdToPriceSD[_dstPoolId];
        (PriceDeviationState state, , bool lt) = _getPriceDiffAndDeviationState(srcPriceSD, dstPriceSD);

        // there is no drift fee if
        // 1. state is normal
        // 2. swap from high price to low price
        if (!lt || state == PriceDeviationState.Normal) {
            return 0;
        }

        require(state != PriceDeviationState.Depeg, "FeeLibrary: _srcPoolId depeg");

        // if whitelisted, then no drift fee
        if (_whitelisted) {
            return 0;
        }

        uint256 amountSDAfterFee = _amountSD.mul(srcPriceSD).div(dstPriceSD);
        return _amountSD.sub(amountSDAfterFee);
    }

    function getRemoteChains(uint256 _poolId1, uint256 _poolId2) public view returns (uint16[] memory) {
        if (_poolId1 < _poolId2) {
            return poolPairToRemoteChainIds[_poolId1][_poolId2];
        } else {
            return poolPairToRemoteChainIds[_poolId2][_poolId1];
        }
    }

    function getVersion() external pure override returns (string memory) {
        return "7.1.0";
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
        (uint256 poolId1, uint256 priceSD1, uint256 poolId2, uint256 priceSD2) = abi.decode(_payload, (uint256, uint256, uint256, uint256));
        poolIdToPriceSD[poolId1] = priceSD1;
        poolIdToPriceSD[poolId2] = priceSD2;
        emit PriceUpdated(poolId1, priceSD1);
        emit PriceUpdated(poolId2, priceSD2);
    }

    ///@notice does an external call to the price feed address supplied and returns the scaled price
    function _getLatestPriceSDFromPriceFeed(uint256 _poolId) internal view returns (uint256) {
        address priceFeed = poolIdToPriceFeed[_poolId];
        require(priceFeed != address(0x0), "FeeLibrary: price feed not set");

        uint8 decimals = AggregatorV3Interface(priceFeed).decimals();
        (, int256 price, , ,) = AggregatorV3Interface(priceFeed).latestRoundData();
        require(price >= 0, "FeeLibrary: price is negative");
        return _scalePrice(uint256(price), decimals);
    }

    ///@notice looks at the two prices and determines if the state of the pair is normal, depeg or drift
    function _getPriceDiffAndDeviationState(uint256 _priceSD1, uint256 _priceSD2) internal pure returns (PriceDeviationState, uint256, bool) {
        // get absolute difference between the two prices
        (uint256 diff, bool lt) = _getAbsoluteDiffAsBps(_priceSD1, _priceSD2);

        PriceDeviationState state;
        if (diff <= PRICE_DRIFT_THRESHOLD) {
            state = PriceDeviationState.Normal;
        } else if (diff >= PRICE_DEPEG_THRESHOLD) {
            state = PriceDeviationState.Depeg;
        } else {
            state = PriceDeviationState.Drift;
        }

        return (state, diff, lt);
    }

    function _scalePrice(uint256 _price, uint8 _decimals) internal pure returns (uint256) {
        if (_decimals == PRICE_SHARED_DECIMALS) {
            return _price;
        }

        uint256 rate = _scaleRate(_decimals, PRICE_SHARED_DECIMALS);
        return _decimals < PRICE_SHARED_DECIMALS ? _price.mul(rate) : _price.div(rate);
    }

    /// @notice returns the absolute difference between two numbers as bps
    /// @return the absolute difference between two numbers as bps
    /// @return true if _a < _b, false otherwise
    function _getAbsoluteDiffAsBps(uint256 _a, uint256 _b) internal pure returns (uint256, bool) {
        if (_a > _b) {
            return (_a.sub(_b).mul(DENOMINATOR).div(_a), false);
        } else if (_a == _b) {
            return (0, false);
        } else {
            return (_b.sub(_a).mul(DENOMINATOR).div(_b), true);
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

    receive() external payable {} // receive ETH from lz endpoint
}