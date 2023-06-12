// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Lendable.sol";
import "../interfaces/ITokenReceiver.sol";
import "../libraries/Constants.sol";

contract TokenReceiver is
    ITokenReceiver,
    Lendable
{

    modifier isSingleNFT(uint256 amount) {
        require(amount == 1, errors.NOT_SINGLE_NFT);
        _;
    }

    modifier canReceiveNFT(address _operator, uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            (uint256(idToAccountInfo[_tokenId].expires) < block.timestamp &&
                (
                    tokenOwner == _operator ||
                    ownerToOperators[tokenOwner][_operator]
                )
            )
            ||
            (
                uint256(idToAccountInfo[_tokenId].expires) >=  block.timestamp && idToAccountInfo[_tokenId].account == _operator
            ),
            errors.NOT_OWNER_OR_OPERATOR
        );
        _;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        override
        validNFToken(_bytesToInteger(_data))
        userCanUpdateFrame(_bytesToInteger(_data), _from)
        canReceiveNFT(_operator, _bytesToInteger(_data))
        returns(bytes4)
    {
        _onNFTReceived(_tokenId, _data, _from);
        return constants.MAGIC_ON_ERC721_RECEIVED;
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    )
        external
        override
        validNFToken(_bytesToInteger(_data))
        canReceiveNFT(_operator, _bytesToInteger(_data))
        userCanUpdateFrame(_bytesToInteger(_data), _from)
        isSingleNFT(_value)
        returns (bytes4)
    {
        _onNFTReceived(_id, _data, _from);
        return constants.MAGIC_ON_ERC1155_RECEIVED;
    }

    function _onNFTReceived(
        uint256 _tokenId,
        bytes memory _data,
        address from
    )
        private
    {
        uint256 frameId = _bytesToInteger(_data);

        if (idToExternalNFT[frameId].contractAddress != address(0)) {
            _emptyFrame(frameId, from);
        }

        if (idToAccountInfo[frameId].expires >= block.timestamp) {
            idToArtworkOwner[frameId] = idToAccountInfo[frameId].account;
        }

        idToExternalNFT[frameId] = ExternalNFT(msg.sender, _tokenId);
        emit NFTReceived(frameId, idToOwner[frameId], msg.sender, _tokenId);
    }

    function _bytesToInteger(
        bytes memory message
    )
        public
        pure
        returns(uint256)
    {
        require(message.length > 0, errors.FRAME_ID_MISSING);
        uint256 converted;
        for (uint i = 0; i < message.length; i++){
            converted = converted + uint8(message[i])*(2**(8*(message.length-(i+1))));
        }
        return converted;
    }
}