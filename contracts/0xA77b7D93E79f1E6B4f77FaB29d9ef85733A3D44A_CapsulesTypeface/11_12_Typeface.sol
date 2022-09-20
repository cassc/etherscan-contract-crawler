// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/ITypeface.sol";

/**
  @title Typeface

  @author peri

  @notice The Typeface contract allows storing and retrieving a "source", such as a base64-encoded file, for all fonts in a typeface.

  Sources may be large and require a high gas fee to store. To reduce gas costs while deploying a contract containing source data, or to avoid surpassing gas limits of the deploy transaction block, only a hash of each source is stored when the contract is deployed. This allows sources to be stored in later transactions, ensuring the hash of the source matches the hash already stored for that font.

  Once the Typeface contract has been deployed, source hashes can't be added or modified.

  Fonts are identified by the Font struct, which includes "style" and "weight" properties.
 */

abstract contract Typeface is ITypeface, ERC165 {
    modifier onlyDonationAddress() {
        if (msg.sender != _donationAddress) {
            revert("Typeface: Not donation address");
        }
        _;
    }

    /// @notice Mapping of style => weight => font source data as bytes.
    mapping(string => mapping(uint256 => bytes)) private _source;

    /// @notice Mapping of style => weight => keccack256 hash of font source data as bytes.
    mapping(string => mapping(uint256 => bytes32)) private _sourceHash;

    /// @notice Mapping of style => weight => true if font source has been stored.
    /// @dev This serves as a gas-efficient way to check if a font source has been stored without getting the entire source data.
    mapping(string => mapping(uint256 => bool)) private _hasSource;

    /// @notice Address to receive donations.
    address _donationAddress;

    /// @notice Typeface name
    string private _name;

    /// @notice Return typeface name.
    /// @return name Name of typeface
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @notice Return source bytes for font.
    /// @param font Font to check source of.
    /// @return source Font source data as bytes.
    function sourceOf(Font memory font)
        public
        view
        virtual
        returns (bytes memory)
    {
        return _source[font.style][font.weight];
    }

    /// @notice Return true if font source exists.
    /// @param font Font to check if source exists for.
    /// @return true True if font source exists.
    function hasSource(Font memory font) public view virtual returns (bool) {
        return _hasSource[font.style][font.weight];
    }

    /// @notice Return hash of source bytes for font.
    /// @param font Font to return source hash of.
    /// @return sourceHash Hash of source for font.
    function sourceHash(Font memory font)
        public
        view
        virtual
        returns (bytes32)
    {
        return _sourceHash[font.style][font.weight];
    }

    /// @notice Returns the address to receive donations.
    /// @return donationAddress The address to receive donations.
    function donationAddress() external view returns (address) {
        return _donationAddress;
    }

    /// @notice Allows the donation address to set a new donation address.
    /// @param __donationAddress New donation address.
    function setDonationAddress(address __donationAddress) external {
        _setDonationAddress(__donationAddress);
    }

    function _setDonationAddress(address __donationAddress) internal {
        _donationAddress = payable(__donationAddress);

        emit SetDonationAddress(__donationAddress);
    }

    /// @notice Sets source for Font.
    /// @dev The keccack256 hash of the source must equal the sourceHash of the font.
    /// @param font Font to set source for.
    /// @param source Font source as bytes.
    function setSource(Font calldata font, bytes calldata source) public {
        require(!hasSource(font), "Typeface: Source already exists");

        require(
            keccak256(source) == sourceHash(font),
            "Typeface: Invalid font"
        );

        _beforeSetSource(font, source);

        _source[font.style][font.weight] = source;
        _hasSource[font.style][font.weight] = true;

        emit SetSource(font);

        _afterSetSource(font, source);
    }

    /// @notice Sets hash of source data for each font in a list.
    /// @dev Length of fonts and hashes arrays must be equal. Each hash from hashes array will be set for the font with matching index in the fonts array.
    /// @param fonts Array of fonts to set hashes for.
    /// @param hashes Array of hashes to set for fonts.
    function _setSourceHashes(Font[] memory fonts, bytes32[] memory hashes)
        internal
    {
        require(
            fonts.length == hashes.length,
            "Typeface: Unequal number of fonts and hashes"
        );

        for (uint256 i; i < fonts.length; i++) {
            _sourceHash[fonts[i].style][fonts[i].weight] = hashes[i];

            emit SetSourceHash(fonts[i], hashes[i]);
        }
    }

    constructor(string memory __name, address __donationAddress) {
        _name = __name;
        _setDonationAddress(__donationAddress);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(ITypeface).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Function called before setSource() is called.
    function _beforeSetSource(Font calldata font, bytes calldata src)
        internal
        virtual
    {}

    /// @notice Function called after setSource() is called.
    function _afterSetSource(Font calldata font, bytes calldata src)
        internal
        virtual
    {}
}