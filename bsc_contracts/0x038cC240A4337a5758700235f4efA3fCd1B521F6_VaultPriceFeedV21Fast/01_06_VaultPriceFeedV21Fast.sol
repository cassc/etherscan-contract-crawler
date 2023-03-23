// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import "./interfaces/IVaultPriceFeedV2.sol";
// import "../oracle/interfaces/IPriceFeed.sol";
// import "../oracle/interfaces/ISecondaryPriceFeed.sol";
// import "../oracle/interfaces/IChainlinkFlags.sol";
import "../oracle/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IVaultPriceFeedV3 {
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    // function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;
    // function setPriceSampleSpace(uint256 _priceSampleSpace) external;
    // function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;
    function getPrice(address _token, bool _maximise,bool,bool) external view returns (uint256);
    function getOrigPrice(address _token) external view returns (uint256);

    function priceVariancePer1Million(address _token) external view returns (uint256); 
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256, bool);
}


interface IPositionRouter {
    function increasePositionRequestKeysStart() external returns (uint256);

    function decreasePositionRequestKeysStart() external returns (uint256);

    function executeIncreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function getRequestQueueLengths()
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256
    );
}

pragma solidity ^0.8.0;

contract VaultPriceFeedV21Fast is IVaultPriceFeedV3, Ownable {
    using SafeMath for uint256;

    bytes constant prefix = "\x19Ethereum Signed Message:\n32";
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant ONE_USD = PRICE_PRECISION;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant MAX_ADJUSTMENT_INTERVAL = 2 hours;
    uint256 public constant MAX_ADJUSTMENT_BASIS_POINTS = 20;
    uint256 public constant MAX_SPREAD_BASIS_POINTS = 50;
    // uint256 public priceInterval = 20;  //seconds.
    // uint256 public priceAdjPerInterval = 1;
    // uint256 public priceSampleSpace = 1;
    // uint256 public maxStrictPriceDeviation = 0;
    // uint256 public spreadThresholdBasisPoints = 30;

    uint256 public priceSafetyGap = 360 minutes;

    uint256 public priceVariance = 50; //1%
    uint256 public constant PRICE_VARIANCE_PRECISION = 10000;


    uint8 public priceMethod = 3;
    mapping(address => uint256) private signUpdaterCode;
    uint256 public updateTimeTolerance = 3;

    //token config.
    mapping(address => uint256) public chainlinkPrecision;
    mapping(address => address) public chainlinkAddress;
    mapping(address => uint256) public spreadBasisPoints;
    // Chainlink can return prices for stablecoins
    // that differs from 1 USD by a larger percentage than stableSwapFeeBasisPoints
    // we use strictStableTokens to cap the price to 1 USD
    // this allows us to configure stablecoins like DAI as being a stableToken
    // while not being a strictStableToken
    mapping(address => bool) public strictStableTokens;
    mapping(address => bool) public override isAdjustmentAdditive;
    mapping(address => uint256) public override adjustmentBasisPoints;
    mapping(address => uint256) public lastAdjustmentTimings;
    mapping(address => uint256) public latestPriceFeedTime;

    mapping(address => uint256) public override priceVariancePer1Million; // 1% -> 100 / 10000
    uint256 public constant MAX_PRICE_VARIANCE_PER_1M = 1000;


    function setPriceMethod(uint8 _setT) external onlyOwner{
        priceMethod = _setT;
    }

    function setPriceVariance(uint256 _priceVariance) external onlyOwner {
        require(_priceVariance < PRICE_VARIANCE_PRECISION.div(2), "invalid variance");
        priceVariance = _priceVariance;
    }

    function setSafePriceTimeGap(uint256 _gap) external onlyOwner {
        priceSafetyGap = _gap;
    }

    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external override onlyOwner {
        require(
            lastAdjustmentTimings[_token].add(MAX_ADJUSTMENT_INTERVAL) < block.timestamp,
            "VaultPriceFeed: adjustment frequency exceeded"
        );
        require(_adjustmentBps <= MAX_ADJUSTMENT_BASIS_POINTS, "invalid _adjustmentBps");
        isAdjustmentAdditive[_token] = _isAdditive;
        adjustmentBasisPoints[_token] = _adjustmentBps;
        lastAdjustmentTimings[_token] = block.timestamp;
    }

    // function setTimeVariace(uint256 _priceAdjPerInterval, uint256 _interval) external onlyOwner{
    //     priceAdjPerInterval = _priceAdjPerInterval;
    //     priceInterval = _interval;
    // }
    // function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external override onlyOwner {
    //     spreadThresholdBasisPoints = _spreadThresholdBasisPoints;
    // }
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external override onlyOwner {
        require(_spreadBasisPoints <= MAX_SPREAD_BASIS_POINTS, "VaultPriceFeed: invalid _spreadBasisPoints");
        spreadBasisPoints[_token] = _spreadBasisPoints;
    }
    // function setPriceSampleSpace(uint256 _priceSampleSpace) external override onlyOwner {
    //     require(_priceSampleSpace > 0, "VaultPriceFeed: invalid _priceSampleSpace");
    //     priceSampleSpace = _priceSampleSpace;
    // }
    // function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external override onlyOwner {
    //     maxStrictPriceDeviation = _maxStrictPriceDeviation;
    // }





    function _getCombPrice(address _token, bool _maximise) internal view returns (uint256){
        uint256 price = 0;
        uint256 updateTime = 0;
         
        (uint256 pricePr, bool statePr) = getPrimaryPriceFast(_token, _maximise);
        require(statePr, "Primary Price Failure");

        (uint256 priceCl, bool stateCl, uint256 clUpdatedTime) = getChainlinkPrice(_token, _maximise);
        require(stateCl, "Chainlink Price Failure");

        {
            uint256 price_minBound = priceCl.mul(PRICE_VARIANCE_PRECISION - priceVariance).div(PRICE_VARIANCE_PRECISION);
            uint256 price_maxBound = priceCl.mul(PRICE_VARIANCE_PRECISION + priceVariance).div(PRICE_VARIANCE_PRECISION);

            if ((pricePr < price_maxBound) && (pricePr > price_minBound)) {
                if (priceMethod == 1){
                    if (_maximise){
                        price = pricePr > priceCl ? pricePr : priceCl;
                    }
                    else{
                        price = pricePr > priceCl ? priceCl : pricePr;
                    }
                }
                else if (priceMethod == 3){
                    if (latestPriceFeedTime[_token] > clUpdatedTime){
                        price = pricePr;
                        updateTime = latestPriceFeedTime[_token];
                    }
                    else{
                        price = priceCl;
                        updateTime = clUpdatedTime;
                    }                    
                }
                else{
                    price = pricePr;
                    updateTime = clUpdatedTime;
                }
            }
            else {
                price = priceCl;
                updateTime = clUpdatedTime;
            }
        }
        
        if (spreadBasisPoints[_token] > 0){
            if (_maximise){
                price = price.mul(BASIS_POINTS_DIVISOR.add(spreadBasisPoints[_token])).div(BASIS_POINTS_DIVISOR);
            }
            else{
                price = price.mul(BASIS_POINTS_DIVISOR.sub(spreadBasisPoints[_token])).div(BASIS_POINTS_DIVISOR);
            }         
        }
        return price;    
    }

    //public read
    function getPrice(address _token, bool _maximise, bool, bool) public override view returns (uint256) {
        // uint256 price = useV2Pricing ? getPriceV2(_token, _maximise, _includeAmmPrice) : getPriceV1(_token, _maximise, _includeAmmPrice);
        uint256 price = _getCombPrice(_token, _maximise);
        if (adjustmentBasisPoints[_token] > 0) {
            bool isAdditive = isAdjustmentAdditive[_token];
            if (isAdditive) {
                price = price.mul(BASIS_POINTS_DIVISOR.add(adjustmentBasisPoints[_token])).div(BASIS_POINTS_DIVISOR);
            } else {
                price = price.mul(BASIS_POINTS_DIVISOR.sub(adjustmentBasisPoints[_token])).div(BASIS_POINTS_DIVISOR);
            }
        }
        require(price > 0, "invalid price");
        return price;
    }

    function getOrigPrice(address _token) public override view returns (uint256) {
        return getPrice(_token, true, false, false);
    }

    function getChainlinkPrice(address _token, bool _max) public view returns (uint256, bool, uint256) {
        if (chainlinkAddress[_token] == address(0)) {
            revert("chainlink address not set");
            // return (0, false, 0);
        }
        if (chainlinkPrecision[_token] < 2) {
            revert("chainlink precision too small");
            // return (0, false, 0);
        }
        (/*uint80 roundId*/, int256 answer, /*uint256 startedAt*/, uint256 updatedAt, /*uint80 answeredInRound*/) = AggregatorV3Interface(chainlinkAddress[_token]).latestRoundData();
    
        if (answer < 1) {
            revert("chainlink price equal to zero");
            // return (0, false, 0);
        }
        uint256 time_interval = uint256(block.timestamp).sub(updatedAt);
        if (time_interval > priceSafetyGap && !strictStableTokens[_token]) {
            revert("chainlink safety time gap reached");
            // return (0, false,0);
        }
        uint256 price = uint256(answer).mul(PRICE_PRECISION).div(chainlinkPrecision[_token]);
        return (price, true, updatedAt);
    }


    function getPrimaryPrice(address _token, bool _maximise) public override view returns (uint256, bool) {
        return getPrimaryPriceFast(_token, _maximise);
    }


    //==============================fast price================================
    function getPrimaryPriceFast(address _token, bool /*_maximise*/)
    public
    view
    returns (uint256, bool)
    {
        uint256 time_interval = uint256(block.timestamp).sub(fastTimeStamp);
        if (time_interval > priceSafetyGap && !strictStableTokens[_token]) {
            return (0, false);
        }
        return (prices[_token], true);
    }

    using Counters for Counters.Counter;
    Counters.Counter private _batchRoundId;

    event PriceUpdated(
        address token,
        uint256 ajustedAmount,
        uint256 batchRoundId
    );

    uint256[] public tokenPrecisions;
    address[] public tokens;
    mapping(address => uint256) public prices;
    uint256 public fastTimeStamp;
    uint256 public constant BITMASK_32 = ~uint256(0) >> (256 - 32);
    mapping(address => bool) public isUpdater;

    modifier onlyUpdater() {
        require(isUpdater[msg.sender], "FastPriceFeed: forbidden");
        _;
    }

    function setUpdater(address _account, bool _isActive) external onlyOwner {
        isUpdater[_account] = _isActive;
    }

    function setSignPrefixCode(address _updater, uint256 _setCode) external onlyOwner {
        signUpdaterCode[_updater] = _setCode;
    }

    function setTimeTolerance(uint256 _tol) external onlyOwner {
        updateTimeTolerance = _tol;
    }

    function setTokenChainlinkConfig(address _token, address _chainlinkContract, bool _isStrictStable) external onlyOwner {
        uint256 chainLinkDecimal = uint256(
            AggregatorV3Interface(_chainlinkContract).decimals()
        );
        require(
            chainLinkDecimal < 10 && chainLinkDecimal > 0,
            "invalid chainlink decimal"
        );
        chainlinkAddress[_token] = _chainlinkContract;
        chainlinkPrecision[_token] = 10 ** chainLinkDecimal;
        strictStableTokens[_token] = _isStrictStable;
    }

    function setBitTokens(
        address[] memory _tokens,
        uint256[] memory _tokenPrecisions
    ) external onlyOwner {
        require(
            _tokens.length == _tokenPrecisions.length,
            "FastPriceFeed: invalid lengths"
        );
        tokens = _tokens;
        tokenPrecisions = _tokenPrecisions;
    }

    function setPricesWithBits(uint256[] memory _priceBits, uint256 _timestamp) external onlyUpdater {
        _setPricesWithBits(_priceBits, _timestamp);
    }

    function _setPricesWithBits(uint256[] memory _priceBits, uint256 _timestamp) private {
        uint256 roundId = _batchRoundId.current();
        _batchRoundId.increment();
        fastTimeStamp = _timestamp;

        uint256 bitsMaxLength = 8;
        for (uint256 i = 0; i < _priceBits.length; i++) {
            uint256 priceBits = _priceBits[i];


            for (uint256 j = 0; j < bitsMaxLength; j++) {
                uint256 tokenIndex = i * bitsMaxLength + j;
                if (tokenIndex >= tokens.length) {
                    return;
                }

                uint256 startBit = 32 * j;
                uint256 price = (priceBits >> startBit) & BITMASK_32;

                address token = tokens[tokenIndex];
                require(fastTimeStamp >= latestPriceFeedTime[token], "data out of time");
                latestPriceFeedTime[token] = fastTimeStamp;
                uint256 tokenPrecision = tokenPrecisions[tokenIndex];
                uint256 adjustedPrice = price.mul(PRICE_PRECISION).div(
                    tokenPrecision
                );
                prices[token] = adjustedPrice;
                emit PriceUpdated(token, adjustedPrice, roundId);
            }
        }
    }

    address[] public positionRouters;

    //set positionRouter
    function setPositionRouter(address[] memory _positionRouters) public onlyOwner {
        positionRouters = _positionRouters;
    }

    function addPositionRouter(address _positionRouter) public onlyOwner {
        positionRouters.push(_positionRouter);
    }

    function setPricesWithBitsAndExecute(uint256[] memory _priceBits, uint256 _timestamp) external onlyUpdater {
        _setPricesWithBits(_priceBits, _timestamp);

        for (uint256 i = 0; i < positionRouters.length; i++) {
            IPositionRouter _positionRouter = IPositionRouter(positionRouters[i]);

            uint256 a;
            uint256 b;
            uint256 c;
            uint256 d;
            (a, b, c, d) = _positionRouter.getRequestQueueLengths();
            _positionRouter.executeIncreasePositions(b + 3, payable(msg.sender));
            _positionRouter.executeDecreasePositions(d + 3, payable(msg.sender));
        }
    }

    function setPricesWithBitsAndExecuteIncrease(uint256[] memory _priceBits, uint256 _timestamp) external onlyUpdater {
        _setPricesWithBits(_priceBits, _timestamp);

        for (uint256 i = 0; i < positionRouters.length; i++) {
            IPositionRouter _positionRouter = IPositionRouter(positionRouters[i]);

            uint256 a;
            uint256 b;
            uint256 c;
            uint256 d;
            (a, b, c, d) = _positionRouter.getRequestQueueLengths();
            _positionRouter.executeIncreasePositions(b + 3, payable(msg.sender));
        }
    }

    function setPricesWithBitsAndExecuteDecrease(uint256[] memory _priceBits, uint256 _timestamp) external onlyUpdater {
        _setPricesWithBits(_priceBits, _timestamp);

        for (uint256 i = 0; i < positionRouters.length; i++) {
            IPositionRouter _positionRouter = IPositionRouter(positionRouters[i]);

            uint256 a;
            uint256 b;
            uint256 c;
            uint256 d;
            (a, b, c, d) = _positionRouter.getRequestQueueLengths();
            _positionRouter.executeDecreasePositions(d + 3, payable(msg.sender));
        }
    }

    function updatePriceImpact(address[] memory _tokens, uint256[] memory _varPer1M) external onlyUpdater {
        for (uint256 i = 0; i < _tokens.length; i++){
            require(_varPer1M[i] < MAX_PRICE_VARIANCE_PER_1M, "max vairance exceed");
            priceVariancePer1Million[_tokens[i]] = _varPer1M[i];
        }
    }

    function updateWithSig(uint256[] memory _priceBits, uint256 _priceTimestamp,  address _updater, bytes memory _updaterSignedMsg) external  onlyUpdater {
        require(VerifyFull(_updater, _priceBits, _priceTimestamp, _updaterSignedMsg), "Verification Failed");
        _setPricesWithBits(_priceBits, _priceTimestamp);
    }

    //code for verify
    function VerifyMessage(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v){
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function VerifyFull(address _updater, uint256[] memory _priceBits, uint256 _priceTimestamp, bytes memory _updaterSignedMsg) public view returns (bool) {
        require(_priceTimestamp <= block.timestamp && block.timestamp.sub(_priceTimestamp) < updateTimeTolerance, "time tollarance reached.");
        bytes memory content = abi.encodePacked(signUpdaterCode[_updater], _updater, _priceTimestamp);
        for(uint8 i = 0; i < _priceBits.length; i++){
            content =  abi.encodePacked(content, _priceBits[i]);//, "."
        }
        bytes32 _calHash = keccak256(content);
        bytes32 ethSignedHash = keccak256(abi.encodePacked(prefix, _calHash));
        return isUpdater[recoverSigner(ethSignedHash, _updaterSignedMsg)];
    }
}