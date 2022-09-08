// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/ITransferGatekeeper.sol";

/// @title TestTransferGatekeeper

contract TestTransferGatekeeper is ITransferGatekeeper {
    string public encodeType;
    bytes public data;
    uint256[2] public tokenIds;
    uint256[2] public amounts;

    function canTransfer(
        address,
        address,
        address,
        bytes memory encodedData
    ) external view override returns (bool) {
        if (bytes(encodeType).length != 0) {
            string memory _encodeType = abi.decode(encodedData, (string));
            if (keccak256(bytes(_encodeType)) == keccak256(bytes("721"))) {
                (, uint256 _tokenId) = abi.decode(encodedData, (string, uint256));
                return tokenIds[0] == _tokenId;
            }
            if (keccak256(bytes(_encodeType)) == keccak256(bytes("1155"))) {
                (, uint256 _tokenId, uint256 _amount, bytes memory _data) =
                    abi.decode(encodedData, (string, uint256, uint256, bytes));
                return (tokenIds[0] == _tokenId &&
                    amounts[0] == _amount &&
                    keccak256(bytes(data)) == keccak256(bytes(_data)));
            }
            if (keccak256(bytes(_encodeType)) == keccak256(bytes("1155_batch"))) {
                (, uint256[] memory _tokenIds, uint256[] memory _amounts, bytes memory _data) =
                    abi.decode(encodedData, (string, uint256[], uint256[], bytes));
                return (tokenIds[0] == _tokenIds[0] &&
                    tokenIds[1] == _tokenIds[1] &&
                    amounts[0] == _amounts[0] &&
                    amounts[1] == _amounts[1] &&
                    keccak256(bytes(data)) == keccak256(bytes(_data)));
            }
        }
        return false;
    }

    function set721Data(uint256 _tokenId) public {
        encodeType = "721";
        tokenIds[0] = _tokenId;
    }

    function set1155Data(
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public {
        encodeType = "1155";
        tokenIds[0] = _tokenId;
        amounts[0] = _amount;
        data = _data;
    }

    function set1155BatchData(
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public {
        encodeType = "1155_batch";
        tokenIds[1] = _tokenId;
        amounts[1] = _amount;
        data = _data;
    }
}