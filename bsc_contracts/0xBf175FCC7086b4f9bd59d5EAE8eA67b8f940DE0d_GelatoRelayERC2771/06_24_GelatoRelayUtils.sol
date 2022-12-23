// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// Four different types of calldata packing
// 1. encodeFeeCollector: append 20 byte feeCollector address
// 2. encodeRelayContext: append 20 byte feeCollector address, 20 byte feeToken address, 32 byte uint256 fee
// 3. encodeFeeCollectorERC2771: append 20 byte feeCollector address, 20 byte _msgSender address
// 4. encodeRelayContextERC2771: append 20 byte feeCollector address, 20 byte feeToken address, 32 byte uint256 fee, 20 byte _msgSender address

function _encodeFeeCollector(bytes calldata _data, address _feeCollector)
    pure
    returns (bytes memory)
{
    return abi.encodePacked(_data, _feeCollector);
}

function _encodeRelayContext(
    bytes calldata _data,
    address _feeCollector,
    address _feeToken,
    uint256 _fee
) pure returns (bytes memory) {
    return abi.encodePacked(_data, _feeCollector, _feeToken, _fee);
}

// ERC2771 Encodings

// vanilla ERC2771 context encoding
// solhint-disable-next-line private-vars-leading-underscore, func-visibility
function _encodeERC2771Context(bytes calldata _data, address _msgSender)
    pure
    returns (bytes memory)
{
    return abi.encodePacked(_data, _msgSender);
}

function _encodeFeeCollectorERC2771(
    bytes calldata _data,
    address _feeCollector,
    address _msgSender
) pure returns (bytes memory) {
    return abi.encodePacked(_data, _feeCollector, _msgSender);
}

function _encodeRelayContextERC2771(
    bytes calldata _data,
    address _feeCollector,
    address _feeToken,
    uint256 _fee,
    address _msgSender
) pure returns (bytes memory) {
    return abi.encodePacked(_data, _feeCollector, _feeToken, _fee, _msgSender);
}