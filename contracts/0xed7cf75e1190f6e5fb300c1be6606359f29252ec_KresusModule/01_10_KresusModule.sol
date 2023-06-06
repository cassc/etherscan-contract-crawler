// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./common/Utils.sol";
import "./common/BaseModule.sol";
import "./KresusRelayer.sol";
import "./SecurityManager.sol";
import "./TransactionManager.sol";
import "../infrastructure/IModuleRegistry.sol";

/**
 * @title KresusModule
 * @notice Single module for Kresus vault.
 */
contract KresusModule is BaseModule, KresusRelayer, SecurityManager, TransactionManager {

    string constant public NAME = "KresusModule";
    address public immutable kresusGuardian;

    /**
     * @param _storage deployed instance of storage contract
     * @param _kresusGuardian default guardian from kresus.
     * @param _kresusGuardian default guardian of kresus for recovery and unblocking
     */
    constructor (
        IStorage _storage,
        IModuleRegistry _moduleRegistry,
        address _kresusGuardian,
        address _refundAddress
    )
        BaseModule(_storage, _moduleRegistry)
        KresusRelayer(_refundAddress)
    {
        require(_kresusGuardian != ZERO_ADDRESS, "KM: Invalid address");
        kresusGuardian = _kresusGuardian;
    }

    /**
     * @inheritdoc IModule
     */
    function init(
        address _vault,
        bytes memory _timeDelay
    )
        external
        override
        onlyVault(_vault)
    {
        uint256 newTimeDelay = uint256(bytes32(_timeDelay));
        require(
            newTimeDelay >= MIN_TIME_DELAY &&
            newTimeDelay <= MAX_TIME_DELAY,
            "KM: Invalid Time Delay"
        );
        IVault(_vault).enableStaticCall(address(this));
        _storage.setTimeDelay(_vault, newTimeDelay);
    }

    /**
    * @inheritdoc IModule
    */
    function addModule(
        address _vault,
        address _module,
        bytes memory _initData
    )
        external
        onlySelf()
    {
        require(moduleRegistry.isRegisteredModule(_module), "KM: module is not registered");
        IVault(_vault).authoriseModule(_module, true, _initData);
    }
    
    /**
     * @inheritdoc KresusRelayer
     */
    function getRequiredSignatures(
        address _vault,
        bytes calldata _data
    )
        public
        view
        override
        returns (bool, bool, bool, Signature)
    {
        bytes4 methodId = Utils.functionPrefix(_data);
        bool votingEnabled = _storage.votingEnabled(_vault);
        bool _locked = _storage.isLocked(_vault);

        if (methodId == TransactionManager.multiCall.selector){
            return((!votingEnabled) ? (!_locked, true, true, Signature.Owner):(!_locked, true, true, Signature.OwnerAndGuardian));    
        }
        if (methodId == SecurityManager.setGuardian.selector ||
            methodId == SecurityManager.transferOwnership.selector ||
            methodId == SecurityManager.changeHeir.selector ||
            methodId == SecurityManager.setTimeDelay.selector
        )
        {
            return((!votingEnabled) ? (!_locked, true, false, Signature.Owner):(!_locked, true, false, Signature.OwnerAndGuardian)); 
        }
        if (methodId == SecurityManager.revokeGuardian.selector){
            return((!votingEnabled) ? (true, true, false, Signature.OwnerOrGuardianOrKWG):(true, true, false, Signature.OwnerAndGuardianOrOwnerAndKWG)); 
        }
        if (methodId == SecurityManager.unlock.selector) {
            return((!votingEnabled) ? (_locked, true, false, Signature.KWG):(_locked, true, false, Signature.GuardianOrKWG)); 
        }
        if (methodId == SecurityManager.lock.selector) {
            return((!votingEnabled) ? (!_locked, false, false, Signature.OwnerOrKWG):(!_locked, false, false, Signature.OwnerOrGuardianOrKWG));
        }
        if (methodId == SecurityManager.toggleVoting.selector ||
            methodId == KresusModule.addModule.selector
        )
        {
            return((!votingEnabled) ? (!_locked, false, false, Signature.Owner):(!_locked, false, false, Signature.OwnerAndGuardian)); 
        }
        if(methodId == SecurityManager.executeBequeathal.selector) {
            return ((!votingEnabled)) ? (true, true, false, Signature.OwnerOrKWG):(true, true, false, Signature.OwnerOrGuardianOrKWG);
        }
        revert("KM: unknown method");
    }

    /**
     * @param _data _data The calldata for the required transaction.
     * @return Signature The required signature from {Signature} enum .
     */
    function getCancelRequiredSignatures(
        bytes calldata _data
    )
        public
        pure
        override
        returns(Signature)
    {
        bytes4 methodId = Utils.functionPrefix(_data);
        if(
            methodId == SecurityManager.transferOwnership.selector ||
            methodId == SecurityManager.setGuardian.selector ||
            methodId == SecurityManager.revokeGuardian.selector ||
            methodId == SecurityManager.setTimeDelay.selector ||
            methodId == TransactionManager.multiCall.selector ||
            methodId == SecurityManager.changeHeir.selector
        ){
            return Signature.Owner;
        }
        revert("KM: unknown method");
    }

    /**
    * @notice Validates the signatures provided with a relayed transaction.
    * @param _vault The target vault.
    * @param _signHash The signed hash representing the relayed transaction.
    * @param _signatures The signatures as a concatenated bytes array.
    * @param _option An OwnerSignature enum indicating whether the owner is required, optional or disallowed.
    * @return A boolean indicating whether the signatures are valid.
    */
    function validateSignatures(
        address _vault,
        bytes32 _signHash,
        bytes memory _signatures,
        Signature _option
    ) 
        public 
        view
        override
        returns (bool)
    {
        if ((_signatures.length < 65))
        {
            return false;
        }

        address signer0 = Utils.recoverSigner(_signHash, _signatures, 0);
        address _ownerAddr = IVault(_vault).owner();
    
        if((
            _option == Signature.Owner || 
            _option == Signature.OwnerOrKWG || 
            _option == Signature.OwnerOrGuardianOrKWG
           ) 
           &&
           signer0 == _ownerAddr
        )
        {
            return true;
        }

        if((
            _option == Signature.KWG ||
            _option == Signature.OwnerOrKWG ||
            _option == Signature.GuardianOrKWG ||
            _option == Signature.OwnerOrGuardianOrKWG
           ) 
           &&
           signer0 == kresusGuardian
        )
        {
            return true;
        }

        address _guardianAddr = _storage.getGuardian(_vault);

        if((
            _option == Signature.GuardianOrKWG ||
             _option == Signature.OwnerOrGuardianOrKWG
           )
           &&
           signer0 == _guardianAddr
        )
        {
            return true;
        }

        address signer1 = Utils.recoverSigner(_signHash, _signatures, 1);

        if((
            _option == Signature.OwnerAndGuardian || _option == Signature.OwnerAndGuardianOrOwnerAndKWG
           ) 
           && 
           signer0 == _ownerAddr 
           && 
           signer1 == _guardianAddr
        )
        {
            return true;
        }
        
        if((
            _option == Signature.OwnerAndGuardianOrOwnerAndKWG
           ) 
           && 
           signer0 == _ownerAddr 
           && 
           (signer1 == kresusGuardian)
        )
        {
            return true;
        }
        return false;
    }
}