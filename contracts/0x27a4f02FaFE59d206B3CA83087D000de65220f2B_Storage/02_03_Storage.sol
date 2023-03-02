// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVault} from "../vault/IVault.sol";
import {IStorage} from "./IStorage.sol";

/**
 * @title Storage
 * @notice Base contract for the storage of a vault.
 */
contract Storage is IStorage{

    uint256 public constant MIN_TIME_DELAY = 5 minutes;
    uint256 public constant MAX_TIME_DELAY = 72 hours;

    struct StorageConfig {
        uint256 timeDelay; // time delay in seconds which has to be expired to executed queued requests.
        address heir; // address of the heir to bequeath.
        address guardian; // address of the guardian.
        bool votingEnabled; // true if voting of guardians is enabled else false.
        bool locked; // true is vault is locked else false.
    }
    
    // Vault specific lock storage
    mapping (address => StorageConfig) vaultStorage;

    /**
     * @notice Throws if the caller is not an authorised module.
     */
    modifier onlyModule(address _vault) {
        require(IVault(_vault).authorised(msg.sender), "S: must be an authorized module to call this method");
        _;
    }

     /**
     * @inheritdoc IStorage
     */
    function setLock(
        address _vault,
        bool _lock
    ) external onlyModule(_vault) {
        vaultStorage[_vault].locked = _lock;
    }

    /**
     * @inheritdoc IStorage
     */
    function toggleVoting(
        address _vault
    )
        external
        onlyModule(_vault)
    {
        bool _locked = vaultStorage[_vault].votingEnabled;
        if(!_locked) {
            require(vaultStorage[_vault].guardian != address(0), "S: Cannot enable voting");
        }
        vaultStorage[_vault].votingEnabled = !_locked;   
    }

    /**
     * @inheritdoc IStorage
     */
    function addGuardian(
        address _vault,
        address _guardian
    )
        external
        onlyModule(_vault)
    {
        require(
            vaultStorage[_vault].guardian == address(0),
            "S: Invalid guardian"
        );
        vaultStorage[_vault].guardian = _guardian;
    }

    /**
     * @inheritdoc IStorage
     */
    function revokeGuardian(
        address _vault
    )
        external
        onlyModule(_vault)
    {
        vaultStorage[_vault].guardian = address(0);
        vaultStorage[_vault].votingEnabled = false;
    }

    /**
     * @inheritdoc IStorage
     */
    function setTimeDelay(
        address _vault,
        uint256 _newTimeDelay
    )
        external
        onlyModule(_vault)
    {
        require(
            _newTimeDelay > MIN_TIME_DELAY &&
            _newTimeDelay <= MAX_TIME_DELAY,
            "S: Invalid Time Delay"
        );
        vaultStorage[_vault].timeDelay = _newTimeDelay;
    }
    
    /**
     * @inheritdoc IStorage
     */
    function addHeir(
        address _vault,
        address _heir
    )
        external
        onlyModule(_vault)
    {
        require(
            vaultStorage[_vault].heir == address(0),
            "S: Invalid Heir"
        );
        vaultStorage[_vault].heir = _heir;
    }

    /**
     * @inheritdoc IStorage
     */
    function revokeHeir(
        address _vault
    )
        external
        onlyModule(_vault)
    {
        vaultStorage[_vault].heir = address(0);
    }

    /**
     * @inheritdoc IStorage
     */
    function isLocked(
        address _vault
    ) 
        external
        view
        returns (bool)
    {
        return vaultStorage[_vault].locked;
    }

    /**
     * @inheritdoc IStorage
     */
    function votingEnabled(
        address _vault
    ) 
        external
        view
        returns (bool)
    {
        return vaultStorage[_vault].votingEnabled;       
    }

    /**
     * @inheritdoc IStorage
     */
    function getGuardian(
        address _vault
    )
        external
        view
        returns (address)
    {
        return vaultStorage[_vault].guardian;
    }

    /**
     * @inheritdoc IStorage
     */
    function isGuardian(
        address _vault,
        address _guardian
    )
        external
        view
        returns (bool)
    {
        return (vaultStorage[_vault].guardian == _guardian);
    }

    /**
     * @inheritdoc IStorage
     */
    function getTimeDelay(
        address _vault
    )
        external
        view
        returns(uint256)
    {
        return vaultStorage[_vault].timeDelay;
    }

    /**
     * @inheritdoc IStorage
     */
    function getHeir(
        address _vault
    )
        external
        view
        returns(address)
    {
        return vaultStorage[_vault].heir;
    }
}