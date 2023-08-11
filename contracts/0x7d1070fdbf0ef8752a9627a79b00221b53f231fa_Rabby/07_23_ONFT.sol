// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IONFT.sol";
import "../../lzApp/NonblockingLzApp.sol";
import "../ERC721A.sol";

// NOTE: this ONFT contract has no minting logic.
// must implement your own minting logic in child classes
contract ONFT is IONFT, NonblockingLzApp, ERC721A {
    string public baseTokenURI;

    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint
    ) ERC721A(_name, _symbol) NonblockingLzApp(_lzEndpoint) {}

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParam
    ) external payable virtual override {
        _send(
            _from,
            _dstChainId,
            _toAddress,
            _tokenId,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParam
        );
    }

    function send(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParam
    ) external payable virtual override {
        _send(
            _msgSender(),
            _dstChainId,
            _toAddress,
            _tokenId,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParam
        );
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParam
    ) internal virtual {
        bool isApprovedOrOwner = (_msgSender() == _from ||
            isApprovedForAll(_from, _msgSender()) ||
            getApproved(_tokenId) == _msgSender());
        require(isApprovedOrOwner);

        _beforeSend(_from, _dstChainId, _toAddress, _tokenId);
        bytes memory payload = abi.encode(_toAddress, _tokenId);
        _lzSend(
            _dstChainId,
            payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParam
        );

        uint64 nonce = lzEndpoint.getOutboundNonce(_dstChainId, address(this));
        emit SendToChain(_from, _dstChainId, _toAddress, _tokenId, nonce);
        _afterSend(_from, _dstChainId, _toAddress, _tokenId);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {
        _beforeReceive(_srcChainId, _srcAddress, _payload);

        // decode and load the toAddress
        (bytes memory toAddress, uint256 tokenId) = abi.decode(
            _payload,
            (bytes, uint256)
        );
        address localToAddress;
        assembly {
            localToAddress := mload(add(toAddress, 20))
        }

        // if the toAddress is 0x0, burn it or it will get cached
        if (localToAddress == address(0x0)) localToAddress == address(0xdEaD);

        _afterReceive(_srcChainId, localToAddress, tokenId);

        emit ReceiveFromChain(_srcChainId, localToAddress, tokenId, _nonce);
    }

    function _beforeSend(
        address, /* _from */
        uint16, /* _dstChainId */
        bytes memory, /* _toAddress */
        uint256 _tokenId
    ) internal virtual {
        _burn(_tokenId);
    }

    function _afterSend(
        address, /* _from */
        uint16, /* _dstChainId */
        bytes memory, /* _toAddress */
        uint256 /* _tokenId */
    ) internal virtual {}

    function _beforeReceive(
        uint16, /* _srcChainId */
        bytes memory, /* _srcAddress */
        bytes memory /* _payload */
    ) internal virtual {}

    function _afterReceive(
        uint16, /* _srcChainId */
        address _toAddress,
        uint256 _tokenId
    ) internal virtual {
        _mintWithTokenId(_toAddress, _tokenId);
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}