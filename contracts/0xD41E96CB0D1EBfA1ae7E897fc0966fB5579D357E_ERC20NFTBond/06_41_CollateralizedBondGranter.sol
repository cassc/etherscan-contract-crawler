// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./BondGranter.sol";

/**
 * @title CollateralizedBondGranter
 * @dev This contract contains functions related to the emission or withdrawal of
 * the bonds with collateral
 * @author Ethichub
 */
abstract contract CollateralizedBondGranter is BondGranter {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable private _collateralToken;

    uint256 public collateralMultiplier;
    uint256 public totalCollateralizedAmount;

    mapping(uint256 => uint256) public collaterals;

    event CollateralMultiplierUpdated(uint256 collateralMultiplier);
    event CollateralAssigned(uint256 tokenId, uint256 collateralAmount);
    event CollateralReleased(uint256 tokenId, uint256 collateralAmount);
    event CollateralExcessRemoved(address indexed destination);

    function __CollateralizedBondGranter_init(
        address collateralToken
    )
    internal initializer {
        collateralMultiplier = 5;
        _collateralToken = IERC20Upgradeable(collateralToken);
    }

    function collateralTokenAddress() external view returns (address) {
        return address(_collateralToken);
    }

    /**
     * @dev Sets the number by which the amount of the collateral must be multiplied.
     * In this version will be 5
     * @param multiplierIndex uint256
     */
    function setCollateralMultiplier(uint256 multiplierIndex) external onlyRole(COLLATERAL_BOND_SETTER) {
        require(multiplierIndex > 0, "CollateralizedBondGranter::multiplierIndex is 0");
        collateralMultiplier = multiplierIndex;
        emit CollateralMultiplierUpdated(collateralMultiplier);
    }

    /**
     * @dev Function to withdraw the rest of the collateral that remains in the contract
     * to a specified address
     * @param destination address
     */
    function removeExcessOfCollateral(address destination) external onlyRole(COLLATERAL_BOND_SETTER) {
        uint256 excessAmount = _collateralToken.balanceOf(address(this)) - totalCollateralizedAmount;
        _collateralToken.safeTransfer(destination, excessAmount);
        emit CollateralExcessRemoved(destination);
    }

    /**
     * @dev Returns the amount of collateral that links to the bond
     * @param principal uint256
     */
    function calculateCollateralBondAmount(uint256 principal) public view returns (uint256) {
        return _calculateCollateralBondAmount(principal);
    }

    /**
     * @dev Issues a bond with calculated collateral
     * @param tokenId uint256
     * @param maturity uint256 seconds
     * @param principal uint256 in wei
     * @param imageCID string
     *
     * Requirement:
     *
     * - The contract must have enough collateral
     */
    function _issueBond(
        uint256 tokenId,
        uint256 maturity,
        uint256 principal,
        string memory imageCID
    ) internal override {
        require(_hasCollateral(principal), "CBG::Not enough collateral");
        super._issueBond(tokenId, maturity, principal, imageCID);
        uint256 collateralAmount = _calculateCollateralBondAmount(principal);
        totalCollateralizedAmount = totalCollateralizedAmount + collateralAmount;
        collaterals[tokenId] = collateralAmount;
        emit CollateralAssigned(tokenId, collateralAmount);
    }

    /**
     * @dev Updates totalCollateralizedAmount when a bond is redeemed
     * @param tokenId uint256
     */
    function _redeemBond(uint256 tokenId) internal virtual override returns (uint256) {
        uint256 bondValue = super._redeemBond(tokenId);
        uint256 collateralAmount = collaterals[tokenId];
        totalCollateralizedAmount = totalCollateralizedAmount - collateralAmount;
        emit CollateralReleased(tokenId, collateralAmount);
        return bondValue;
    }

    /**
     * @dev Returns the amount of collateral that links to the bond
     * @param principal uint256
     */
    function _calculateCollateralBondAmount(uint256 principal) internal view returns (uint256) {
        return principal * collateralMultiplier;
    }

    /**
     * @dev Return true if the balace of the contract minus totalCollateralizedAmount is greater or equal to
     * the amount of the bond's collateral
     * @param principal uint256
     */
    function _hasCollateral(uint256 principal) internal view returns (bool) {
        if (_collateralToken.balanceOf(address(this)) - totalCollateralizedAmount >= principal * collateralMultiplier) {
            return true;
        }
        return false;
    }

    uint256[49] private __gap;
}