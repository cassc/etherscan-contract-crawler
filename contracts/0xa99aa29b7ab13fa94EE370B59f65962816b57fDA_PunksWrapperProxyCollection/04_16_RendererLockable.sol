// SPDX-License-Identifier: UNLICENSED
/// @title RenderContractLockable
/// @notice RenderContractLockable
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____
//  __________________/\/\/\/\________________________________________________________________________________
// __________________________________________________________________________________________________________

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract RendererLockable is Ownable {
    address public renderer;
    bool public isChangeRendererDisabled = false;

    // Irreversible.
    function disableChangeRenderer() public onlyOwner {
        isChangeRendererDisabled = true;
    }

    // In case there's a bug, but eventually disabled
    function setRenderer(address _renderer) public onlyOwner {
        require(!isChangeRendererDisabled, "Disabled");
        renderer = _renderer;
    }
}