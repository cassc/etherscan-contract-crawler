// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";

/// @title ERC721AMintable
/// @author dev by @dievardump
/// @notice adds minting logic, including minting extra data, max supply and bundle size for ERC721A
abstract contract ERC721AMintable is ERC721A {
    error TooManyRequested();

    /// @dev this variable is a flag that is used at minting time, if extra data needs to be added to the minted elements
    uint24 private _extraDataMint;

    /////////////////////////////////////////////////////////
    // Internal                                            //
    /////////////////////////////////////////////////////////

    /// @dev internal config to return the max supply and stop the mint function to work after it's met
    /// @return the max supply, 0 means no max
    function _maxSupply() internal view virtual returns (uint256) {
        return 0;
    }

    /// @dev internal config to bundle the mints into smaller groups of items and reduce lookup gas cost
    /// @return the bundle size
    function _mintBundleSize() internal view virtual returns (uint256) {
        return 5;
    }

    /// @notice Allows to mint `amount` tokens tokens to `to` with `extraData`
    /// @param to to whom we need to mint
    /// @param amount how many to mint
    /// @param extraData extraData for the token
    function _mintTo(
        address to,
        uint256 amount,
        uint24 extraData
    ) internal virtual {
        uint256 maxSupply = _maxSupply();
        uint256 mintBundleSize = _mintBundleSize();

        // check that there is enough supply
        if (maxSupply != 0 && _totalMinted() + amount > maxSupply) {
            revert TooManyRequested();
        }

        // this allows the minter to set some extraData when minting
        if (extraData != 0) {
            _extraDataMint = extraData;
        }

        uint256 times = amount / mintBundleSize;
        uint256 rest = amount % mintBundleSize;
        for (uint256 i; i < times; i++) {
            _mint(to, mintBundleSize);
        }

        if (rest != 0) {
            _mint(to, rest);
        }

        if (extraData != 0) {
            _extraDataMint = 0;
        }
    }

    /// @dev erc721A internal function used when minting or transfering an item
    /// @inheritdoc ERC721A
    function _extraData(
        address from,
        address, /*to*/
        uint24 previousExtraData
    ) internal view virtual override returns (uint24) {
        // if minting, return the _extraDataMint value
        if (from == address(0)) {
            return _extraDataMint;
        }
        // else return the current value
        return previousExtraData;
    }
}