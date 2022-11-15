// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)
pragma solidity ^0.8.0;

import "../diamond/LibAppStorage.sol";

/**
 * @dev Implements attributes on a token. an attribute is a value that can be modified by permissioned contracts. The attribute is also displayed on the token.
 */
contract TokenAttributeFacet is Modifiers {

    event AttributeSet(uint256 indexed tokenId, string indexed key, uint256 value);

    /// @notice set an attribute to a tokenid keyed by string
    function setAttribute(
        uint256 _tokenId,
        string memory key,
        uint256 value
    ) public onlyOwner {
        s.tokenAttributeStorage.attributes[_tokenId][key] = value;
        emit AttributeSet(_tokenId, key, value);
    }

    /// @notice get an attribute for a tokenid keyed by string
    function getAttribute(
        uint256 _tokenId,
        string memory key
    ) public view returns (uint256) {
        return s.tokenAttributeStorage.attributes[_tokenId][key];
    }
}