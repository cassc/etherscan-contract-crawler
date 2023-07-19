// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { NFTState } from "../NFTState.sol";
import { ERC721A } from "ERC721A/ERC721A.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract NFTBase is NFTState, Ownable, ERC721A {
    constructor() ERC721A(NAME, SYMBOL) { }
    // solhint-disable-previous-line no-empty-blocks

    /**
     * @dev Set baseURI
     * @param _newBaseURI BaseURI as string, include trailing slash.
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        if (baseURIFrozen) revert URIFrozen();
        baseURI = _newBaseURI;
    }

    /**
     * @dev Make BaseURI immutable
     */
    function freezeBaseURI() external onlyOwner {
        baseURIFrozen = true;
    }

    /// @notice Overrides ERC721A start tokenId to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice Overrides ERC721A baseURI function to concat baseURI+tokenId
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}