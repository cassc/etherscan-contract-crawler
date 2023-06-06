// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./common/BaseModule.sol";
import "../vault/IVault.sol";

/**
 * @title SecurityManager
 * @notice Abstract module implementing the key security features of the vault: guardians, lock and recovery.
 */
abstract contract SecurityManager is BaseModule {

    uint256 public constant MIN_TIME_DELAY = 5 minutes;
    uint256 public constant MAX_TIME_DELAY = 72 hours;

    event OwnershipTransferred(address indexed vault, address indexed _newOwner);
    event Bequeathed(address indexed vault, address indexed _newOwner);
    event Locked(address indexed vault);
    event Unlocked(address indexed vault);
    event GuardianAdded(address indexed vault, address indexed guardian);
    event GuardianRevoked(address indexed vault);
    event HeirChanged(address indexed vault, address indexed heir);
    event VotingToggled(address indexed vault, bool votingEnabled);
    event TimeDelayChanged(address indexed vault, uint256 newTimeDelay);

    /**
     * @notice Lets the owner transfer the vault ownership. This is executed immediately.
     * @param _vault The target vault.
     * @param _newOwner The address to which ownership should be transferred.
     */
    function transferOwnership(
        address _vault,
        address _newOwner
    )
        external
        onlySelf()
    {
        changeOwner(_vault, _newOwner);
        emit OwnershipTransferred(_vault, _newOwner);
    }

    /**
     * @notice Lets a guardian lock a vault.
     * @param _vault The target vault.
     */
    function lock(address _vault) external onlySelf() {
        _storage.setLock(_vault, true);
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("cancelAll(address)", _vault)
        );
        require(success, "SM: cancel all operation failed");
        emit Locked(_vault);
    }

    /**
     * @notice Updates the TimeDelay
     * @param _vault The target vault.
     * @param _newTimeDelay The new DelayTime to update.
     */
    function setTimeDelay(
        address _vault,
        uint256 _newTimeDelay
    )
        external
        onlySelf()
    {
        require(
            _newTimeDelay >= MIN_TIME_DELAY &&
            _newTimeDelay <= MAX_TIME_DELAY,
            "SM: Invalid Time Delay"
        );
        _storage.setTimeDelay(_vault, _newTimeDelay);
        emit TimeDelayChanged(_vault, _newTimeDelay);
    }

    /**
     * @notice Lets a guardian unlock a locked vault.
     * @param _vault The target vault.
     */
    function unlock(
        address _vault
    ) 
        external
        onlySelf()
    {
        _storage.setLock(_vault, false);
        emit Unlocked(_vault);
    }

    /**
     * @notice To turn voting on and off.
     * @param _vault The target vault.
     */
    function toggleVoting(
        address _vault
    )
        external
        onlySelf()
    {
        bool _enabled = _storage.votingEnabled(_vault);
        if(!_enabled) {
            require(_storage.getGuardian(_vault) != ZERO_ADDRESS, "SM: Cannot enable voting");
        }
        _storage.toggleVoting(_vault);
        emit VotingToggled(_vault, !_enabled);
    }


    /**
     * @notice Lets the owner add a guardian to its vault.
     * @param _vault The target vault.
     * @param _guardian The guardian to add.
     */
    function setGuardian(
        address _vault,
        address _guardian
    ) 
        external 
        onlySelf()
    {
        _storage.setGuardian(_vault, _guardian);
        emit GuardianAdded(_vault, _guardian);
    }
    
    /**
     * @notice Lets the owner revoke a guardian from its vault.
     * @param _vault The target vault.
     */
    function revokeGuardian(
        address _vault
    ) external onlySelf() 
    {
        _storage.revokeGuardian(_vault);
        bool _enabled = _storage.votingEnabled(_vault);
        if(_enabled) {
            _storage.toggleVoting(_vault);
        }
        emit GuardianRevoked(_vault);
    }

    function changeHeir(
        address _vault,
        address _newHeir
    ) 
        external
        onlySelf()
    {
        require(
            _newHeir != ZERO_ADDRESS,
            "SM: Invalid Heir"
        );
        _storage.setHeir(_vault, _newHeir);
        emit HeirChanged(_vault, _newHeir);
    }

    function executeBequeathal(
        address _vault
    )
        external
        onlySelf()
    {
        address heir = _storage.getHeir(_vault);
        changeOwner(_vault, heir);
        _storage.setHeir(_vault, ZERO_ADDRESS);
        emit Bequeathed(_vault, heir);
    }

    /**
     * @notice Checks if an address is a guardian for a vault.
     * @param _vault The target vault.
     * @param _guardian The address to check.
     * @return _isGuardian `true` if the address is a guardian for the vault otherwise `false`.
     */
    function isGuardian(
        address _vault,
        address _guardian
    ) 
        public
        view
        returns(bool _isGuardian)
    {
        return _storage.isGuardian(_vault, _guardian);
    }

    function changeOwner(address _vault, address _newOwner) internal {
        validateNewOwner(_vault, _newOwner);
        IVault(_vault).setOwner(_newOwner);
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("cancelAll(address)", _vault)
        );
        require(success, "SM: cancel all operation failed");
    }

    /**
     * @notice Checks if the vault address is valid to be a new owner.
     * @param _vault The target vault.
     * @param _newOwner The target vault.
     */
    function validateNewOwner(address _vault, address _newOwner) internal view {
        require(_newOwner != ZERO_ADDRESS, "SM: new owner cannot be null");
        require(!isGuardian(_vault, _newOwner), "SM: new owner cannot be guardian");
    }
}