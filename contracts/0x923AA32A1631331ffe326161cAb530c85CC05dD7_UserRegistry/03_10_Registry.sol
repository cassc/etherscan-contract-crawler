// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Claimer.sol";

abstract contract Registry is Claimer {
    struct AttributeData {
        uint256 value;
        address updatedBy;
        uint256 timestamp;
    }

    mapping(address => mapping(bytes32 => AttributeData)) public attributes;

    event SetAttribute(
        address indexed who,
        bytes32 attribute,
        uint256 value,
        address indexed updatedBy
    );

    function setAttribute(
        address _who,
        bytes32 _attribute,
        uint256 _value
    ) public onlyOwner {
        attributes[_who][_attribute] = AttributeData(
            _value,
            msg.sender,
            block.timestamp
        );
        emit SetAttribute(_who, _attribute, _value, msg.sender);
    }

    function hasAttribute(address _who, bytes32 _attribute)
        public
        view
        returns (bool)
    {
        return attributes[_who][_attribute].value != 0;
    }

    function getAttribute(address _who, bytes32 _attribute)
        public
        view
        returns (AttributeData memory data)
    {
        data = attributes[_who][_attribute];
    }

    function getAttributeValue(address _who, bytes32 _attribute)
        public
        view
        returns (uint256)
    {
        return attributes[_who][_attribute].value;
    }
}