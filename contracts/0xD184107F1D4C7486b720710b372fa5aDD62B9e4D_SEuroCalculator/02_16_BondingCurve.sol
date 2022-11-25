// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "contracts/Rates.sol";

contract BondingCurve is AccessControl {
    struct Bucket { uint32 index; uint256 price; }

    uint8 private constant J_NUMERATOR = 1;
    uint8 private constant J_DENOMINATOR = 5;
    uint64 public constant FINAL_PRICE = 1 ether;
    bytes32 public constant UPDATER = keccak256("UPDATER");
    bytes32 public constant CALCULATOR = keccak256("CALCULATOR");

    uint256 private immutable initialPrice;
    uint256 private immutable priceDelta;
    int128 private immutable curveShape;
    uint256 private immutable bucketSize;
    uint32 private immutable finalBucketIndex;
    uint256 public immutable maxSupply;

    // index and price of current price bucket
    Bucket public currentBucket;
    mapping(uint32 => uint256) private bucketPricesCache;
    uint256 public ibcoTotalSupply;

    event PriceUpdated(uint32 index, uint256 price);

    /// @param _initialPrice initial price of sEURO, multiplied by 10^18, e.g. 800_000_000_000_000_000 = 0.8
    /// @param _maxSupply the amount of sEURO to be supplied by the Bonding Curve before sEURO reaches full price (€1 = 1 SEUR)
    /// @param _bucketSize the size of each price bucket in sEURO
    // Price buckets combine accurate pricing with lightweight calculations
    // All sEURO within a single price bucket are equal to the price of the median token
    // e.g. if bucket size is 100_000 SEUR, each of the first 100_000 SEUR will be priced as if the 50,001st token
    // Pricing is calculated by the Bonding Curve formula:
    // y = k * (x / m)^j + i;
    // where: k = final price - initial price
    // x = current total supply of sEURO by Bonding Curve
    // m = max supply of Bonding Curve
    // j = 0.2, a constant which dictates the shape of the curve
    // i = the initial price of sEURO in Bonding Curve
    constructor(uint256 _initialPrice, uint256 _maxSupply, uint256 _bucketSize) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(UPDATER, msg.sender);
        grantRole(CALCULATOR, msg.sender);

        initialPrice = _initialPrice;
        maxSupply = _maxSupply;
        priceDelta = FINAL_PRICE - initialPrice;
        curveShape = ABDKMath64x64.divu(J_NUMERATOR, J_DENOMINATOR);

        bucketSize = _bucketSize;
        finalBucketIndex = uint32(_maxSupply / _bucketSize);
        updateCurrentBucket(ibcoTotalSupply);
    }

    modifier onlyUpdater() { require(hasRole(UPDATER, msg.sender), "invalid-curve-updater"); _; }

    modifier onlyCalculator() { require(hasRole(CALCULATOR, msg.sender), "invalid-curve-calculator"); _; }

    // Read only function to estimate the amount of sEURO for given euros
    // Based on the current price alone, so not necessarily accurate
    /// @param _euroAmount amount of euros for which you want to estimate conversion into sEURO
    function readOnlyCalculatePrice(uint256 _euroAmount) external view returns (uint256) {
        return convertEuroToSeuro(_euroAmount, currentBucket.price);
    }

    // Calculates exactly how much sEURO is equivalent to given euros
    // Caches price calculations and is therefore a state-changing function
    /// @param _euroAmount amount of euros for which you want to calculate conversion into sEURO
    function calculatePrice(uint256 _euroAmount) external onlyCalculator returns (uint256) {
        uint256 _sEuroTotal = 0;
        uint32 bucketIndex = currentBucket.index;
        uint256 bucketPrice = currentBucket.price;
        while (_euroAmount > 0) {
            uint256 remainingInSeuro = convertEuroToSeuro(_euroAmount, bucketPrice);
            uint256 remainingCapacityInBucket = getRemainingCapacityInBucket(bucketIndex);
            if (remainingInSeuro > remainingCapacityInBucket) {
                _sEuroTotal += remainingCapacityInBucket;
                _euroAmount -= convertSeuroToEuro(remainingCapacityInBucket, bucketPrice);
                bucketIndex++;
                bucketPrice = getBucketPrice(bucketIndex);
                continue;
            }
            _sEuroTotal += remainingInSeuro;
            _euroAmount = 0;
        }
        return _sEuroTotal;
    }

    // Updates the current price of sEURO, based on the total supply of sEURO through IBCO
    /// @param _minted the amount of sEURO to add to the IBCO total supply
    function updateCurrentBucket(uint256 _minted) public onlyUpdater {
        ibcoTotalSupply += _minted;
        uint32 bucketIndex = uint32(ibcoTotalSupply / bucketSize);
        uint32 previous = currentBucket.index;
        currentBucket = Bucket(bucketIndex, getBucketPrice(bucketIndex));
        delete bucketPricesCache[bucketIndex];
        if (previous != bucketIndex) emit PriceUpdated(currentBucket.index, currentBucket.price);
    }

    function getBucketPrice(uint32 _bucketIndex) internal returns (uint256 _price) {
        if (_bucketIndex >= finalBucketIndex) return FINAL_PRICE;
        if (bucketPricesCache[_bucketIndex] > 0) return bucketPricesCache[_bucketIndex];
        // y = k * (x / m)^j + i;
        _price = ABDKMath64x64.mulu(ABDKMath64x64.exp_2(ABDKMath64x64.mul(curveShape, ABDKMath64x64.log_2(ABDKMath64x64.divu(getBucketMidpoint(_bucketIndex), maxSupply)))), priceDelta) + initialPrice;
        cacheBucketPrice(_bucketIndex, _price);
    }

    function convertEuroToSeuro(uint256 _amount, uint256 _rate) private pure returns (uint256) {
        // price is stored as 18 decimal
        return Rates.convertInverse(_amount, _rate, 18);
    }

    function convertSeuroToEuro(uint256 _amount, uint256 _rate) private pure returns (uint256) {
        // price is stored as 18 decimal
        return Rates.convertDefault(_amount, _rate, 18);
    }

    function getRemainingCapacityInBucket(uint32 _bucketIndex) private view returns (uint256) {
        uint256 bucketCapacity = (_bucketIndex + 1) * bucketSize;
        uint256 diff = bucketCapacity - ibcoTotalSupply;
        return diff > bucketSize ? bucketSize : diff;
    }

    function getBucketMidpoint(uint32 _bucketIndex) private view returns (uint256) {
        return (_bucketIndex * bucketSize) + (bucketSize / 2);
    }

    function cacheBucketPrice(uint32 _bucketIndex, uint256 _bucketPrice) private {
        bucketPricesCache[_bucketIndex] = _bucketPrice;
    }
}