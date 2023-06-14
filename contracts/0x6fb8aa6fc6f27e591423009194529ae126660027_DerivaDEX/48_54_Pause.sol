// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { LibDiamondStorageDerivaDEX } from "../../storage/LibDiamondStorageDerivaDEX.sol";
import { LibDiamondStoragePause } from "../../storage/LibDiamondStoragePause.sol";

/**
 * @title Pause
 * @author DerivaDEX
 * @notice This is a facet to the DerivaDEX proxy contract that handles
 *         the logic pertaining to pausing functionality. The purpose
 *         of this is to ensure the system can pause in the unlikely
 *         scenario of a bug or issue materially jeopardizing users'
 *         funds or experience. This facet will be removed entirely
 *         as the system stabilizes shortly. It's important to note that
 *         unlike the vast majority of projects, even during this
 *         short-lived period of time in which the system can be paused,
 *         no single admin address can wield this power, but rather
 *         pausing must be carried out via governance.
 */
contract Pause {
    event PauseInitialized();

    event IsPausedSet(bool isPaused);

    /**
     * @notice Limits functions to only be called via governance.
     */
    modifier onlyAdmin {
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();
        require(msg.sender == dsDerivaDEX.admin, "Pause: must be called by Gov.");
        _;
    }

    /**
     * @notice This function initializes the facet.
     */
    function initialize() external onlyAdmin {
        emit PauseInitialized();
    }

    /**
     * @notice This function sets the paused status.
     * @param _isPaused Whether contracts are paused or not.
     */
    function setIsPaused(bool _isPaused) external onlyAdmin {
        LibDiamondStoragePause.DiamondStoragePause storage dsPause = LibDiamondStoragePause.diamondStoragePause();

        dsPause.isPaused = _isPaused;

        emit IsPausedSet(_isPaused);
    }

    /**
     * @notice This function gets whether the contract ecosystem is
     *         currently paused.
     * @return Whether contracts are paused or not.
     */
    function getIsPaused() public view returns (bool) {
        LibDiamondStoragePause.DiamondStoragePause storage dsPause = LibDiamondStoragePause.diamondStoragePause();

        return dsPause.isPaused;
    }
}