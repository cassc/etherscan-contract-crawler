//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

import "../interfaces/IAttribute.sol";

struct AttributeStorage {
    AttributeContract attributes;
}

library AttributeLib {
    event AttributeSet(address indexed tokenAddress, uint256 tokenId, Attribute attribute);
    event AttributeRemoved(address indexed tokenAddress, uint256 tokenId, string attributeKey);

    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.nextblock.bitgem.app.AttributeStorage.storage");

    function attributeStorage() internal pure returns (AttributeStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice set an attribute for a tokenid keyed by string
    function _getAttribute(
        AttributeContract storage self,
        uint256 tokenId,
        string memory key
    ) internal view returns (Attribute memory) {
        require(self.burnedIds[tokenId] == false, "Token has been burned");
        return self.attributes[tokenId][key];
    }

    /// @notice get a list of keys of attributes assigned to this tokenid
    function _getAttributeValues(
        uint256 id
    ) internal view returns (string[] memory) {
        AttributeContract storage ct = AttributeLib.attributeStorage().attributes;
        string[] memory keys = ct.attributeKeys[id];
        string[] memory values = new string[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = ct.attributes[id][keys[i]].value;
        }
        return values;
    }
    
    /// @notice set an attribute to a tokenid keyed by string
    function _setAttribute(
        AttributeContract storage self,
        uint256 tokenId,
        Attribute memory attribute
    ) internal {
        require(self.burnedIds[tokenId] == false, "Token has been burned");
        if (self.attributeKeysIndexes[tokenId][attribute.key] == 0 
            && bytes(self.attributes[tokenId][attribute.key].value).length == 0) {
            self.attributeKeys[tokenId].push(attribute.key);
            self.attributeKeysIndexes[tokenId][attribute.key] = self.attributeKeys[tokenId].length - 1;
        }
        self.attributes[tokenId][attribute.key] = attribute;
    }
    
    /// @notice set multiple  attributes for the token
    function _setAttributes(
        AttributeContract storage self,
        uint256 tokenId, 
        Attribute[] memory _attributes)
        internal
    {
        require(self.burnedIds[tokenId] == false, "Token has been burned");
        for (uint256 i = 0; i < _attributes.length; i++) {
            _setAttribute(self, tokenId, _attributes[i]);
        }
    }

    /// @notice get a list of keys of attributes assigned to this tokenid
    function _getAttributeKeys(
        AttributeContract storage self,
        uint256 tokenId
    ) internal view returns (string[] memory) {
        require(self.burnedIds[tokenId] == false, "Token has been burned");
        return self.attributeKeys[tokenId];
    }

    /// @notice remove the attribute for a tokenid keyed by string
    function _removeAttribute(
        AttributeContract storage self,
        uint256 tokenId,
        string memory key
    ) internal {
        require(self.burnedIds[tokenId] == false, "Token has been burned");
        delete self.attributes[tokenId][key];
        uint256 ndx = self.attributeKeysIndexes[tokenId][key];
        for (uint256 i = ndx; i < self.attributeKeys[tokenId].length - 1; i++) {
            self.attributeKeys[tokenId][i] = self.attributeKeys[tokenId][i + 1];
            self.attributeKeysIndexes[tokenId][self.attributeKeys[tokenId][i]] = i;
        }
        delete self.attributeKeys[tokenId][self.attributeKeys[tokenId].length - 1];
        emit AttributeRemoved(address(this), tokenId, key);
    }

    // @notice set multiple attributes for the token
    function _burn(
        AttributeContract storage self,
        uint256 tokenId)
        internal
    {
        self.burnedIds[tokenId] = true;
    }
}