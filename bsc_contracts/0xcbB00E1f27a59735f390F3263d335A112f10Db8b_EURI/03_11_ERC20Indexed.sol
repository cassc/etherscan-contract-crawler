// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20ElasticSupply.sol";
import "IPredictIndex.sol";


/**
 * @title ERC20Indexed
 * @author Geminon Protocol
 * @notice Extension of the ERC20 standard that allows to create
 * stablecoins whose price follows the values of an external index.
 * The contract checks the values provided to avoid large variations.
 * Also the max % variation in the peg target in one step is protected 
 * against big changes. Owner must first request the change, the flag 
 * "maxVarChangeRequested" shows that condition, and the new value 
 * proposed is public. Only after 30 days from the request the 
 * change can be made effective. Additionally, the new value can't 
 * be higher than 2x the actual value.
 * In case the contract that provides CPI target values stops working, 
 * this contract has a fallback update mechanism that converges to a 
 * constant CPI value of 0.2% monthly, or 2.68% annualized. This ensures 
 * the token can work indefinitely without external intervention.
 * @dev Peg values are managed with 6 decimals following the PredictIndex
 * format, since they are expected to be numbers around 1. The getter 
 * function getPegValue performs conversion to 18 decimals standard to 
 * allow compatibility with other contracts and apps.
 */
