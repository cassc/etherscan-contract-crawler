// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

library BoxType {
    /**
     * @dev Box types
     * BoxType.SEASON1_MAJESTIC_BOX
     * - Majestic box type for season1
     *
     * BoxType.SEASON1_BOOSTER_OMEGA_BOX
     * - Booster Omega box type for season1
     *
     * BoxType.SEASON1_BOOSTER_PREMIUM_BOX
     * - Booster Premium box type for season1
     *
     * BoxType.SEASON1_BOOSTER_BASIC_BOX
     * - Booster Basic box type for season1
     *
     * BoxType.SEASON1_FOUNDERS_BOX
     * - Founders box type for season1
     */
    uint public constant SEASON1_MAJESTIC_BOX = 1;
    uint public constant SEASON1_BOOSTER_OMEGA_BOX = 20;
    uint public constant SEASON1_BOOSTER_PREMIUM_BOX = 21;
    uint public constant SEASON1_BOOSTER_BASIC_BOX = 22;
    uint public constant SEASON1_FOUNDERS_BOX = 30;
}

interface IWLBox is IERC721AUpgradeable {
    function mint(address to, uint256 quantity, bool reserved) external returns (uint256, uint256);
    function burn(uint256[] calldata tokenIds) external;
    function claimCount() external view returns (uint);
}

interface IWLBoxMint {
    function mint(address to, uint256 quantity, bool reserved) external returns (uint256, uint256);
}