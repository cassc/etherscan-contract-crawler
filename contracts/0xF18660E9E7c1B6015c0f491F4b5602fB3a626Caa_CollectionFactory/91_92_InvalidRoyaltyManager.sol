// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "../interfaces/IRoyaltyManager.sol";
import "../../utils/Ownable.sol";

/**
 * @author [email protected]
 * @dev A basic royalty manager / sample implementation that locks swaps / removals, 
        but doesn't implement supportsInterface
 */
contract InvalidRoyaltyManager is IRoyaltyManager {
    /**
     * @dev See {IRoyaltyManager-canSetGranularRoyalty}
     */
    function canSetGranularRoyalty(
        uint256, /* id */
        Royalty calldata, /* royalty */
        address sender
    ) external view override returns (bool) {
        // owner can set granular royalty (same as without royalty manager)
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {IRoyaltyManager-canSetDefaultRoyalty}
     */
    function canSetDefaultRoyalty(
        Royalty calldata, /* royalty */
        address sender
    ) external view override returns (bool) {
        // owner can set granular royalty (same as without royalty manager)
        return Ownable(msg.sender).owner() == sender;
    }

    /**
     * @dev See {IRoyaltyManager-canSwap}
     */
    function canSwap(
        address, /* newRoyaltyManager */
        address /* sender */
    ) external pure override returns (bool) {
        return false;
    }

    /**
     * @dev See {IRoyaltyManager-canRemoveItself}
     */
    function canRemoveItself(
        address /* sender */
    ) external pure override returns (bool) {
        return false;
    }
}