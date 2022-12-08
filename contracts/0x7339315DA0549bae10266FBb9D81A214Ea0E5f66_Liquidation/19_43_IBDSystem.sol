// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./ILinkageLeaf.sol";

interface IBDSystem is IAccessControl, ILinkageLeaf {
    event AgreementAdded(
        address indexed liquidityProvider,
        address indexed representative,
        uint256 representativeBonus,
        uint256 liquidityProviderBoost,
        uint32 startBlock,
        uint32 endBlock
    );
    event AgreementEnded(
        address indexed liquidityProvider,
        address indexed representative,
        uint256 representativeBonus,
        uint256 liquidityProviderBoost,
        uint32 endBlock
    );

    /**
     * @notice getter function to get liquidity provider agreement
     */
    function providerToAgreement(address)
        external
        view
        returns (
            uint256 liquidityProviderBoost,
            uint256 representativeBonus,
            uint32 endBlock,
            address representative
        );

    /**
     * @notice getter function to get counts
     *         of liquidity providers of the representative
     */
    function representativesProviderCounter(address) external view returns (uint256);

    /**
     * @notice Creates a new agreement between liquidity provider and representative
     * @dev Admin function to create a new agreement
     * @param liquidityProvider_ address of the liquidity provider
     * @param representative_ address of the liquidity provider representative.
     * @param representativeBonus_ percentage of the emission boost for representative
     * @param liquidityProviderBoost_ percentage of the boost for liquidity provider
     * @param endBlock_ The number of the first block when agreement will not be in effect
     * @dev RESTRICTION: Admin only
     */
    function createAgreement(
        address liquidityProvider_,
        address representative_,
        uint256 representativeBonus_,
        uint256 liquidityProviderBoost_,
        uint32 endBlock_
    ) external;

    /**
     * @notice Removes a agreement between liquidity provider and representative
     * @dev Admin function to remove a agreement
     * @param liquidityProvider_ address of the liquidity provider
     * @param representative_ address of the representative.
     * @dev RESTRICTION: Admin only
     */
    function removeAgreement(address liquidityProvider_, address representative_) external;

    /**
     * @notice checks if `account_` is liquidity provider.
     * @dev account_ is liquidity provider if he has agreement.
     * @param account_ address to check
     * @return `true` if `account_` is liquidity provider, otherwise returns false
     */
    function isAccountLiquidityProvider(address account_) external view returns (bool);

    /**
     * @notice checks if `account_` is business development representative.
     * @dev account_ is business development representative if he has liquidity providers.
     * @param account_ address to check
     * @return `true` if `account_` is business development representative, otherwise returns false
     */
    function isAccountRepresentative(address account_) external view returns (bool);

    /**
     * @notice checks if agreement is expired
     * @dev reverts if the `account_` is not a valid liquidity provider
     * @param account_ address of the liquidity provider
     * @return `true` if agreement is expired, otherwise returns false
     */
    function isAgreementExpired(address account_) external view returns (bool);
}