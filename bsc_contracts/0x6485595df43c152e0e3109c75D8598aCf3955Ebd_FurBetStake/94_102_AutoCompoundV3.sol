// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IResolver {
    function checker(uint256 checker_) external view returns (bool canExec, bytes memory execPayload);
}

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// INTERFACES
import "./interfaces/IVault.sol";

/**
 * @title AutoCompound
 * @author Steve Harmeyer
 * @notice This is the auto compound contract.
 */

/// @custom:security-contact [email protected]
contract AutoCompoundV3 is BaseContract, IResolver
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        _properties.maxPeriods = 7;
        _properties.period = 86400; // PRODUCTION period is 24 hours.
        _properties.fee = 2000000000000000; // .002 BNB per period.
        _properties.maxParticipants = 100;
    }

    using Counters for Counters.Counter;

    /**
     * Id tracker.
     * @dev Keeps track of the current id.
     */
    Counters.Counter private _idTracker;

    /**
     * Properties.
     */
    struct Properties {
        uint256 maxPeriods; // Maximum number of periods a participant can auto compound.
        uint256 period; // Seconds between compounds.
        uint256 fee; // BNB fee per period of auto compounding.
        uint256 maxParticipants; // Maximum autocompound participants.
    }
    Properties private _properties;

    /**
     * Stats.
     */
    struct Stats {
        uint256 compounding; // Number of participants auto compounding.
        uint256 compounds; // Number of auto compounds performed.
    }
    Stats private _stats;

    /**
     * Auto compound mappings.
     */
    mapping(uint256 => uint256) private _compoundsLeft;
    mapping(uint256 => uint256) private _lastCompound;
    mapping(uint256 => uint256) private _totalCompounds;
    mapping(uint256 => uint256[]) private _compounds;
    mapping(uint256 => address) private _addresses;
    mapping(address => uint256) private _ids;
    mapping(uint256 => bool) private _compounding;

    uint256 private _checkers;

    /**
     * Checker.
     * @param checker_ The checker number.
     */
    function checker(uint256 checker_) external view override returns (bool canExec, bytes memory execPayload)
    {
        require(checker_ < _checkers, "Invalid checker.");
        uint256 _next_ = _next(checker_);
        if (_next_ == 0) return (false, bytes("No participants are due for an auto compound"));
        return(true, abi.encodeWithSelector(this.compound.selector, _next_));
    }

    /**
     * Set checkers.
     * @param checkers_ The number of checkers.
     */
    function setCheckers(uint256 checkers_) external onlyOwner
    {
        _checkers = checkers_;
    }

    /**
     * Get properties.
     * @return Properties Contract properties.
     */
    function properties() external view returns (Properties memory)
    {
        return _properties;
    }

    /**
     * Get stats.
     * @return Stats Contract stats.
     */
    function stats() external view returns (Stats memory)
    {
        return _stats;
    }

    /**
     * Get id.
     * @param participant_ Participant address.
     * @return uint256 Participant id.
     */
    function getId(address participant_) external view returns (uint256)
    {
        return _ids[participant_];
    }

    /**
     * Get address.
     * @param id_ Participant id.
     * @return address Participant address.
     */
    function getAddress(uint256 id_) external view returns (address)
    {
        return _addresses[id_];
    }

    /**
     * Compounding.
     * @param participant_ Participant address.
     * @return bool True if they're auto compounding.
     */
    function compounding(address participant_) external view returns (bool)
    {
        return _compounding[_ids[participant_]];
    }

    /**
     * Get compounds left.
     * @param participant_ Participant address.
     * @return uint256 Number of compounds remaining.
     */
    function compoundsLeft(address participant_) external view returns (uint256)
    {
        return _compoundsLeft[_ids[participant_]];
    }

    /**
     * Get last compound.
     * @param participant_ Participant address.
     * @return uint256 Timestamp of last compound.
     */
    function lastCompound(address participant_) external view returns (uint256)
    {
        return _lastCompound[_ids[participant_]];
    }

    /**
     * Get total compounds.
     * @param participant_ Participant address.
     * @return uint256 Total number of auto compounds.
     */
    function totalCompounds(address participant_) external view returns (uint256)
    {
        return _totalCompounds[_ids[participant_]];
    }

    /**
     * Next up.
     * @return address Next address to be compounded.
     * @dev Returns the next address in line that needs to be compounded.
     */
    function next() public view returns (address)
    {
        for(uint256 i = 0; i < _checkers; i++) {
            uint256 _next_ = _next(i);
            if (_next_ != 0) return _addresses[_next_];
        }
        return address(0);
    }

    /**
     * Internal next.
     * @param checker_ Chceker number.
     * @return uint256 Id of next participant.
     */
    function _next(uint256 checker_) internal view returns (uint256)
    {
        uint256 _dueDate_ = block.timestamp - _properties.period;
        for(uint256 i = 1; i <= _idTracker.current(); i ++) {
            if(!_compounding[i]) continue; // Skip if they're not compounding.
            if(_lastCompound[i] >= _dueDate_) continue; // Skip if their last compound was too soon.
            if(i % _checkers != checker_) continue; // Skip if it's not their turn.
            return i; // Return first id that is ready to compound.
        }
        return 0;
    }

    /**
     * Due for compound.
     * @return uint256 Number of addresses that are due for compounding.
     */
    function due() public view returns (uint256)
    {
        uint256 _dueCount_ = 0;
        uint256 _dueDate_ = block.timestamp - _properties.period;
        for(uint256 i = 1; i <= _idTracker.current(); i ++) {
            if(!_compounding[i]) continue;
            if(_lastCompound[i] < _dueDate_) _dueCount_ ++;
        }
        return _dueCount_;
    }

    /**
     * Compound next up.
     * @param id_ Id of next participant.
     * @dev Auto compounds next participant.
     */
    function compound(uint256 id_) public whenNotPaused
    {
        _compound(id_);
    }

    /**
     * Internal compound.
     * @dev Auto compounds participant.
     * @param id_ Id of participant.
     */
    function _compound(uint256 id_) internal
    {
        _lastCompound[id_] = block.timestamp;
        _compoundsLeft[id_] --;
        _totalCompounds[id_] ++;
        _stats.compounds ++;
        if(_compoundsLeft[id_] == 0) {
            _end(id_);
        }
        IVault _vault_ = IVault(addressBook.get("vault"));
        address(_vault_).call(abi.encodePacked(_vault_.autoCompound.selector, abi.encode(_addresses[id_])));
    }

    /**
     * Start auto compound.
     * @param periods_ Number of periods to auto compound.
     */
    function start(uint256 periods_) external payable whenNotPaused
    {
        require(msg.value >= periods_ * _properties.fee, "Insufficient message value");
        _start(msg.sender, periods_);
    }

    /**
     * Internal start.
     * @param participant_ Participant address.
     * @param periods_ Number of periods to auto compound.
     */
    function _start(address participant_, uint256 periods_) internal
    {
        require(periods_ > 0 && periods_ <= _properties.maxPeriods, "Invalid periods");
        uint256 _id_ = _ids[participant_];
        if(_id_ == 0) {
            _idTracker.increment();
            _id_ = _idTracker.current();
            _addresses[_id_] = participant_;
            _ids[participant_] = _id_;
        }
        require(_compoundsLeft[_id_] == 0, "Participant is already auto compounding");
        require(_stats.compounding < _properties.maxParticipants, "Maximum participants reached");
        _compoundsLeft[_id_] = periods_;
        _lastCompound[_id_] = block.timestamp - _properties.period;
        _compounding[_id_] = true;
        _stats.compounding ++;
    }

    /**
     * End auto compound.
     */
    function end() external whenNotPaused
    {
        _end(_ids[msg.sender]);
    }

    /**
     * Internal end auto compound.
     * @param id_ Participant id.
     */
    function _end(uint256 id_) internal
    {
        if(id_ == 0) return;
        _stats.compounding --;
        delete _compoundsLeft[id_];
        delete _lastCompound[id_];
        delete _totalCompounds[id_];
        delete _compounding[id_];
    }

    /**
     * Get vault.
     * @return IVault Vault contract.
     */
    function _getVault() internal view returns (IVault)
    {
        return IVault(addressBook.get("vault"));
    }

    /**
     * Withdraw.
     */
    function withdraw() external onlyOwner
    {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * Set max participants.
     * @param max_ Max participants.
     */
    function setMaxParticipants(uint256 max_) external onlyOwner
    {
        _properties.maxParticipants = max_;
    }

    /**
     * Set fee.
     * @param fee_ New fee.
     */
    function setFee(uint256 fee_) external onlyOwner
    {
        _properties.fee = fee_;
    }

    /**
     * Set max periods.
     * @param max_ Max periods.
     */
    function setMaxPeriods(uint256 max_) external onlyOwner
    {
        _properties.maxPeriods = max_;
    }

    /**
     * Add periods.
     * @param participant_ Participant address.
     * @param periods_ Number of periods to add.
     */
    function addPeriods(address participant_, uint256 periods_) external onlyOwner
    {
        uint256 _id_ = _ids[participant_];
        if(_id_ == 0) return _start(participant_, periods_);
        require(_compoundsLeft[_id_] + periods_ <= _properties.maxPeriods, "Invalid periods");
        _compoundsLeft[_id_] += periods_;
        _compounding[_id_] = true;
    }
}