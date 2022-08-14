// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../access/Access.sol";
import "../common/Utils.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/ILaserMasterGuard.sol";
import "../interfaces/ILaserState.sol";
import "../interfaces/ILaserRegistry.sol";

/////
///////// @todo Add 'removeModule', should be the signature of the owner + guardian
////////        or owner + recovery owner.
/////
contract LaserState is ILaserState, Access {
    address internal constant POINTER = address(0x1); // Pointer for the link list.

    /*//////////////////////////////////////////////////////////////
                         Laser Wallet storage
    //////////////////////////////////////////////////////////////*/

    address public singleton; // Base contract.

    address public owner; // Owner of the wallet.

    address public laserMasterGuard; // Parent module for guard sub modules.

    address public laserRegistry; // Registry that keeps track of authorized modules (Laser and Guards).

    bool public isLocked; // If the wallet is locked, only certain operations can unlock it.

    uint256 public nonce; // Anti-replay number for signed transactions.

    mapping(address => address) internal laserModules; // Mapping of authorized Laser modules.

    /**
     * @notice Restricted, can only be called by the wallet 'address(this)' or module.
     *
     * @param newOwner  Address of the new owner.
     */
    function changeOwner(address newOwner) external access {
        owner = newOwner;
    }

    /**
     * @notice Restricted, can only be called by the wallet 'address(this)' or module.
     *
     * @param newModule Address of a new authorized Laser module.
     */
    function addLaserModule(address newModule) external access {
        require(ILaserRegistry(laserRegistry).isModule(newModule), "Invalid new module");
        laserModules[newModule] = laserModules[POINTER];
        laserModules[POINTER] = newModule;
    }

    function upgradeSingleton(address _singleton) external access {
        //@todo Change require for custom errrors.
        require(_singleton != address(this), "Invalid singleton");
        require(ILaserRegistry(laserRegistry).isSingleton(_singleton), "Invalid master copy");
        singleton = _singleton;
    }

    function activateWallet(
        address _owner,
        address smartSocialRecoveryModule,
        address _laserMasterGuard,
        address laserVault,
        address _laserRegistry,
        bytes calldata smartSocialRecoveryInitData
    ) internal {
        // If owner is not address 0, the wallet was already initialized.
        if (owner != address(0)) revert LaserState__initOwner__walletInitialized();

        if (_owner.code.length != 0 || _owner == address(0)) revert LaserState__initOwner__invalidAddress();

        // We set the owner.
        owner = _owner;

        // check that the module is accepted.
        laserMasterGuard = _laserMasterGuard;
        laserRegistry = _laserRegistry;

        require(ILaserRegistry(laserRegistry).isModule(smartSocialRecoveryModule), "Module not authorized");
        bool success = Utils.call(smartSocialRecoveryModule, 0, smartSocialRecoveryInitData, gasleft());
        require(success);
        laserModules[smartSocialRecoveryModule] = POINTER;

        // We add the guard module.
        ILaserMasterGuard(_laserMasterGuard).addGuardModule(laserVault);
    }
}