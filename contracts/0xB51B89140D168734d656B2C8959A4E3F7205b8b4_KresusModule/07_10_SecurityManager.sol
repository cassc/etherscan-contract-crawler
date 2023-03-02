// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./common/Utils.sol";
import "./common/BaseModule.sol";
import "./KresusRelayer.sol";
import "../vault/IVault.sol";

/**
 * @title SecurityManager
 * @notice Abstract module implementing the key security features of the vault: guardians, lock and recovery.
 */
abstract contract SecurityManager is BaseModule {
    event OwnershipTransfered(address indexed vault, address indexed _newOwner);
    event Locked(address indexed vault);
    event Unlocked(address indexed vault);
    event GuardianAdded(address indexed vault, address indexed guardian);
    event GuardianRevoked(address indexed vault, address indexed guardian);
    event VotingToggled(address indexed vault, bool votingEnabled);
    event TimeDelayChanged(address indexed vault, uint256 newTimeDelay);

    /**
     * @notice Throws if the caller is not a guardian for the vault or the module itself.
     */
    modifier onlyGuardianOrSelf(address _vault) {
        require(
            _isSelf(msg.sender) || isGuardian(_vault, msg.sender),
            "SM: must be guardian/self"
        );
        _;
    }

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
        onlyWhenUnlocked(_vault)
    {
        validateNewOwner(_vault, _newOwner);
        IVault(_vault).setOwner(_newOwner);
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("cancelAll(address)", _vault)
        );
        require(success, "SM: cancel all operation failed");
        emit OwnershipTransfered(_vault, _newOwner);
    }

    /**
     * @notice Lets a guardian lock a vault.
     * @param _vault The target vault.
     */
    function lock(address _vault) external onlySelf() onlyWhenUnlocked(_vault) {
        Storage.setLock(_vault, true);
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("cancelAll(address)", _vault)
        );
        require(success, "SM: cancel all operation failed");
        // KresusRelayer(_vault).cancelAll(_vault);
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
        onlyWhenUnlocked(_vault)
    {
        Storage.setTimeDelay(_vault, _newTimeDelay);
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
        onlyWhenLocked(_vault)
    {
        Storage.setLock(_vault, false);
        emit Unlocked(_vault);
    }

    /**
     * @notice To turn votig on and off.
     * @param _vault The target vault.
     */
    function toggleVoting(
        address _vault
    ) 
        external
        onlySelf()
        onlyWhenUnlocked(_vault)
    {
        Storage.toggleVoting(_vault);
        emit VotingToggled(_vault, Storage.votingEnabled(_vault));
    }


    /**
     * @notice Lets the owner add a guardian to its vault.
     * The first guardian is added immediately. All following additions must be confirmed
     * by calling the confirmGuardianAddition() method.
     * @param _vault The target vault.
     * @param _guardian The guardian to add.
     */
    function addGuardian(
        address _vault,
        address _guardian
    ) 
        external 
        onlySelf() 
        onlyWhenUnlocked(_vault) {
        Storage.addGuardian(_vault, _guardian);
        emit GuardianAdded(_vault, _guardian);
    }
    
    /**
     * @notice Lets the owner revoke a guardian from its vault.
     * @dev Revokation must be confirmed by calling the confirmGuardianRevokation() method.
     * @param _vault The target vault.
     * @param _guardian The guardian to revoke.
     */
    function revokeGuardian(
        address _vault,
        address _guardian
    ) external onlySelf() 
    {
        Storage.revokeGuardian(_vault);
        emit GuardianRevoked(_vault, _guardian);
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
        return Storage.isGuardian(_vault, _guardian);
    }

    /**
     * @notice Checks if the vault address is valid to be a new owner.
     * @param _vault The target vault.
     * @param _newOwner The target vault.
     */
    function validateNewOwner(address _vault, address _newOwner) internal view {
        require(_newOwner != address(0), "SM: new owner cannot be null");
        require(!isGuardian(_vault, _newOwner), "SM: new owner cannot be guardian");
    }
}