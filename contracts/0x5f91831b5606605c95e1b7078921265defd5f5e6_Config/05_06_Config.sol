// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "../lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IConfig.sol";

contract Config is Ownable, IConfig, ReentrancyGuard {
    using Address for address;

    // add protocol fee
    int128 public totalFeePercentage = 100000;
    int128 public protocolFee;
    address public protocolTreasury;

    // Global curve operational state
    bool public globalFrozen = false;
    bool public flashable = false;

    bool public globalGuarded = false;
    mapping (address => bool) public poolGuarded;

    uint256 public globalGuardAmt;
    mapping (address => uint256) public poolGuardAmt;
    mapping (address => uint256) public poolCapAmt;

    event GlobalFrozenSet(bool isFrozen);
    event FlashableSet(bool isFlashable);
    event TreasuryUpdated(address indexed newTreasury);
    event ProtocolFeeUpdated(address indexed treasury, int128 indexed fee);
    event GlobalGuardSet(bool isGuarded);
    event GlobalGuardAmountSet (uint256 amount);
    event PoolGuardSet (address indexed pool, bool isGuarded);
    event PoolGuardAmountSet (address indexed pool, uint256 guardAmount);
    event PoolCapSet (address indexed pool, uint256 cap);

    constructor (
        int128 _protocolFee,
        address _treasury) {
            require(totalFeePercentage >= _protocolFee, "CurveFactory/fee-cant-be-over-100%");
            require(_treasury != address(0), "CurveFactory/zero-address");
            protocolFee = _protocolFee;
            protocolTreasury = _treasury;
        }

    function getGlobalFrozenState() external view virtual override returns (bool) {
        return globalFrozen;
    }
    
    function getFlashableState() external view virtual override returns (bool) {
        return flashable;
    }

    function getProtocolFee() external view virtual override returns (int128) {
        return protocolFee;
    }

    function getProtocolTreasury() external view virtual override returns (address) {
        return protocolTreasury;
    }

    function setGlobalFrozen(bool _toFreezeOrNotToFreeze) external virtual override onlyOwner {
        emit GlobalFrozenSet(_toFreezeOrNotToFreeze);

        globalFrozen = _toFreezeOrNotToFreeze;
    }

    function toggleGlobalGuarded () external  virtual override onlyOwner nonReentrant {
        globalGuarded = !globalGuarded;
        emit GlobalGuardSet(globalGuarded);
    }

    function setPoolGuarded (address pool, bool guarded ) external  virtual override onlyOwner nonReentrant {
        poolGuarded[pool] = guarded;
        emit PoolGuardSet(pool, guarded);
    }

    function setGlobalGuardAmount (uint256 amount) external  virtual override onlyOwner nonReentrant {
        globalGuardAmt = amount - 1e6;
        emit GlobalGuardAmountSet (globalGuardAmt);
    }

    function setPoolCap (address pool, uint256 cap) external nonReentrant virtual override onlyOwner {
        poolCapAmt[pool] = cap;
        emit PoolCapSet(pool, cap);
    }

    function setPoolGuardAmount (address pool, uint256 amount) external nonReentrant virtual override onlyOwner {
        poolGuardAmt[pool] = amount - 1e6;
        emit PoolGuardAmountSet(pool, amount);
    }

    function isPoolGuarded (address pool) external view override returns (bool) {
        bool _poolGuarded = poolGuarded[pool];
        if(!_poolGuarded){
            return globalGuarded;
        }else{
            return true;
        }
    }

    function getPoolGuardAmount (address pool) external view override returns (uint256) {
        uint256 _poolGuardAmt = poolGuardAmt[pool];
        if(_poolGuardAmt == 0) {
            return globalGuardAmt;
        }else{
            return _poolGuardAmt;
        }
    }

    function getPoolCap (address pool) external view override returns (uint256) {
        return poolCapAmt[pool];
    }
    
    function setFlashable(bool _toFlashOrNotToFlash) external  virtual override onlyOwner nonReentrant {
        emit FlashableSet(_toFlashOrNotToFlash);

        flashable = _toFlashOrNotToFlash;
    }

    function updateProtocolTreasury(address _newTreasury) external  virtual override onlyOwner nonReentrant {
        require(_newTreasury != protocolTreasury, "CurveFactory/same-treasury-address");
        require(_newTreasury != address(0), "CurveFactory/zero-address");
        protocolTreasury = _newTreasury;
        emit TreasuryUpdated(protocolTreasury);
    }

    function updateProtocolFee(int128 _newFee) external virtual override onlyOwner nonReentrant {
        require(totalFeePercentage >= _newFee, "CurveFactory/fee-cant-be-over-100%");
        require(_newFee != protocolFee, "CurveFactory/same-protocol-fee");
        protocolFee = _newFee;
        emit ProtocolFeeUpdated(protocolTreasury, protocolFee);
    }
}