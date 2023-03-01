// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "../contracts-generated/Versioned.sol";
import "./base/Utils.sol";

/**
 * @dev Implementation of a multi-addresses validator contract
 */
contract Validator is PausableUpgradeable, 
                      AccessControlUpgradeable, 
                      Versioned 
{
    /// @custom:oz-renamed-from __gap
    uint256[1000] private _gap_;    
    
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Mapping from address to enabled flag for all the validators
    mapping(address => bool) private _validators;
    
    // Number of enabled validators
    uint256 private _numValidators;
    
    // Validation threshold
    uint256 private _validationThreshold;

    /**
     * @dev Emitted when `validator` is added
     */
    event ValidatorAdded(address validator);

    /**
     * @dev Emitted when `validator` is removed
     */
    event ValidatorRemoved(address validator);
    
    /**
     * @dev Emitted when the validation threshold is changed from `oldThreshold` to `newThreshold`
     */
    event ThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initialize the contract
     * `admin` receives {DEFAULT_ADMIN_ROLE} and {PAUSER_ROLE}, assumes msg.sender if not specified.
     */
    function initialize(address admin) 
        initializer 
        public 
    {
        require(Utils.isKnownNetwork(), "unknown network");
        __Pausable_init();
        __AccessControl_init();

        if (admin == address(0)) {
            admin = _msgSender();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
         
        _validationThreshold = type(uint256).max;
    }

    /**
     * @dev Pause the contract, requires `PAUSER_ROLE`
     */
    function pause() 
        public 
        onlyRole(PAUSER_ROLE) 
    {
        _pause();
    }

    /**
     * @dev Unpause the contract, requires `PAUSER_ROLE`
     */
    function unpause() 
        public 
        onlyRole(PAUSER_ROLE) 
    {
        _unpause();
    }

    /**
     * @dev Return if `account` is a validator
     */
    function isValidator(address account) 
        public 
        view 
        returns (bool) 
    {
        return _validators[account];
    }

    /**
     * @dev Return the number of validators
     */
    function numValidators() 
        public 
        view 
        returns (uint256) 
    {
        return _numValidators;
    }

    /**
     * @dev Return the validation threshold
     */
    function threshold() 
        public 
        view 
        returns (uint256) 
    {
        return _validationThreshold;
    }

    /**
     * @dev Admin function to update the validation threshold, requires `DEFAULT_ADMIN_ROLE`
     * Emits {ThresholdUpdated}
     */
    function adminSetThreshold(uint256 newThreshold) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        require(newThreshold <= _numValidators, "not enough validators");
        uint256 old = _validationThreshold;
        _validationThreshold = newThreshold;
        emit ThresholdUpdated(old, newThreshold);
    }

    /**
     * @dev Admin function to add `account` as validator, requires `DEFAULT_ADMIN_ROLE`
     * Emits {ValidatorAdded}
     */
    function adminAddValidator(address account) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        require(account != address(0x0), "bad address");
        require(!isValidator(account), "already is");
        _validators[account] = true;
        _numValidators += 1;
        emit ValidatorAdded(account);
    }

    /**
     * @dev Admin function to remove `account` as validator, requires `DEFAULT_ADMIN_ROLE`
     * Emits {ValidatorAdded}
     */
    function adminRemoveValidator(address account) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        require(isValidator(account), "not a validator");
        require(_numValidators - 1 >= _validationThreshold, "not enough validators");
        _validators[account] = false;
        _numValidators -= 1;
        emit ValidatorRemoved(account);
    }

    /**
     * @dev Helper function to split `signature` at `offset` into r, s, v components
     */
    function _splitSignature(bytes memory signature, uint256 signatureIndex) 
        internal 
        pure 
        returns (bytes32 r, bytes32 s, uint8 v) 
    {
        // first 32 bytes is the length of "signature"
        uint256 offset = 32 + signatureIndex * 65;
        assembly {
            r := mload(add(signature, offset))
            s := mload(add(add(signature, offset), 32))
            v := byte(0, mload(add(add(signature, offset), 64)))
        }
    }

    /**
     * @dev Verify if `message` is signed by enough validators whose signatures are in `signature`
     * The length of the signature is expected to be number of validators * 65
     */
    function verifySignature(bytes memory message, bytes memory signature) 
        public 
        view 
        whenNotPaused 
        returns (bool) 
    {
        require(_numValidators > 0, "no validator");

        bytes32 messageHash = ECDSAUpgradeable.toEthSignedMessageHash(message);
        uint256 numVerifications = 0;
        uint256 numSignatures = signature.length / 65;
        address[] memory usedValidators = new address[](numSignatures);
        for (uint256 index = 0; index < numSignatures; index++) {
            (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature, index);
            address recovered = ecrecover(messageHash, v, r, s);

            if (_validators[recovered]) {
                // check for duplicated validators
                bool duplicated = false;
                for (uint256 index2 = 0; index2 < usedValidators.length; index2++) {
                    if (usedValidators[index2] == recovered) {
                        duplicated = true;
                        break;
                    }
                }

                if (!duplicated) {
                    numVerifications += 1;
                    usedValidators[index] = recovered;
                }
            }
        }

        return numVerifications >= _validationThreshold;
    }
}