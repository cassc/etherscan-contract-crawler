//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IYardbois.sol";
import "../interfaces/IYardboisResources.sol";

contract Mines is ReentrancyGuardUpgradeable {
    error Unauthorized();
    error InvalidLength();
    
    event GnomeDeposit(
        uint256 indexed gnomeId,
        address indexed owner
    );
    event GnomeWithdrawal(
        uint256 indexed gnomeId,
        address indexed owner,
        bool unpaid
    );
    event RewardsClaim(
        uint256 indexed gnomeId,
        address indexed owner,
        uint256 oreClaimed,
        uint256 gemsClaimed
    );

    uint256 public constant ORE_INDEX = uint256(keccak256("ORE"));
    uint256 public constant GEM_INDEX = uint256(keccak256("GEM"));

    uint256 public constant ORE_DAY = 100;
    uint256 public constant ORE_DAY_PROFICIENT = 150;
    uint256 public constant GEMS_DAY = 1;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IYardbois public immutable GNOMES;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IYardboisResources public immutable RESOURCES;

    struct GnomeData {
        address owner;
        uint40 lastOreClaimTime;
        uint40 lastGemClaimTime;
    }

    mapping(uint256 => GnomeData) public gnomeData;

    //this constructor is fine even tho this is an upgradeable contract as we are
    //only initializing immutable variables
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IYardbois _gnomes, IYardboisResources _resources) {
        GNOMES = _gnomes;
        RESOURCES = _resources;
    }

    function depositGnomes(uint256[] calldata _ids) external nonReentrant {
        uint256 _length = _ids.length;
        if (_length == 0)
            revert InvalidLength();
        for (uint256 i; i < _length; ++i) {
            uint256 _idx = _ids[i];
            GNOMES.setGnomeWorking(_idx);
            GNOMES.transferFrom(msg.sender, address(this), _idx);
            gnomeData[_idx] = GnomeData(
                msg.sender,
                uint40(block.timestamp),
                uint40(block.timestamp)
            );

            emit GnomeDeposit(_idx, msg.sender);
        }
    }

    function withdrawGnomes(uint256[] calldata _ids, bool _unpaid)
        external
        nonReentrant
    {
        uint256 _totalGems;
        uint256 _totalOre;

        uint256 _length = _ids.length;
        if (_length == 0)
            revert InvalidLength();
        for (uint256 i; i < _length; ++i) {
            uint256 _idx = _ids[i];
            GnomeData memory _data = gnomeData[_idx];

            if (_data.owner != msg.sender) revert Unauthorized();

            (
                uint256 _oreAmount,
                uint256 _gemAmount,
                ,

            ) = _calculateGnomeRewards(_idx, _data);

            delete gnomeData[_idx];

            if (_oreAmount != 0 || _gemAmount != 0) {
                if (_oreAmount != 0) _totalOre += _oreAmount;
                if (_gemAmount != 0) _totalGems += _gemAmount;

                emit RewardsClaim(_idx, msg.sender, _oreAmount, _gemAmount);
            }

            GNOMES.transferFrom(address(this), msg.sender, _idx);
            GNOMES.setGnomeNotWorking(_idx, _unpaid);

            emit GnomeWithdrawal(_idx, msg.sender, _unpaid);
        }

        if (_unpaid) {
            if (_totalGems != 0)
                RESOURCES.mint(msg.sender, GEM_INDEX, _totalGems);
        } else {
            if (_totalGems > _length) {
                RESOURCES.mint(msg.sender, GEM_INDEX, _totalGems - _length);
            } else if (_totalGems < _length) {
                RESOURCES.burn(msg.sender, GEM_INDEX, _length - _totalGems);
            }
        }

        if (_totalOre != 0)
            RESOURCES.mint(msg.sender, ORE_INDEX, _totalOre);
    }

    function claimRewards(uint256[] calldata _ids) external nonReentrant {
        uint256 _totalGems;
        uint256 _totalOre;

        uint256 _length = _ids.length;
        if (_length == 0)
            revert InvalidLength();
        for (uint256 i; i < _length; ++i) {
            uint256 _idx = _ids[i];
            GnomeData memory _data = gnomeData[_idx];

            if (_data.owner != msg.sender) revert Unauthorized();

            uint256 _oreAmount;
            uint256 _gemAmount;
            (
                _oreAmount,
                _gemAmount,
                _data.lastOreClaimTime,
                _data.lastGemClaimTime
            ) = _calculateGnomeRewards(_idx, _data);

            if (_oreAmount > 0 || _gemAmount > 0) {
                //no need to write new claim times to storage if 0 rewards.
                //This can happen in two cases:
                // - gnome doesn't have any rewards yet: in this case the claim time will be the same as the previous claim time
                // - gnome's happiness ran out: in this case we only need to write to storage when the happiness goes back up, handled by signalHappinessBonus
                gnomeData[_idx] = _data;
                _totalGems += _gemAmount;
                _totalOre += _oreAmount;

                emit RewardsClaim(_idx, msg.sender, _oreAmount, _gemAmount);
            }
        }

        if (_totalOre != 0)
            RESOURCES.mint(msg.sender, ORE_INDEX, _totalOre);
        if (_totalGems != 0)
            RESOURCES.mint(msg.sender, GEM_INDEX, _totalGems);
    }

    function signalHappinessBonus(uint256 _idx) external {
        if (msg.sender != address(GNOMES)) revert Unauthorized();

        GnomeData memory _data = gnomeData[_idx];

        uint256 _oreAmount;
        uint256 _gemAmount;
        (
            _oreAmount,
            _gemAmount,
            _data.lastOreClaimTime,
            _data.lastGemClaimTime
        ) = _calculateGnomeRewards(_idx, _data);
        
        gnomeData[_idx] = _data;

        if (_oreAmount != 0 || _gemAmount != 0) {
            if (_oreAmount != 0)
                RESOURCES.mint(_data.owner, ORE_INDEX, _oreAmount);
            if (_gemAmount != 0)
                RESOURCES.mint(_data.owner, GEM_INDEX, _gemAmount);

            emit RewardsClaim(_idx, msg.sender, _oreAmount, _gemAmount);
        }
    }

    function pendingRewards(uint256 _idx)
        external
        view
        returns (uint256 _pendingOre, uint256 _pendingGems)
    {
        GnomeData memory _data = gnomeData[_idx];

        if (_data.owner == address(0)) return (0, 0);

        (_pendingOre, _pendingGems, , ) = _calculateGnomeRewards(_idx, _data);
    }

    function isProficient(uint256 _idx) public pure returns (bool) {
        return uint256(keccak256(abi.encode(_idx))) % 5 == 0;
    }

    function _calculateGnomeRewards(uint256 _idx, GnomeData memory _data)
        internal
        view
        returns (
            uint256 _oreAmount,
            uint256 _gemAmount,
            uint40 _lastOreClaimTime,
            uint40 _lastGemClaimTime
        )
    {
        IYardbois.GnomeStatus memory _status = GNOMES.gnomeStatus(_idx);
        uint40 _zeroHappinessTimestamp = _status.happinessSnapshotTime +
            _status.happinessCounter;

        uint256 _orePerDay = isProficient(_idx) ? ORE_DAY_PROFICIENT : ORE_DAY;

        //if the gnome's happiness reached 0, only calculate rewards for when the gnome's happiness was non zero
        //and set last claim time to now (gnome stops mining)
        if (block.timestamp > _zeroHappinessTimestamp) {
            (_oreAmount, ) = _calculateRewards(
                _zeroHappinessTimestamp,
                _data.lastOreClaimTime,
                _orePerDay
            );

            (_gemAmount, ) = _calculateRewards(
                _zeroHappinessTimestamp,
                _data.lastGemClaimTime,
                GEMS_DAY
            );

            _lastOreClaimTime = uint40(block.timestamp);
            _lastGemClaimTime = uint40(block.timestamp);
        } else {
            (_oreAmount, _lastOreClaimTime) = _calculateRewards(
                block.timestamp,
                _data.lastOreClaimTime,
                _orePerDay
            );

            (_gemAmount, _lastGemClaimTime) = _calculateRewards(
                block.timestamp,
                _data.lastGemClaimTime,
                GEMS_DAY
            );
        }
    }

    function _calculateRewards(
        uint256 _currentTime,
        uint256 _lastClaimTime,
        uint256 _dailyRewards
    ) internal pure returns (uint256 _rewards, uint40 _effectiveClaimTime) {
        if (_currentTime <= _lastClaimTime) return (0, uint40(_lastClaimTime));
        uint256 _elapsed = _currentTime - _lastClaimTime;
        _rewards = (_dailyRewards * _elapsed) / 1 days;
        _effectiveClaimTime = uint40(_lastClaimTime) + uint40((_rewards * 1 days) / _dailyRewards);
    }
}