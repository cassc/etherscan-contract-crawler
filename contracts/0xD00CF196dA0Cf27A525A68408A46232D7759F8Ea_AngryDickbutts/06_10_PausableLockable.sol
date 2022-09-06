// SPDX-License-Identifier: UNLICENSED
/// @title PausableLLockable
/// @notice Implements Pausable, adding a locking flag
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____
//  __________________/\/\/\/\________________________________________________________________________________
// __________________________________________________________________________________________________________

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract PausableLockable is Ownable, Pausable {
    bool public isChangePausedDisabled = false;

    // Irreversible.
    function disableChangePaused() public onlyOwner {
        isChangePausedDisabled = true;
    }

    function pause() public onlyOwner {
        require(!isChangePausedDisabled, "Disabled");
        _pause();
    }

    function unpause() public onlyOwner {
        require(!isChangePausedDisabled, "Disabled");
        _unpause();
    }
}