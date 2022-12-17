// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../utils/rollup/Settleable.sol";

abstract contract ERC721Settleable is ERC721, Settleable, AccessControl {
    uint256 private _totalMintCount;
    uint256 private _totalBurnCount;

    constructor(address bridgeAddress) Settleable(bridgeAddress) {}

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev It's called by {settle} in Settleable.sol.
    function _settle(KeyValuePair[] memory pairs, bytes32)
        internal
        virtual
        override
    {
        // Use a local variable to hold the loop computation result.
        uint256 curBurnCount = 0;
        for (uint256 i = 0; i < pairs.length; i++) {
            uint256 tokenId = abi.decode(pairs[i].key, (uint256));
            address account = abi.decode(pairs[i].value, (address));

            if (account == address(0)) {
                curBurnCount += 1;
            } else {
                _mint(account, tokenId);
            }
        }
        _incrementTotalMinted(pairs.length);
        _incrementTotalBurned(curBurnCount);
    }

    function _incrementTotalMinted(uint256 n) internal virtual {
        _totalMintCount += n;
    }

    function _incrementTotalBurned(uint256 n) internal virtual {
        _totalBurnCount += n;
    }

    function _totalMinted() internal view virtual returns (uint256) {
        return _totalMintCount;
    }

    function _totalBurned() internal view virtual returns (uint256) {
        return _totalBurnCount;
    }
}