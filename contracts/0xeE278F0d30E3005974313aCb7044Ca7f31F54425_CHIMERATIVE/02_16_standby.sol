//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./token.sol";

contract STANDBY is TOKEN {
    bool public standbyStart;
    mapping(uint256 => bool) private _standbyStatus;
    mapping(uint256 => uint256) private _transactionCount;

    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 _startTokenId,
        uint256 _quantity
    ) internal override(ERC721A) {
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = _startTokenId + i;
            if (_standbyStatus[tokenId]) {
                _standbyStatus[tokenId] = false;
            }

            if (msg.sender != _to) {
                _transactionCount[tokenId]++;
            }
        }

        super._beforeTokenTransfers(_from, _to, _startTokenId, _quantity);
    }

    function _toggleStandby(uint256 _tokenId) private {
        address owner = ownerOf(_tokenId);
        require(
            owner == msg.sender,
            "You can change the Chimera status only owners"
        );

        if (_standbyStatus[_tokenId]) {
            _standbyStatus[_tokenId] = false;
        } else {
            _standbyStatus[_tokenId] = true;
        }
    }

    function toggleStandby(uint256[] calldata _tokenIds) external {
        require(standbyStart, "This feature is not yet available.");

        uint256 n = _tokenIds.length;
        for (uint256 i = 0; i < n; ) {
            _toggleStandby(_tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    function setStandbyStart(bool _state) public onlyOwner {
        standbyStart = _state;
    }

    function getStandbyStatus(uint256 _tokenId) external view returns (bool) {
        return _standbyStatus[_tokenId];
    }

    function getTransactionCount(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        return _transactionCount[_tokenId];
    }
}