contract ERC20Indexed is ERC20ElasticSupply {

    IPredictIndex private indexBeacon;

    uint16 public baseYear;
    uint8 public baseMonth;

    uint32 public alpha;
    uint32 public defaultPegVar;
    uint32 public maxPegVariation;
    uint32 public lastPegVarRate;
    bool public maxVarChangeRequested;
    uint64 public timestampMVChangeRequest;
    uint32 public newMaxVarRequested;
    
    uint64 public lastPegTarget;
    uint64 public pegTarget;
    uint64 public lastTargetTimestamp;
    uint64 public targetTimestamp;


    /// @param beacon address of the contract that provides the target values for the peg
    /// @param baseMintRatio max percentage of the supply that can be minted per day, 3 decimals [1,1000]
    /// @param thresholdLimitMint Minimum supply minted to begin requiring the maxMintRatio limit. 18 decimals.
    /// @dev alpha, defaultPegVar and maxPegVariation have 6 decimals [1, 1000000]
    constructor(
        string memory name, 
        string memory symbol, 
        address beacon, 
        uint32 baseMintRatio, 
        uint256 thresholdLimitMint
    ) 
        ERC20ElasticSupply(name, symbol, baseMintRatio, thresholdLimitMint) 
    {
        indexBeacon = IPredictIndex(beacon);
        baseYear = indexBeacon.baseYear();
        baseMonth = indexBeacon.baseMonth();
        
        uint32 span = 12;
        alpha = 2*1e6 / (1+span);
        
        defaultPegVar = 2*1e3;  // 0.2% monthly ~ 2.68% yearly
        maxPegVariation = 2*1e4;  // 2% monthly

        _initializePegValues();
    }


    /// @notice allows to set a new source for CPI index data. It
    /// doesn't affect the actual index value of the token, and the
    /// new values provided need to be inside the accepted limits or
    /// they will be clipped by this contract.
    function setIndexBeacon(address beacon) external onlyOwner {
        IPredictIndex newBeacon = IPredictIndex(beacon);

        require(newBeacon.isInitialized()); // dev: Not initialized
        require(newBeacon.baseYear() == baseYear); // dev: Base year
        require(newBeacon.baseMonth() == baseMonth); // dev: Base month
        require(newBeacon.baseValue() == indexBeacon.baseValue()); // dev: Base value
        require(newBeacon.isUpdated()); // dev: Not updated

        indexBeacon = newBeacon;
    }

    /// @notice Make a request to change the maxPegVariation parameter of the
    /// contract. The value proposed can't be higher than 2x the actual value.
    /// After the request, a delay of 30 days is set to apply the changes. The
    /// request, timestamp and new value proposed are public.
    /// @param newValue with 6 decimals (1e6)
    function requestMaxVariationChange(uint16 newValue) external onlyOwner {
        require(newValue > 0); // dev: Null value
        require(newValue < maxPegVariation * 2); // dev: Out of limits

        timestampMVChangeRequest = uint64(block.timestamp);
        maxVarChangeRequested = true;
        newMaxVarRequested = newValue;
    }

    /// @notice Apply the change in the maxPegVariation parameter proposed using
    /// the requestMaxVariationChange() function. This function can only be called
    /// 30 days after the request of the change.
    function applyMaxVariationChange() external onlyOwner {
        require(maxVarChangeRequested); // dev: Not requested
        require(block.timestamp - timestampMVChangeRequest > 30 days); // dev: Timelock
        maxVarChangeRequested = false;
        maxPegVariation = newMaxVarRequested;
    }

    
    /// @notice Updates the target value of the inflation index. Tries to use the
    /// external beacon to get the last published CPI value, and if it is not available,
    /// it uses a fallback function to autonomously update the index target. Anyone can
    /// call this function to trigger the token peg update. 
    function updateTarget() public {
        if (indexBeacon.isUpdated()) 
            _updateFromBeacon();
        else 
            _backupUpdate();
    }

    
    /// @notice Get the current value of the peg and updates the target
    /// value from the beacon if needed.
    function getOrUpdatePegValue() public returns(uint256) {
        if (block.timestamp > targetTimestamp) updateTarget();
        return getPegValue();
    }

    /// @notice Get the current value of the peg
    /// @dev Peg is stored using 6 decimals. It needs to be converted to 18 decimals price.
    function getPegValue() public view virtual returns(uint256) {
        return _pegValue() * 1e12;
    }


    /// @notice Calculates the current value of the peg
    function _pegValue() internal view returns(uint256) {
        uint256 deltaT = ((block.timestamp - lastTargetTimestamp) * 1e6) / (targetTimestamp - lastTargetTimestamp);
        return (lastPegTarget + (deltaT * (pegTarget - lastPegTarget)) / 1e6);
    }


    /// @dev Initializes peg target value and timestamp from the index beacon contract.
    function _initializePegValues() private {
        uint64 newPegTarget = indexBeacon.getTargetValue();
        uint64 newTargetTimestamp = indexBeacon.getTargetTimestamp();
        uint32 varRate = indexBeacon.getRelativeTrend();

        require(newTargetTimestamp > block.timestamp); // dev: Timestamp

        pegTarget = newPegTarget;
        lastPegTarget = (newPegTarget * (1e6 - varRate)) / 1e6;
        targetTimestamp = newTargetTimestamp;
        lastTargetTimestamp = newTargetTimestamp - 30 days;
        lastPegVarRate = varRate;

        if (block.timestamp < lastTargetTimestamp) 
            lastTargetTimestamp = uint64(block.timestamp);
    }


    /// @notice Fetch peg target value and timestamp from the index beacon contract,
    /// verifies that the new values are inside the limits and stores those values.
    /// @dev This design pattern with a paid transaction instead of just a view of the peg 
    /// is needed so that the token contract can autonomously perform checks on the validity 
    /// and bounds of the provided peg value. If we don't store internally the peg values,
    /// we can't verify their limits of variation.
    function _updateFromBeacon() private {
        require(block.timestamp > targetTimestamp); // dev: Update too soon

        uint256 newPegTarget = indexBeacon.getTargetValue();
        uint64 newTargetTimestamp = indexBeacon.getTargetTimestamp();
        uint256 newVarRate = indexBeacon.getRelativeTrend();

        require(newTargetTimestamp > block.timestamp); // dev: Invalid target timestamp
        
        (newPegTarget, newVarRate) = _limitPegVar(newPegTarget, newVarRate, targetTimestamp, newTargetTimestamp);

        lastPegTarget = pegTarget;
        pegTarget = _toUint64(newPegTarget);
        lastTargetTimestamp = targetTimestamp;
        targetTimestamp = newTargetTimestamp;
        lastPegVarRate = _toUint32(newVarRate);
    }

    /// @dev Performs the target index update if external update from beacon stops
    /// working. It slowly converges to the default value of 0,2% monthly (~2,68% yearly)
    /// inflation using an exponential moving average of 12 periods. In absence of any
    /// external updates, the token can indefinitely autoupdate its peg value at the default rate.
    function _backupUpdate() private {
        require(!indexBeacon.isUpdated()); // dev: Beacon is updated
        require(block.timestamp > targetTimestamp); // dev: Update too soon

        uint64 newTargetTimestamp = targetTimestamp + 30 days;
        if (newTargetTimestamp < block.timestamp) {
            newTargetTimestamp = uint64(block.timestamp) + 30 days;
        }
        uint256 newVarRate = (alpha*defaultPegVar + uint256(1e6-alpha)*lastPegVarRate) / 1e6;
        uint256 newPegTarget = (pegTarget * (1e6 + newVarRate)) / 1e6;
        uint256 currentPeg = _pegValue();
        if (currentPeg > newPegTarget) {
            newPegTarget = (currentPeg * (1e6 + newVarRate)) / 1e6;
        }
        
        (newPegTarget, newVarRate) = _limitPegVar(newPegTarget, newVarRate, targetTimestamp, newTargetTimestamp);
        
        lastPegTarget = pegTarget;
        pegTarget = _toUint64(newPegTarget);
        lastTargetTimestamp = targetTimestamp;
        targetTimestamp = newTargetTimestamp;
        lastPegVarRate = _toUint32(newVarRate);
    }

    /// @dev Verifies that the resulting variation rate of the peg given the 
    /// time delta and new value isn't over the max allowed value or negative.
    function _limitPegVar(uint256 newPegTarget, uint256 newVarRate, uint256 lastTimestamp, uint256 nextTimestamp) 
        private 
        view 
        returns(uint256, uint256) 
    {
        uint256 timeWeight = ((block.timestamp - lastTimestamp) * 1e6) / (nextTimestamp - lastTimestamp);
        uint256 maxAdjVar = maxPegVariation * timeWeight;
        uint256 currentPeg = _pegValue();

        if (currentPeg > 0) {
            if (newPegTarget < currentPeg) {
                newPegTarget = currentPeg;
                newVarRate = 0;
            }
            else if ((1e6*(newPegTarget - currentPeg)) / currentPeg > maxAdjVar){
                newPegTarget = (currentPeg * (1e6 + maxAdjVar)) / 1e6;
                newVarRate = maxPegVariation;
            }
        }
        if (newVarRate > maxPegVariation)
            newVarRate = maxPegVariation;
        return (newPegTarget, newVarRate);
    }

    /// @dev safe casting of integer to avoid overflow
    function _toUint32(uint256 value) private pure returns (uint32) {
        require(value <= type(uint32).max); // dev: Overflow on integer casting
        return uint32(value);
    }
    /// @dev safe casting of integer to avoid overflow
    function _toUint64(uint256 value) private pure returns (uint64) {
        require(value <= type(uint64).max); // dev: Overflow on integer casting
        return uint64(value);
    }
}