// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IInterestParameters.sol";
import "../access/AccessManagedUpgradeable.sol";
import "../Roles.sol";

/**
 * @title InterestParameters
 * @dev Contains functions related to interests and maturities for the bonds
 * @author Ethichub
 */
abstract contract InterestParameters is Initializable, IInterestParameters, AccessManagedUpgradeable {
    uint256[] public interests;
    uint256[] public maturities;
    uint256 public maxParametersLength;

    function __InterestParameters_init(
        uint256[] calldata _interests,
        uint256[] calldata _maturities
    )
    internal initializer {
        maxParametersLength = 3;
        _setInterestParameters(_interests, _maturities);
    }

    function setInterestParameters(
        uint256[] calldata _interests,
        uint256[] calldata _maturities
    )
    external override onlyRole(INTEREST_PARAMETERS_SETTER) {
        _setInterestParameters(_interests, _maturities);
    }

    function setMaxInterestParams(uint256 value) external override onlyRole(INTEREST_PARAMETERS_SETTER) {
        _setMaxInterestParams(value);
    }

    function getInterestForMaturity(uint256 maturity) public view override returns (uint256) {
        return _getInterestForMaturity(maturity);
    }

    /**
     * @dev Sets the parameters of interests and maturities
     * @param _interests set of interests per second in wei
     * @param _maturities set of maturities in second
     *
     * Requirements:
     *
     * - The length of the array of interests can not be 0
     * - The length of the array of interests can not be greater than maxParametersLength
     * - The length of the array of interests and maturities must be the same
     * - The value of maturities must be in ascending order
     * - The values of interest and maturities can not be 0
     */
    function _setInterestParameters(
        uint256[] calldata _interests,
        uint256[] calldata _maturities
    )
    internal {
        require(_interests.length > 0, "InterestParameters::Interest must be greater than 0");
        require(_interests.length <= maxParametersLength, "InterestParameters::Interest parameters is greater than max parameters");
        require(_interests.length == _maturities.length, "InterestParameters::Unequal input length");
        for (uint256 i = 0; i < _interests.length; ++i) {
            if (i != 0) {
                require(_maturities[i-1] < _maturities[i], "InterestParameters::Unordered maturities");
            }
            require(_interests[i] > 0, "InterestParameters::Can't set zero interest");
            require(_maturities[i] > 0, "InterestParameters::Can't set zero maturity");
        }
        interests = _interests;
        maturities = _maturities;
        emit InterestParametersSet(interests, maturities);
    }

    /**
     * @dev Sets the maximum length of interests and maturities parameters
     * @param value uint256
     *
     * Requirement:
     *
     * - The length value can not be 0
     */
    function _setMaxInterestParams(uint256 value) internal {
        require(value > 0, "InterestParameters::Interest length is 0");
        maxParametersLength = value;
        emit MaxInterestParametersSet(value);
    }

    /**
     * @dev Checks the interest correspondant to the maturity.
     * Needs at least 1 maturity / interest pair.
     * Returns interest per second
     * @param maturity duration of the bond in seconds
     */
    function _getInterestForMaturity(uint256 maturity) internal view returns (uint256) {
        require(maturity >= maturities[0], "InterestParameters::Maturity must be greater than first interest");
        for (uint256 i = interests.length - 1; i >= 0; --i) {
            if (maturity >= maturities[i]) {
                return interests[i];
            }
        }
        return interests[0];
    }

    uint256[49] private __gap;
}