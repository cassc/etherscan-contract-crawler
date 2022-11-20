// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ProxyCheckerUpgradeable.sol";
import "./interfaces/IReferralUpgradeable.sol";

import "../libraries/FixedPointMathLib.sol";

abstract contract ReferralUpgradeable is
    ProxyCheckerUpgradeable,
    IReferralUpgradeable
{
    using FixedPointMathLib for uint256;

    uint256 private __maxDepth;
    uint16[] public levelBonusRates;

    mapping(address => uint256) public levels;
    mapping(address => uint256) public bonuses;
    mapping(address => address) public referrals;

    function __Referral_init(
        uint16[] calldata levelBonusRates_
    ) internal onlyInitializing {
        __Referral_init_unchained(levelBonusRates_);
    }

    function __Referral_init_unchained(
        uint16[] calldata levelBonusRates_
    ) internal onlyInitializing {
        _updateLevelBonusrates(levelBonusRates_);
    }

    function _updateLevelBonusrates(
        uint16[] calldata levelBonusRates_
    ) internal {
        uint256 length = levelBonusRates_.length;
        uint256 sum;
        for (uint256 i; i < length; ) {
            unchecked {
                sum += levelBonusRates_[i];
                ++i;
            }
        }

        require(sum == _denominator(), "REFERALL: INVALID_ARGUMENTS");

        levelBonusRates = levelBonusRates_;
    }

    function updateLevelBonusRates(
        uint16[] calldata levelBonusRates_
    ) external virtual;

    function addReferrer(address referrer_, address referree_) external virtual;

    function referralTree(
        address referee_
    ) external view returns (address[] memory referrers) {
        uint256 maxDepth = levelBonusRates.length;
        referrers = new address[](maxDepth);
        address referrer = referee_;
        for (uint256 i; i < maxDepth; ) {
            if ((referrer = referrals[referrer]) == address(0)) break;
            referrers[i] = referrer;
            unchecked {
                ++i;
            }
        }
    }

    function _addReferrer(address referrer_, address referree_) internal {
        require(!_isProxy(referrer_), "REFERRAL: PROXY_NOT_ALLOWED");
        require(
            referrals[referree_] == address(0),
            "REFERRAL: REFERRER_EXISTED"
        );
        referrals[referree_] = referrer_;

        uint256 level;
        uint256 maxDepth = levelBonusRates.length;
        for (uint256 i; i < maxDepth; ) {
            require(referrer_ != referree_, "REFERRAL: CIRCULAR_REF_UNALLOWED");

            unchecked {
                level = ++levels[referrer_];
                ++i;
            }

            emit LevelUpdated(referrer_, level);
            if ((referrer_ = referrals[referrer_]) == address(0)) break;
        }

        emit ReferrerAdded(referree_, referrer_);
    }

    function _updateReferrerBonus(address referree_, uint256 amount_) internal {
        uint16[] memory _levelBonusRates = levelBonusRates;
        uint256 maxDepth = _levelBonusRates.length;
        address referrer = referree_;
        uint256 denominator = _denominator();
        for (uint256 i; i < maxDepth; ) {
            if ((referrer = referrals[referrer]) == address(0)) break;
            unchecked {
                bonuses[referrer] += amount_.mulDivDown(
                    _levelBonusRates[i],
                    denominator
                );
                ++i;
            }
        }
    }

    function _denominator() internal pure virtual returns (uint256) {
        return 10_000;
    }

    uint256[45] private __gap;
}