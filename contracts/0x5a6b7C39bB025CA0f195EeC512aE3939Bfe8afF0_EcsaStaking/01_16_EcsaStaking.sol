pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ABDKMath64x64.sol";
import "./EcsaERC20Token.sol";
import "./OGEcsa.sol";
import "./ExitQueue.sol";

// import "hardhat/console.sol";

/**
 * Mechancics of how a user can stake ecsa.
 */
contract EcsaStaking is Ownable {
    using ABDKMath64x64 for int128;
    
    EcsaERC20Token immutable public ECSA; // The token being staked, for which ECSA rewards are generated
    OGEcsa immutable public OG_ECSA; // Token used to redeem staked ECSA
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
        EcsaERC20Token _ECSA,
        ExitQueue _EXIT_QUEUE,
        uint256 _epochSizeSeconds,
        uint256 _startTimestamp) {

        require(_startTimestamp < block.timestamp, "Start timestamp must be in the past");
        require(_startTimestamp > (block.timestamp - (24 * 2 * 60 * 60)), "Start timestamp can't be more than 2 days in the past");

        ECSA = _ECSA;
        EXIT_QUEUE = _EXIT_QUEUE;

        transferOwnership(address(0x67Fe53fD9a332faf9867c191b5b7d660623DC057));

        // Each version of the staking contract needs it's own instance of OGECSA users can use to
        // claim back rewards
        OG_ECSA = new OGEcsa(); 
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

    /** Balance in ECSA for a given amount of OG_ECSA */
    function balance(uint256 amountOgEcsa) public view returns(uint256) {
        return _overflowSafeMul1e18(
            ABDKMath64x64.divu(amountOgEcsa, 1e18).mul(_accumulationFactorAt(currentEpoch()))
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
    function stakeFor(address _staker, uint256 _amountEcsa) public returns(uint256 amountOgEcsa) {
        require(_amountEcsa > 0, "Cannot stake 0 tokens");

        _updateAccumulationFactor();

        // net past value/genesis value/OG Value for the ecsa you are putting in.
        amountOgEcsa = _overflowSafeMul1e18(ABDKMath64x64.divu(_amountEcsa, 1e18).div(accumulationFactor));

        SafeERC20.safeTransferFrom(ECSA, msg.sender, address(this), _amountEcsa);
        OG_ECSA.mint(_staker, amountOgEcsa);
        emit StakeCompleted(_staker, _amountEcsa, 0);

        return amountOgEcsa;
    }

    /** Stake ecsa */
    function stake(uint256 _amountEcsa) external returns(uint256 amountOgEcsa) {
        return stakeFor(msg.sender, _amountEcsa);
    }

    /** Unstake ecsa */
    function unstake(uint256 _amountOgEcsa) external {      
        require(OG_ECSA.allowance(msg.sender, address(this)) >= _amountOgEcsa, 'Insufficient OGEcsa allowance. Cannot unstake');

        _updateAccumulationFactor();
        uint256 unstakeBalanceEcsa = balance(_amountOgEcsa);

        OG_ECSA.burnFrom(msg.sender, _amountOgEcsa);
        SafeERC20.safeIncreaseAllowance(ECSA, address(EXIT_QUEUE), unstakeBalanceEcsa);
        EXIT_QUEUE.join(msg.sender, unstakeBalanceEcsa);

        emit UnstakeCompleted(msg.sender, _amountOgEcsa);    
    }

    function _overflowSafeMul1e18(int128 amountFixedPoint) internal pure returns (uint256) {
        uint256 integralDigits = amountFixedPoint.toUInt();
        uint256 fractionalDigits = amountFixedPoint.sub(ABDKMath64x64.fromUInt(integralDigits)).mul(ABDKMath64x64.fromUInt(1e18)).toUInt();
        return (integralDigits * 1e18) + fractionalDigits;
    }
}