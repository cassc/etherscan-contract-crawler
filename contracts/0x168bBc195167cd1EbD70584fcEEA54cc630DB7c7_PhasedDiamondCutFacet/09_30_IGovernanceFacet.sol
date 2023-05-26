// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGovernanceFacet {
    /**
     * @notice Check if the diamond has been initialized.
     * @dev This will get the value from AppStorage.diamondInitialized.
     */
    function isDiamondInitialized() external view returns (bool);

    /**
     * @notice Approve the following upgrade hash: `id`
     * @dev The diamondCut() has been modified to check if the upgrade has been scheduled. This method needs to be called in order
     *      for an upgrade to be executed.
     * @param id This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].
     */
    function createUpgrade(bytes32 id) external;

    /**
     * @notice Update the diamond cut upgrade expiration period.
     * @dev When createUpgrade() is called, it allows a diamondCut() upgrade to be executed. This upgrade must be executed before the
     *      upgrade expires. The upgrade expires based on when the upgrade was scheduled (when createUpgrade() was called) + AppStorage.upgradeExpiration.
     * @param duration The duration until the upgrade expires.
     */
    function updateUpgradeExpiration(uint256 duration) external;

    /**
     * @notice Cancel the following upgrade hash: `id`
     * @dev This will set the mapping AppStorage.upgradeScheduled back to 0.
     * @param id This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].
     */
    function cancelUpgrade(bytes32 id) external;

    /**
     * @notice Get the expiry date for provided upgrade hash.
     * @dev This will get the value from AppStorage.upgradeScheduled  mapping.
     * @param id This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].
     */
    function getUpgrade(bytes32 id) external view returns (uint256 expiry);

    /**
     * @notice Get the upgrade expiration period.
     * @dev This will get the value from AppStorage.upgradeExpiration. AppStorage.upgradeExpiration is added to the block.timestamp to create the upgrade expiration date.
     */
    function getUpgradeExpiration() external view returns (uint256 upgradeExpiration);
}