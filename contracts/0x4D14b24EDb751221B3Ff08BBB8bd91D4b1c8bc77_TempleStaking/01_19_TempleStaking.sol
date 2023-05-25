pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ABDKMath64x64.sol";
import "./TempleERC20Token.sol";
import "./OGTemple.sol";
import "./ExitQueue.sol";

// import "hardhat/console.sol";

/**
 * Mechancics of how a user can stake temple.
 */
contract TempleStaking is Ownable {
    using ABDKMath64x64 for int128;
    
    TempleERC20Token immutable public TEMPLE; // The token being staked, for which TEMPLE rewards are generated
    OGTemple immutable public OG_TEMPLE; // Token used to redeem staked TEMPLE
    ExitQueue public EXIT_QUEUE;    // unstake exit queue

    // epoch percentage yield, as an ABDKMath64x64
    int128 public epy; 

    // epoch size, in seconds
    uint256 public epochSizeSeconds; 

    // The starting timestamp. from where staking starts
    uint256 public startTimestamp;

    // epy compounded over every epoch since the contract creation up 
    // until lastUpdatedEpoch. Represented as an ABDKMath64x64
    int128 public accumulationFactor;

    // the epoch up to which we have calculated accumulationFactor.
    uint256 public lastUpdatedEpoch; 

    event StakeCompleted(address _staker, uint256 _amount, uint256 _lockedUntil);
    event AccumulationFactorUpdated(uint256 _epochsProcessed, uint256 _currentEpoch, uint256 _accumulationFactor);
    event UnstakeCompleted(address _staker, uint256 _amount);    

    constructor(
        TempleERC20Token _TEMPLE,
        ExitQueue _EXIT_QUEUE,
        uint256 _epochSizeSeconds,
        uint256 _startTimestamp) {

        require(_startTimestamp < block.timestamp, "Start timestamp must be in the past");
        require(_startTimestamp > (block.timestamp - (24 * 2 * 60 * 60)), "Start timestamp can't be more than 2 days in the past");

        TEMPLE = _TEMPLE;
        EXIT_QUEUE = _EXIT_QUEUE;

        // Each version of the staking contract needs it's own instance of OGTemple users can use to
        // claim back rewards
        OG_TEMPLE = new OGTemple(); 
        epochSizeSeconds = _epochSizeSeconds;
        startTimestamp = _startTimestamp;
        epy = ABDKMath64x64.fromUInt(1);
        accumulationFactor = ABDKMath64x64.fromUInt(1);
    }

    /** Sets epoch percentage yield */
    function setExitQueue(ExitQueue _EXIT_QUEUE) external onlyOwner {
        EXIT_QUEUE = _EXIT_QUEUE;
    }

    /** Sets epoch percentage yield */
    function setEpy(uint256 _numerator, uint256 _denominator) external onlyOwner {
        _updateAccumulationFactor();
        epy = ABDKMath64x64.fromUInt(1).add(ABDKMath64x64.divu(_numerator, _denominator));
    }

    /** Get EPY as uint, scaled up the given factor (for reporting) */
    function getEpy(uint256 _scale) external view returns (uint256) {
        return epy.sub(ABDKMath64x64.fromUInt(1)).mul(ABDKMath64x64.fromUInt(_scale)).toUInt();
    }

    function currentEpoch() public view returns (uint256) {
        return (block.timestamp - startTimestamp) / epochSizeSeconds;
    }

    /** Return current accumulation factor, scaled up to account for fractional component */
    function getAccumulationFactor(uint256 _scale) external view returns(uint256) {
        return _accumulationFactorAt(currentEpoch()).mul(ABDKMath64x64.fromUInt(_scale)).toUInt();
    }

    /** Calculate the updated accumulation factor, based on the current epoch */
    function _accumulationFactorAt(uint256 epoch) private view returns(int128) {
        uint256 _nUnupdatedEpochs = epoch - lastUpdatedEpoch;
        return accumulationFactor.mul(epy.pow(_nUnupdatedEpochs));
    }

    /** Balance in TEMPLE for a given amount of OG_TEMPLE */
    function balance(uint256 amountOgTemple) public view returns(uint256) {
        return _overflowSafeMul1e18(
            ABDKMath64x64.divu(amountOgTemple, 1e18).mul(_accumulationFactorAt(currentEpoch()))
        );
    }

    /** updates rewards in pool */
    function _updateAccumulationFactor() internal {
        uint256 _currentEpoch = currentEpoch();

        // still in previous epoch, no action. 
        // NOTE: should be a pre-condition that _currentEpoch >= lastUpdatedEpoch
        //       It's possible to end up in this state if we shorten epoch size.
        //       As such, it's not baked as a precondition
        if (_currentEpoch <= lastUpdatedEpoch) {
            return;
        }

        accumulationFactor = _accumulationFactorAt(_currentEpoch);
        lastUpdatedEpoch = _currentEpoch;
        uint256 _nUnupdatedEpochs = _currentEpoch - lastUpdatedEpoch;
        emit AccumulationFactorUpdated(_nUnupdatedEpochs, _currentEpoch, accumulationFactor.mul(10000).toUInt());
    }

    /** Stake on behalf of a given address. Used by other contracts (like Presale) */
    function stakeFor(address _staker, uint256 _amountTemple) public returns(uint256 amountOgTemple) {
        require(_amountTemple > 0, "Cannot stake 0 tokens");

        _updateAccumulationFactor();

        // net past value/genesis value/OG Value for the temple you are putting in.
        amountOgTemple = _overflowSafeMul1e18(ABDKMath64x64.divu(_amountTemple, 1e18).div(accumulationFactor));

        SafeERC20.safeTransferFrom(TEMPLE, msg.sender, address(this), _amountTemple);
        OG_TEMPLE.mint(_staker, amountOgTemple);
        emit StakeCompleted(_staker, _amountTemple, 0);

        return amountOgTemple;
    }

    /** Stake temple */
    function stake(uint256 _amountTemple) external returns(uint256 amountOgTemple) {
        return stakeFor(msg.sender, _amountTemple);
    }

    /** Unstake temple */
    function unstake(uint256 _amountOgTemple) external {      
        require(OG_TEMPLE.allowance(msg.sender, address(this)) >= _amountOgTemple, 'Insufficient OGTemple allowance. Cannot unstake');

        _updateAccumulationFactor();
        uint256 unstakeBalanceTemple = balance(_amountOgTemple);

        OG_TEMPLE.burnFrom(msg.sender, _amountOgTemple);
        SafeERC20.safeIncreaseAllowance(TEMPLE, address(EXIT_QUEUE), unstakeBalanceTemple);
        EXIT_QUEUE.join(msg.sender, unstakeBalanceTemple);

        emit UnstakeCompleted(msg.sender, _amountOgTemple);    
    }

    function _overflowSafeMul1e18(int128 amountFixedPoint) internal pure returns (uint256) {
        uint256 integralDigits = amountFixedPoint.toUInt();
        uint256 fractionalDigits = amountFixedPoint.sub(ABDKMath64x64.fromUInt(integralDigits)).mul(ABDKMath64x64.fromUInt(1e18)).toUInt();
        return (integralDigits * 1e18) + fractionalDigits;
    }
}