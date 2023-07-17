// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/ILayerZeroUserApplicationConfig.sol";
import "./interfaces/IERC721OReceiver.sol";
import "./extensions/IERC721OMetadata.sol";
import "./IERC721O.sol";

/**
 * @dev Implementation of ERC721-O (Omnichain Non-Fungible Token standard)
 */
contract ERC721O is
    ERC721,
    Ownable,
    IERC721OMetadata,
    IERC721OReceiver,
    ILayerZeroUserApplicationConfig,
    IERC721O
{
    /**
     * @dev Emitted when trusted remote contract of `remoteAddress` set on `chainId` chain
     */
    event RemoteSet(uint16 chainId, bytes remoteAddress);

    /**
     * @dev Emitted when message execution failed
     */
    event MoveInFailed(
        uint16 srcChainId,
        bytes srcAddress,
        uint64 nonce,
        bytes payload
    );

    // LayerZero endpoint used to send message cross chian
    ILayerZeroEndpoint internal _endpoint;

    // Minimum gas limit for cross chain operation, exceeding fees will refund to users
    uint256 internal _minDestinationGasLimit;

    // Mapping from chainId to trusted remote contract address
    mapping(uint16 => bytes) internal _remotes;

    /**
     * @dev failed payload hash located by source chainId, source contract address, and nonce together
     */
    mapping(uint16 => mapping(bytes => mapping(uint256 => bytes32)))
        internal _failedPayloadHashs;

    /**
     * @dev Returns the address of cross chain endpoint
     */
    function endpoint() public view virtual override returns (address) {
        return address(_endpoint);
    }

    /**
     * @dev Returns the remote trusted contract address on chain `chainId`.
     */
    function remotes(uint16 chainId)
        public
        view
        virtual
        override
        returns (bytes memory)
    {
        return _remotes[chainId];
    }

    /**
     * @dev Returns the failed payload hash located by source chainId, source contract address, and nonce together
     */
    function failedPayloadHashs(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint256 nonce
    ) public view virtual returns (bytes32) {
        return _failedPayloadHashs[srcChainId][srcAddress][nonce];
    }

    /**
     * @dev Returns the minimum gas limit for cross chain operation
     */
    function minDestinationGasLimit() public view virtual returns (uint256) {
        return _minDestinationGasLimit;
    }

    /**
     * @dev Set the trusted remote contract of `remoteAddress` on `chainId` chain
     * @notice When remote contract has not invoked `setRemote()` for this contract,
     * invoke `pauseMove(chainId)` method before `setRemote()` to avoid avoid possible fund loss
     *
     * Requirements:
     *
     * - The remote contract must be ready to receive command
     *
     * Emits a {RemoteSet} event.
     */
    function setRemote(uint16 chainId, bytes calldata remoteAddress)
        external
        virtual
        onlyOwner
    {
        _remotes[chainId] = remoteAddress;
        emit RemoteSet(chainId, remoteAddress);
    }

    /**
     * @dev Set the minimum gas limit for cross chain operation
     */
    function setMinDestinationGasLimit(uint256 minDestinationGasLimit_)
        external
        virtual
        onlyOwner
    {
        _minDestinationGasLimit = minDestinationGasLimit_;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection,
     * and setting address of LayerZero endpoint on current chain
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address endpoint_
    ) ERC721(name_, symbol_) {
        _endpoint = ILayerZeroEndpoint(endpoint_);
    }

    /**
     * @dev Local action before move `tokenId` token to `dstChainId` chain
     */
    function _beforeMoveOut(
        address, // from
        uint16, // dstChainId
        bytes memory, // to
        uint256 tokenId
    ) internal virtual {
        // burn if move to other chain
        _burn(tokenId);
    }

    /**
     * @dev Local action after `tokenId` token from `srcChainId` chain send to `to`
     */
    function _afterMoveIn(
        uint16, // srcChainId
        address to,
        uint256 tokenId
    ) internal virtual {
        // erc721 cannot mint to zero address
        if (to == address(0x0)) {
            to = address(0xdEaD);
        }
        // mint when receive from other chain
        _safeMint(to, tokenId);
    }

    /**
     * @dev check whether the destination gas limit set by users is too low
     * if do not check the adapterParams, users can stuck the receiver by input low destination gas limit even with nonBlocking extension
     */
    function _gasGuard(bytes memory adapterParams) internal virtual {
        require(
            adapterParams.length == 34 || adapterParams.length > 66,
            "ERC721-O: wrong adapterParameters size"
        );
        uint16 txType;
        uint256 extraGas;
        assembly {
            txType := mload(add(adapterParams, 2))
            extraGas := mload(add(adapterParams, 34))
        }
        require(
            extraGas >= _minDestinationGasLimit,
            "ERC721-O: destination gas limit too low"
        );
    }

    /**
     * @dev See {IERC721_O-moveFrom}.
     */
    function moveFrom(
        address from,
        uint16 dstChainId,
        bytes calldata to,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable virtual override {
        _move(
            from,
            dstChainId,
            to,
            tokenId,
            refundAddress,
            zroPaymentAddress,
            adapterParams
        );
    }

    /**
     * @dev  Move `tokenId` token from `from` address on the current chain to `to` address on the `dstChainId` chain.
     * Internal function of {moveFrom}
     * See {IERC721_O-moveFrom}
     */
    function _move(
        address from,
        uint16 dstChainId,
        bytes calldata to,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) internal virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721-O: move caller is not owner or approved"
        );
        // only send message to exist remote contract`
        require(
            _remotes[dstChainId].length > 0,
            "ERC721-O: no remote contract on destination chain"
        );
        // revert if the destination gas limit is lower than `_minDestinationGasLimit`
        _gasGuard(adapterParams);

        _beforeMoveOut(from, dstChainId, to, tokenId);

        // abi.encode() the payload
        bytes memory payload = abi.encode(to, tokenId);

        // send message via LayerZero
        _endpoint.send{value: msg.value}(
            dstChainId,
            _remotes[dstChainId],
            payload,
            refundAddress,
            zroPaymentAddress,
            adapterParams
        );

        // track the LayerZero nonce
        uint64 nonce = _endpoint.getOutboundNonce(dstChainId, address(this));

        emit MoveOut(dstChainId, from, to, tokenId, nonce);
    }

    /**
     * @dev  See {IERC721OReceiver - lzReceive}
     */
    function lzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) external virtual override {
        // lzReceive must only be called by the endpoint
        require(msg.sender == address(_endpoint));
        // only receive message from `_remotes`
        require(
            srcAddress.length == _remotes[srcChainId].length &&
                keccak256(srcAddress) == keccak256(_remotes[srcChainId]),
            "ERC721-O: invalid source contract"
        );

        // catch all exceptions to avoid failed messages blocking message path
        try this.onLzReceive(srcChainId, nonce, payload) {
            // pass if succeed
        } catch {
            _failedPayloadHashs[srcChainId][srcAddress][nonce] = keccak256(
                payload
            );
            emit MoveInFailed(srcChainId, srcAddress, nonce, payload);
        }
    }

    /**
     * @dev Invoked by internal transcation to handle lzReceive logic
     */
    function onLzReceive(
        uint16 srcChainId,
        uint64 nonce,
        bytes memory payload
    ) public virtual {
        // only allow internal transaction
        require(
            msg.sender == address(this),
            "ERC721-O: only internal transcation allowed"
        );

        // decode the payload
        (bytes memory to, uint256 tokenId) = abi.decode(
            payload,
            (bytes, uint256)
        );

        address toAddress;
        // get toAddress from bytes
        assembly {
            toAddress := mload(add(to, 20))
        }

        _afterMoveIn(srcChainId, toAddress, tokenId);

        emit MoveIn(srcChainId, toAddress, tokenId, nonce);
    }

    /**
     * @dev Retry local stored failed messages
     */
    function retryMessage(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes calldata payload
    ) external payable {
        // assert there is message to retry
        bytes32 payloadHash = _failedPayloadHashs[srcChainId][srcAddress][
            nonce
        ];
        require(payloadHash != bytes32(0), "ERC721-O: no stored message");
        require(keccak256(payload) == payloadHash, "ERC721-O: invalid payload");
        // clear the stored message
        _failedPayloadHashs[srcChainId][srcAddress][nonce] = bytes32(0);
        // execute the message. revert if it fails again
        this.onLzReceive(srcChainId, nonce, payload);
    }

    /**
     * @dev See {ILayerZeroUserApplicationConfig-setConfig}.
     */
    function setConfig(
        uint16 version,
        uint16 chainId,
        uint256 configType,
        bytes calldata config
    ) external virtual override onlyOwner {
        _endpoint.setConfig(version, chainId, configType, config);
    }

    /**
     * @dev See {ILayerZeroUserApplicationConfig-setSendVersion}.
     */
    function setSendVersion(uint16 version)
        external
        virtual
        override
        onlyOwner
    {
        _endpoint.setSendVersion(version);
    }

    /**
     * @dev See {ILayerZeroUserApplicationConfig-setReceiveVersion}.
     */
    function setReceiveVersion(uint16 version)
        external
        virtual
        override
        onlyOwner
    {
        _endpoint.setReceiveVersion(version);
    }

    /**
     * @dev See {ILayerZeroUserApplicationConfig-forceResumeReceive}.
     * Warning: force resume will clear the failed payload and may cause fund loss
     */
    function forceResumeReceive(
        uint16 srcChainId,
        bytes calldata srcContractAddress
    ) external virtual override onlyOwner {
        _endpoint.forceResumeReceive(srcChainId, srcContractAddress);
    }
}