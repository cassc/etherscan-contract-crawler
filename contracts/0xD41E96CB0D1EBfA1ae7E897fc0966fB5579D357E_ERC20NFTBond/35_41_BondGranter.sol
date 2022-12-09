// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../utils/InterestCalculator.sol";
import "./InterestParameters.sol";

/**
 * @title BondGranter
 * @dev This contract contains functions related to the emission or withdrawal of the bonds
 * @author Ethichub
 */
abstract contract BondGranter is Initializable, InterestParameters, InterestCalculator {
    struct Bond {
        uint256 mintingDate;
        uint256 maturity;
        uint256 principal;
        uint256 interest;
        bool redeemed;
        string imageCID;
    }

    mapping(uint256 => Bond) public bonds;

    event BondIssued(uint256 tokenId, uint256 mintingDate, uint256 maturity, uint256 principal, uint256 interest, string imageCID);
    event BondRedeemed(uint256 tokenId, uint256 redeemDate, uint256 maturity, uint256 withdrawn, uint256 interest, string imageCID);

    /**
     * @dev Assigns a bond with its parameters
     * @param tokenId uint256
     * @param maturity uint256 seconds
     * @param principal uint256 in wei
     * @param imageCID string
     *
     * Requirements:
     *
     * - Principal amount can not be 0
     * - Maturity must be greater than the first element of the set of interests
     */
    function _issueBond(uint256 tokenId, uint256 maturity, uint256 principal, string memory imageCID) internal virtual {
        require(principal > 0, "BondGranter::Principal is 0");
        require(maturity >= maturities[0], "BondGranter::Maturity must be greater than the first interest");
        uint256 interest = super.getInterestForMaturity(maturity);
        bonds[tokenId] = Bond(block.timestamp, maturity, principal, interest, false, imageCID);
        emit BondIssued(tokenId, block.timestamp, maturity, principal, interest, imageCID);
    }

    /**
     * @dev Checks eligilibility to redeem the bond and returns its value
     * @param tokenId uint256
     */
    function _redeemBond(uint256 tokenId) internal virtual returns (uint256) {
        Bond memory bond = bonds[tokenId];
        require((bond.maturity + bond.mintingDate) < block.timestamp, "BondGranter::Can't redeem yet");
        require(!bond.redeemed, "BondGranter::Already redeemed");
        bonds[tokenId].redeemed = true;
        emit BondRedeemed(tokenId, block.timestamp, bond.maturity, _bondValue(tokenId), bond.interest, bond.imageCID);
        return _bondValue(tokenId);
    }

    /**
     * @dev Returns the actual value of the bond with its interest
     * @param tokenId uint256
     */
    function _bondValue(uint256 tokenId) internal view virtual returns (uint256) {
        Bond memory bond = bonds[tokenId];
        return bond.principal + bond.principal * super.simpleInterest(bond.interest, bond.maturity) / 100 / 1000000000000000000;
    }

    uint256[49] private __gap;

}