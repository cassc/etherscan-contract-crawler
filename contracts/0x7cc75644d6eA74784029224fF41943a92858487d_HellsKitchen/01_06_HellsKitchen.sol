// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ISFTD.sol";
import "./ISINS.sol";

/*

  _________                           __  .__              _____                __  .__             ________              .__.__          
 /   _____/__.__. _____ ___________ _/  |_|  |__ ___.__. _/ ____\___________  _/  |_|  |__   ____   \______ \   _______  _|__|  |   ______
 \_____  <   |  |/     \\____ \__  \\   __\  |  <   |  | \   __\/  _ \_  __ \ \   __\  |  \_/ __ \   |    |  \_/ __ \  \/ /  |  |  /  ___/
 /        \___  |  Y Y  \  |_> > __ \|  | |   Y  \___  |  |  | (  <_> )  | \/  |  | |   Y  \  ___/   |    `   \  ___/\   /|  |  |__\___ \ 
/_______  / ____|__|_|  /   __(____  /__| |___|  / ____|  |__|  \____/|__|     |__| |___|  /\___  > /_______  /\___  >\_/ |__|____/____  >
        \/\/          \/|__|       \/          \/\/                                      \/     \/          \/     \/                  \/ 

I see you nerd! ⌐⊙_⊙
*/

contract HellsKitchen is Ownable {

    ISFTD public immutable devilsContract;
    ISINS public immutable sinsContract;

    bool public cookingIsActive;

    error CookingNotLive();
    error NotOwner();

    event DevilCooked(uint256 firstTokenId, uint256 secondTokenId, uint256 cookedDevilTokenId);

    constructor(address sftdContractAddress, address sinsContractAddress) {
        devilsContract = ISFTD(sftdContractAddress);
        sinsContract = ISINS(sinsContractAddress);
    }

    /*
    * Pause cooking if active, make active if paused.
    */
    function flipCookingState() external onlyOwner {
        cookingIsActive = !cookingIsActive;
    }

    function returnOwnership() external onlyOwner {
        devilsContract.transferOwnership(msg.sender);
    }

    function cookDevil(uint256 firstTokenId, uint256 secondTokenId) external {
        if (! cookingIsActive) {
            revert CookingNotLive();
        }

        if (devilsContract.ownerOf(firstTokenId) != msg.sender || devilsContract.ownerOf(secondTokenId) != msg.sender) {
            revert NotOwner();
        }

        uint256 burnCost = 1000;

        if (firstTokenId > 6666) {
            burnCost += 500;
        }

        if (secondTokenId > 6666) {
            burnCost += 500;
        }

        // burn $SINS
        sinsContract.burnFrom(msg.sender, burnCost * 10 ** 18);

        // burn 2 SFTD NFTs
        devilsContract.burn(firstTokenId);
        devilsContract.burn(secondTokenId);

        // mint cooked SFTD NFT
        devilsContract.reserveMint(1, msg.sender);
        uint256 cookedDevilTokenId = devilsContract.tokenByIndex(devilsContract.totalSupply() - 1);

        // fire event in logs
        emit DevilCooked(firstTokenId, secondTokenId, cookedDevilTokenId);
    }
}