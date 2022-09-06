// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Custom.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NonblockingReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";

contract CrossChainERC721 is NonblockingReceiver, ERC721Custom {
    uint256 public lzGas;

    error InsufficientChainTransferFee();
    error IncorrectTransferChainId();
    error ChainTransferCallerNotOwner();

    event ChainTransferStarted(
        uint256 tokenId,
        address owner,
        uint16 srcChainId
    );
    event ChainTransferCompleted(
        uint256 tokenId,
        address owner,
        uint16 dstChainId
    );

    constructor(
        string memory name_,
        string memory symbol_,
        address lzEndpoint_,
        uint256 lzGas_
    ) ERC721Custom(name_, symbol_) {
        _lzEndpoint = ILayerZeroEndpoint(lzEndpoint_);
        lzGas = lzGas_;
    }

    function setLzEndpoint(ILayerZeroEndpoint lzEndpoint_) public onlyOwner {
        _lzEndpoint = lzEndpoint_;
    }

    function transferChain(uint16 _dstChainId, uint256 _tokenId)
        public
        payable
    {
        if (trustedRemoteLookup[_dstChainId].length == 0)
            revert IncorrectTransferChainId();
        if (msg.sender != ownerOf(_tokenId))
            revert ChainTransferCallerNotOwner();
        bytes memory payload = _getPayload(_tokenId);
        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, lzGas);
        (uint256 messageFee, ) = _lzEndpoint.estimateFees(
            _dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );

        if (msg.value < messageFee) revert InsufficientChainTransferFee();
        // burn NFT
        _burn(_tokenId);

        _lzSend(
            _dstChainId,
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );

        _afterChainTransferStart(_tokenId);

        emit ChainTransferStarted(_tokenId, msg.sender, _dstChainId);
    }

    function _lzReceive(
        uint16 _srcChainId,
        bytes memory, /* _srcAddress */
        uint64, /* _nonce */
        bytes memory _payload
    ) internal override {
        (uint256 tokenId, address toAddr) = _completeChainTransfer(_payload);
        _afterChainTransferComplete(tokenId);
        emit ChainTransferCompleted(tokenId, toAddr, _srcChainId);
        // emit ReceiveNFT(_srcChainId, toAddr, tokenId, counter);
    }

    // Endpoint.sol estimateFees() returns the fees for the message
    function estimateFees(uint16 _dstChainId, uint256 _tokenId)
        public
        view
        returns (uint256 messageFee)
    {
        if (trustedRemoteLookup[_dstChainId].length == 0)
            revert IncorrectTransferChainId();
        bytes memory payload = _getPayload(_tokenId);
        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, lzGas);
        (messageFee, ) = _lzEndpoint.estimateFees(
            _dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );
    }

    function setLzGas(uint256 _lzGas) external onlyOwner {
        lzGas = _lzGas;
    }

    function _getPayload(uint256 _tokenId)
        internal
        view
        virtual
        returns (bytes memory payload)
    {
        payload = abi.encode(ownerOf(_tokenId), _tokenId);
    }

    function _completeChainTransfer(bytes memory _payload)
        internal
        virtual
        returns (uint256, address)
    {
        // decode
        (address toAddr, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );

        // mint the tokens back into existence on destination chain
        _safeMint(toAddr, tokenId);
        return (tokenId, toAddr);
    }

    // solhint-disable-next-line no-empty-blocks
    function _afterChainTransferStart(uint256 tokenId) internal virtual {}

    // solhint-disable-next-line no-empty-blocks
    function _afterChainTransferComplete(uint256 tokenId) internal virtual {}
}