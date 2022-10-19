//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAttribute.sol";
import "../libraries/AttributeLib.sol";

import "../utilities/Modifiers.sol";

/// @title ERC721AAttributes
/// @notice the total balance of a token type
contract ERC721AAttributesFacet is Modifiers {
    using AttributeLib for AttributeContract;
    
    /// @notice set an attribute for a tokenid keyed by string
    function _getAttribute(
        uint256 id,
        string memory key
    ) internal view returns (Attribute memory) {
        AttributeContract storage ct = AttributeLib.attributeStorage().attributes;
        return ct._getAttribute(id, key);
    }
    
    /// @notice set an attribute to a tokenid keyed by string
    function _setAttribute(
        uint256 id,
        Attribute memory attribute
    ) internal virtual {
        AttributeContract storage ct = AttributeLib.attributeStorage().attributes;
        ct._setAttribute(id, attribute);
    }

    /// @notice get a list of keys of attributes assigned to this tokenid
    function _getAttributeKeys(
        uint256 id
    ) internal view returns (string[] memory) {
        AttributeContract storage ct = AttributeLib.attributeStorage().attributes;
        return ct.attributeKeys[id];
    }

    /// @notice remove the attribute for a tokenid keyed by string
    function _removeAttribute(
        uint256 id,
        string memory key
    ) internal virtual {
        AttributeContract storage ct = AttributeLib.attributeStorage().attributes;
        ct._removeAttribute(id, key);
    }

    function getAttributeKeys(
        uint256 id
    ) external view returns (string[] memory) {
        return _getAttributeKeys(id);
    }

    function getAttribute(
        uint256 id,
        string memory key
    ) external view returns (Attribute memory) {
        return _getAttribute(id, key);
    }

    /// @notice set an attribute value
    function setAttribute(uint256 id, Attribute memory attrib) external onlyOwner {
        _setAttribute(id, attrib);
    }
}