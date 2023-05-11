// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Crowdsale.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title GoochCrowdsale
 * @dev Crowdsale with per-beneficiary caps.
 */
contract GoochCrowdsale is Crowdsale {
    uint256 private _perBeneficiaryCap;
    uint256 private _totalCap;

    bool private _publicSale;

    mapping(address => uint256) private _contributions;
    mapping(address => uint256) private _caps;

    function initialize(
        bool publicSale_,
        uint256 perBeneficiaryCap_,
        uint256 totalCap_,
        uint256 rate_,
        address payable wallet_,
        IERC20 token_
    ) external initializer {
        __Ownable_init();
        __Crowdsale_init(rate_, wallet_, token_);

        _publicSale = publicSale_;

        _perBeneficiaryCap = perBeneficiaryCap_;
        _totalCap = totalCap_;
    }

    /**
     * @dev Sets a specific beneficiary's maximum contribution.
     * @param beneficiary Address to be capped
     * @param cap Wei limit for individual contribution
     */
    function setCap(address beneficiary, uint256 cap) external onlyOwner {
        _caps[beneficiary] = cap;
    }

    /**
     * @dev Sets multiple beneficiaries' maximum contribution.
     * @param beneficiaries_ Addresses to be capped
     * @param caps_ Wei limit for individual contributions
     */
    function setCaps(
        address[] calldata beneficiaries_,
        uint256[] calldata caps_
    ) external onlyOwner {
        require(
            beneficiaries_.length == caps_.length,
            "GoochCrowdsale: mismatched array lengths"
        );
        uint256 countBeneficiaries = beneficiaries_.length;
        uint256 cap;
        address beneficiary;
        for (uint256 i = 0; i < countBeneficiaries; ) {
            beneficiary = beneficiaries_[i];
            cap = caps_[i];
            _caps[beneficiary] = cap;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns the cap of a specific beneficiary.
     * @param beneficiary Address whose cap is to be checked
     * @return Current cap for individual beneficiary
     */
    function getCap(address beneficiary) public view returns (uint256) {
        return _caps[beneficiary];
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return weiRaised() >= _totalCap;
    }

    /**
     * @dev Sets/updates the whitelist.
     * @param cap Wei limit for individual contribution
     */
    function setTotalCap(uint256 cap) external onlyOwner {
        _totalCap = cap;
    }

    /**
     * @dev Returns the total cap
     * @return Current cap for individual beneficiary
     */
    function getTotalCap() public view returns (uint256) {
        return _totalCap;
    }

    /**
     * @dev Returns the cap set for all the beneficiaries
     * @return Current cap for individual beneficiary
     */
    function getPerBeneficiaryCap() public view returns (uint256) {
        return _perBeneficiaryCap;
    }

    /**
     * @dev Toggles publicSale
     * @param publicSale_ Whether or not it is a public sale
     *
     */
    function setPublicSale(bool publicSale_) external onlyOwner {
        _publicSale = publicSale_;
    }

    /**
     * @dev Returns publicSale
     * @return Whether or not it is a public sale
     *
     */
    function getPublicSale() public view returns (bool) {
        return _publicSale;
    }

    /**
     * @dev Returns the amount contributed so far by a specific beneficiary.
     * @param beneficiary Address of contributor
     * @return Beneficiary contribution so far
     */
    function getContribution(
        address beneficiary
    ) public view returns (uint256) {
        return _contributions[beneficiary];
    }

    /**
     * @dev Returns the amount contributed so far by a specific beneficiary.
     * @param beneficiary Address of contributor
     * @return Beneficiary contribution so far
     */
    function getEligibleRemainingDepositAmount(
        address beneficiary
    ) public view returns (uint256) {
        if (_publicSale) {
            if (_perBeneficiaryCap > _contributions[beneficiary]) {
                return _perBeneficiaryCap - _contributions[beneficiary];
            } else {
                return 0;
            }
        } else {
            if (_caps[beneficiary] > _contributions[beneficiary]) {
                return _caps[beneficiary] - _contributions[beneficiary];
            } else {
                return 0;
            }
        }
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount
    ) internal view override {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(
            weiRaised() + weiAmount <= _totalCap,
            "GoochCrowdsale: cap exceeded"
        );
        // solhint-disable-next-line max-line-length
        if (_publicSale) {
            require(
                _contributions[beneficiary] + weiAmount <= _perBeneficiaryCap,
                "GoochCrowdsale: beneficiary cap exceeded"
            );
        } else {
            require(
                _contributions[beneficiary] + weiAmount <= _caps[beneficiary],
                "GoochCrowdsale: beneficiary's cap exceeded"
            );
        }
    }

    /**
     * @dev Extend parent behavior to update beneficiary contributions.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _updatePurchasingState(
        address beneficiary,
        uint256 weiAmount
    ) internal override {
        super._updatePurchasingState(beneficiary, weiAmount);
        _contributions[beneficiary] = _contributions[beneficiary] + weiAmount;
    }
}