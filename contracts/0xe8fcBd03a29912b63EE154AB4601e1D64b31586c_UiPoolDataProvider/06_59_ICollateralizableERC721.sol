// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @title ICollateralizableERC721
 * @author Parallel
 * @notice Defines the basic interface for an CollateralizableERC721.
 **/
interface ICollateralizableERC721 {
    /**
     * @dev get the collateralized balance of a specific user
     */
    function collateralizedBalanceOf(address user)
        external
        view
        returns (uint256);

    /**
     * @dev get the the collateral configuration of a specific token
     */
    function isUsedAsCollateral(uint256 tokenId) external view returns (bool);

    /**
     * @dev changes the collateral state/config of a token
     * @return if the state has changed
     */
    function setIsUsedAsCollateral(
        uint256 tokenId,
        bool useAsCollateral,
        address sender
    ) external returns (bool);

    /**
     * @dev the ids of the token want to change the collateral state
     * @return uint256 (user's old collateralized balance), uint256 (user's new collateralized balance)
     */
    function batchSetIsUsedAsCollateral(
        uint256[] calldata tokenIds,
        bool useAsCollateral,
        address sender
    ) external returns (uint256, uint256);
}