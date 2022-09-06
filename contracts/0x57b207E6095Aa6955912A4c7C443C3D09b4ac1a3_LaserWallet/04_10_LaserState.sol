// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../access/Access.sol";
import "../common/Utils.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/ILaserState.sol";

contract LaserState is ILaserState, Access {
    address internal constant pointer = address(0x1);

    address public singleton;

    address public owner;

    address public laserGuard;

    bool public isLocked;

    uint256 public nonce;

    mapping(address => address) internal laserModules;

    function changeOwner(address newOwner) external access {
        owner = newOwner;
    }

    function addLaserModule(address newModule) external access {
        laserModules[newModule] = laserModules[pointer];
        laserModules[pointer] = newModule;
    }

    function changeLaserGuard(address newLaserGuard) external access {
        laserGuard = newLaserGuard;
    }

    function upgradeSingleton(address _singleton) external access {
        // if (_singleton == address(this)) revert Singleton__upgradeSingleton__incorrectAddress();

        if (!IERC165(_singleton).supportsInterface(0xae029e0b)) {
            //bytes4(keccak256("I_AM_LASER")))
            revert LaserState__upgradeSingleton__notLaser();
        }

        singleton = _singleton;
    }

    function activateWallet(
        address _owner,
        address laserModule,
        bytes calldata laserModuleData
    ) internal {
        // If owner is not address 0, the wallet was already initialized ...
        if (owner != address(0)) revert LaserState__initOwner__walletInitialized();

        if (_owner.code.length != 0 || _owner == address(0)) revert LaserState__initOwner__addressWithCode();
        owner = _owner;

        if (laserModule != address(0)) {
            bool success = Utils.call(laserModule, 0, laserModuleData, gasleft());
            require(success);
            laserModules[laserModule] = pointer;
        }
    }
}