// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IDataURI.sol";
import "./ERC721WithOperatorFilter.sol";

/**
 * @dev Rebased ERC721 Contract
 *
 *      ERC721Rebased
 *          <= ERC721WithOperatorFilter
 *          <= ERC721RoyaltyOwnable
 *          <= ERC721Royalty
 *          <= ERC721Enumerable
 *          <= ERC721
 */
abstract contract ERC721Rebased is ERC721WithOperatorFilter {
    IDataURI private _dataURIContract;

    mapping(uint256 => bytes32) internal _dna;

    constructor(address dataURIContract_) {
        _setDataURIContract(dataURIContract_);
    }

    function dataURIContract() public view returns (address) {
        return address(_dataURIContract);
    }

    function tokenURI(
        uint256 tokenId_
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId_);

        return _dataURIContract.tokenURI(tokenId_, _dna[tokenId_]);
    }

    function setDataURIContract(address dataURIContract_) public onlyOwner {
        _dataURIContract = IDataURI(dataURIContract_);
    }

    function _setDataURIContract(address dataURIContract_) internal {
        _dataURIContract = IDataURI(dataURIContract_);
    }
}
