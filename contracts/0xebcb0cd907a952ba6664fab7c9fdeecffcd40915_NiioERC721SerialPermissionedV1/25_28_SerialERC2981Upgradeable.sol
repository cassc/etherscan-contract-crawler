// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or for
 * specific series {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 */
abstract contract SerialERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {

    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    uint256 public constant SERIES_FACTOR = 1000000;
    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) internal _seriesRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165Upgradeable, ERC165Upgradeable)
    returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    virtual
    override
    returns (address, uint256)
    {
        uint256 seriesId = getTokenSeriesId(_tokenId);
        RoyaltyInfo memory royalty = _seriesRoyaltyInfo[seriesId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    function getSeriesRoyalty(uint256 seriesId)
    public
    view
    returns (RoyaltyInfo memory) {
        RoyaltyInfo memory royalty = _seriesRoyaltyInfo[seriesId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }
        return royalty;
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator()
    internal
    pure
    virtual
    returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator)
    internal
    virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `seriesId` must exist.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setSeriesRoyalty(
        uint256 seriesId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _seriesRoyaltyInfo[seriesId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetSeriesRoyalty(uint256 seriesId)
    internal
    virtual {
        delete _seriesRoyaltyInfo[seriesId];
    }

    function getTokenSeriesId(uint256 tokenId)
    public
    pure
    returns (uint256) {
        require(tokenId > SERIES_FACTOR, "tokenId must be greater than 1,000,000");
        return tokenId / SERIES_FACTOR;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}