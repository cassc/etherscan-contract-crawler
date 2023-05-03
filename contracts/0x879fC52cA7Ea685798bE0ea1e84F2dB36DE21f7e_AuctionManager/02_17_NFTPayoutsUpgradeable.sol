// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// Interfaces
import "../interfaces/INFTPayoutsUpgradeable.sol";

/**
 * @dev Implementation of the NFT Royalty Standard plus Payout Info added, a standardized way to retrieve royalty payment and payout information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 */
abstract contract NFTPayoutsUpgradeable is
    Initializable,
    ERC165Upgradeable,
    INFTPayoutsUpgradeable
{
    struct PayoutInfo {
        address receiver;
        uint96 payoutFraction;
    }

    struct PayoutTier {
        address creator;
        PayoutInfo[] primaryPayoutInfo;
        PayoutInfo[] secondaryPayoutInfo;
    }

    mapping(uint256 => address) private _tokenCreatorInfo;
    mapping(bool => mapping(uint256 => PayoutInfo[])) private _tokenPayoutInfo;
    mapping(bool => mapping(uint256 => uint256)) private _tokenPayoutCount;

    function __ERC2981Payout_init() internal onlyInitializing {}

    function __ERC2981Payout_init_unchained() internal onlyInitializing {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC165Upgradeable, ERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(INFTPayoutsUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function creator(
        uint256 tokenId_
    ) public view virtual override returns (address) {
        return _tokenCreatorInfo[tokenId_];
    }

    /**
     * @inheritdoc INFTPayoutsUpgradeable
     */
    function payoutCount(
        uint256 tokenId_,
        bool isPayout_
    ) public view virtual override returns (uint256) {
        return _tokenPayoutCount[isPayout_][tokenId_];
    }

    /**
     * @inheritdoc INFTPayoutsUpgradeable
     */
    function payoutInfo(
        uint256 tokenId_,
        uint256 salePrice_,
        bool isPayout_
    )
        public
        view
        virtual
        override
        returns (address[] memory receivers, uint256[] memory payoutAmounts)
    {
        uint256 count = payoutCount(tokenId_, isPayout_);
        require(count != 0, "NFTPayouts: no payout");

        receivers = new address[](count);
        payoutAmounts = new uint256[](count);

        for (uint256 i; i < count; ) {
            receivers[i] = _tokenPayoutInfo[isPayout_][tokenId_][i].receiver;
            payoutAmounts[i] =
                (salePrice_ *
                    _tokenPayoutInfo[isPayout_][tokenId_][i].payoutFraction) /
                _feeDenominator();

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the payout information for a specific token id, overriding the global default.
     */
    function _setCreator(uint256 tokenId_, address creator_) internal virtual {
        require(creator_ != address(0), "NFTPayouts: zero creator address");

        _tokenCreatorInfo[tokenId_] = creator_;
    }

    /**
     * @dev Sets the payout information for a specific token id, overriding the global default.
     */
    function _setTokenPayout(
        uint256 tokenId_,
        bool isPayout_,
        uint256 payoutCount_,
        PayoutInfo[] calldata payoutInfo_
    ) internal virtual {
        _resetTokenPayout(tokenId_, isPayout_);

        uint256 payoutTotal;

        _tokenPayoutCount[isPayout_][tokenId_] = payoutCount_;

        for (uint256 i; i < payoutCount_; ) {
            require(
                payoutInfo_[i].receiver != address(0),
                "NFTPayouts: invalid receiver"
            );

            payoutTotal = payoutTotal + payoutInfo_[i].payoutFraction;

            unchecked {
                ++i;
            }
        }

        if (isPayout_) {
            require(
                payoutTotal == _feeDenominator(),
                "ERC2981Payout: invalid payouts"
            );
        } else {
            require(
                payoutTotal <= _feeDenominator(),
                "ERC2981Payout: invalid royalties"
            );
        }

        for (uint256 i; i < payoutCount_; ) {
            _tokenPayoutInfo[isPayout_][tokenId_].push(payoutInfo_[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Resets payout information for the token id back to the global default.
     */
    function _resetTokenPayout(
        uint256 tokenId_,
        bool isPayout_
    ) internal virtual {
        delete _tokenPayoutCount[isPayout_][tokenId_];
        delete _tokenPayoutInfo[isPayout_][tokenId_];
        delete _tokenCreatorInfo[tokenId_];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}