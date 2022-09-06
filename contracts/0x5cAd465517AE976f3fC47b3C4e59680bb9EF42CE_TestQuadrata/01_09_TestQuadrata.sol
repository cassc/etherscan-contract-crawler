//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/IQuadReader.sol";
import "../interfaces/IQuadPassportStore.sol";

contract TestQuadrata {
   address public admin;
    IQuadReader public reader;

    constructor() {
        admin = msg.sender;
    }
    function setReader(address _reader) public {
        reader = IQuadReader(_reader);
    }

    function checkValues(address _account, bytes32 _attribute, bytes32 _value, uint256 i) public payable {
        uint256 queryFee = reader.queryFee(_account, _attribute);

        require(msg.value >= queryFee, "NOT_ENOUGH_FEE");
        IQuadPassportStore.Attribute[] memory attributes = reader.getAttributes{value: queryFee}(_account, _attribute);
        require(attributes.length > i, "NO_ATTRIBUTE_FOUND");
        require(attributes[i].value == _value, "MISMATCH_VALUE");
    }

    function checkValuesInt(address _account, bytes32 _attribute, uint256 _value, uint256 i) public payable {
        uint256 queryFee = reader.queryFee(_account, _attribute);

        require(msg.value >= queryFee, "NOT_ENOUGH_FEE");
        IQuadPassportStore.Attribute[] memory attributes = reader.getAttributes{value: queryFee}(_account, _attribute);
        require(attributes.length > i, "NO_ATTRIBUTE_FOUND");
        require(uint256(attributes[i].value) == _value, "MISMATCH_VALUE");
    }

    function checkIssuer(address _account, bytes32 _attribute, address _issuer, uint256 i) public payable {
        uint256 queryFee = reader.queryFee(_account, _attribute);

        require(msg.value >= queryFee, "NOT_ENOUGH_FEE");
        IQuadPassportStore.Attribute[] memory attributes = reader.getAttributes{value: queryFee}(_account, _attribute);
        require(attributes.length > i, "NO_ATTRIBUTE_FOUND");
        require(attributes[i].issuer == _issuer, "MISMATCH_ISSUER");
    }

    function checkBeforeEpoch(address _account, bytes32 _attribute, uint256 _epoch, uint256 i) public payable {

        uint256 queryFee = reader.queryFee(_account, _attribute);

        require(msg.value >= queryFee, "NOT_ENOUGH_FEE");
        IQuadPassportStore.Attribute[] memory attributes = reader.getAttributes{value: queryFee}(_account, _attribute);
        require(attributes.length > i, "NO_ATTRIBUTE_FOUND");
        require(attributes[i].epoch <= _epoch, "MISMATCH_EPOCH");
    }

    function checkNumberAttributes(address _account, bytes32 _attribute, uint256 _number) public payable {
        uint256 queryFee = reader.queryFee(_account, _attribute);

        require(msg.value >= queryFee, "NOT_ENOUGH_FEE");
        IQuadPassportStore.Attribute[] memory attributes = reader.getAttributes{value: queryFee}(_account, _attribute);
        require(attributes.length == _number, "INVALID_NUMBER_ATTRIBUTES");
    }
}