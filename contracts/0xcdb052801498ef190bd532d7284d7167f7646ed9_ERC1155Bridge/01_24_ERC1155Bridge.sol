// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IZKBridge.sol";
import "./interfaces/IZKBridgeReceiver.sol";
import "./libraries/external/BytesLib.sol";
import "./token/ZKBridgeErc1155.sol";

contract ERC1155Bridge is
    Initializable,
    OwnableUpgradeable,
    IZKBridgeReceiver,
    ReentrancyGuard
{
    using BytesLib for bytes;

    event TransferNFT(
        uint64 indexed sequence,
        address token,
        uint256 tokenID,
        uint256 amount,
        uint16 recipientChain,
        address sender,
        address recipient
    );

    event ReceiveNFT(
        uint64 indexed sequence,
        address sourceToken,
        address token,
        uint256 tokenID,
        uint256 amount,
        uint16 sourceChain,
        uint16 sendChain,
        address recipient
    );

    struct WrappedAsset {
        uint16 nativeChainId;
        address nativeContract;
    }

    struct Transfer {
        // Address of the token
        address tokenAddress;
        // Chain ID of the token
        uint16 tokenChain;
        // TokenID of the token
        uint256 tokenID;
        // Amount of the transfer
        uint256 amount;
        // URI of the token metadata (UTF-8)
        string uri;
        // Address of the recipient
        address to;
        // Chain ID of the recipient
        uint16 toChain;
    }

    IZKBridge public zkBridge;

    uint16 public chainId;

    // Mapping of wrapped assets (chainID => nativeAddress => wrappedAddress)
    mapping(uint16 => mapping(address => address)) wrappedAssets;

    // Mapping of wrapped assets data(wrappedAddress => WrappedAsset)
    mapping(address => WrappedAsset) public wrappedAssetData;

    // chainID => bridgeAddress
    mapping(uint16 => address) public trustedRemoteLookup;

    // Mapping of receive chain fee
    mapping(uint16 => uint256) public chainFee;

    function initialize(uint16 _chainId, address _zkBridge) public initializer {
        __Ownable_init();
        chainId = _chainId;
        zkBridge = IZKBridge(_zkBridge);
    }

    function transferNFT(
        address _token,
        uint256 _tokenId,
        uint256 _amount,
        uint16 _recipientChain,
        address _recipient
    ) external payable nonReentrant returns (uint64 sequence) {
        require(msg.value >= chainFee[_recipientChain], "Insufficient Fee");
        // determine token parameters
        uint16 tokenChain = chainId;
        address tokenAddress = _token;
        WrappedAsset memory wrappedAsset = wrappedAssetData[_token];
        if (wrappedAsset.nativeChainId != 0) {
            tokenChain = wrappedAsset.nativeChainId;
            tokenAddress = wrappedAsset.nativeContract;
        } else {
            // Verify that the correct interfaces are implemented
            require(
                ERC165(_token).supportsInterface(type(IERC1155).interfaceId),
                "must support the ERC1155 interface"
            );
            require(
                ERC165(_token).supportsInterface(
                    type(IERC1155MetadataURI).interfaceId
                ),
                "must support the ERC1155-Metadata extension"
            );
        }

        string memory uriString = ERC1155(_token).uri(_tokenId);

        ERC1155(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            ""
        );
        if (wrappedAsset.nativeChainId != 0) {
            IZKBridgeErc1155(_token).zkBridgeBurn(
                address(this),
                _tokenId,
                _amount
            );
        }

        sequence = _logTransfer(
            Transfer(
                tokenAddress,
                tokenChain,
                _tokenId,
                _amount,
                uriString,
                _recipient,
                _recipientChain
            ),
            msg.value
        );

        emit TransferNFT(
            sequence,
            _token,
            _tokenId,
            _amount,
            _recipientChain,
            msg.sender,
            _recipient
        );
    }

    function _logTransfer(
        Transfer memory _transfer,
        uint256 _callValue
    ) internal returns (uint64 sequence) {
        bytes memory payload = _encodeTransfer(_transfer);
        address dstAddress = trustedRemoteLookup[_transfer.toChain];
        require(dstAddress != address(0), "invalid recipientChain");
        sequence = zkBridge.send{value: _callValue}(
            _transfer.toChain,
            dstAddress,
            payload
        );
    }

    function zkReceive(
        uint16 _srcChainId,
        address _srcAddress,
        uint64 _sequence,
        bytes calldata _payload
    ) external override nonReentrant {
        require(msg.sender == address(zkBridge), "Not From ZKBridgeEntrypoint");
        require(
            trustedRemoteLookup[_srcChainId] == _srcAddress,
            "invalid emitter"
        );
        _completeTransfer(_srcChainId, _sequence, _payload);
    }

    function _completeTransfer(
        uint16 _srcChainId,
        uint64 _sequence,
        bytes calldata _payload
    ) internal {
        Transfer memory transfer = _parseTransfer(_payload);
        require(transfer.toChain == chainId, "invalid target chain");

        address transferToken;
        if (transfer.tokenChain == chainId) {
            transferToken = transfer.tokenAddress;
            IERC1155(transfer.tokenAddress).safeTransferFrom(
                address(this),
                transfer.to,
                transfer.tokenID,
                transfer.amount,
                ""
            );
        } else {
            address wrapped = wrappedAssets[transfer.tokenChain][
                transfer.tokenAddress
            ];
            // If the wrapped asset does not exist yet, create it
            if (wrapped == address(0)) {
                wrapped = _createWrapped(
                    transfer.tokenChain,
                    transfer.tokenAddress
                );
            }
            transferToken = wrapped;
            // mint wrapped asset
            IZKBridgeErc1155(wrapped).zkBridgeMint(
                transfer.to,
                transfer.tokenID,
                transfer.amount,
                transfer.uri
            );
        }
        emit ReceiveNFT(
            _sequence,
            transfer.tokenAddress,
            transferToken,
            transfer.tokenID,
            transfer.amount,
            transfer.tokenChain,
            _srcChainId,
            transfer.to
        );
    }

    // Creates a wrapped asset using AssetMeta
    function _createWrapped(
        uint16 _tokenChain,
        address _tokenAddress
    ) internal returns (address token) {
        require(
            _tokenChain != chainId,
            "can only wrap tokens from foreign chains"
        );
        require(
            wrappedAssets[_tokenChain][_tokenAddress] == address(0),
            "wrapped asset already exists"
        );

        token = address(new ZKBridgeErc1155());
        wrappedAssetData[token] = WrappedAsset(_tokenChain, _tokenAddress);
        wrappedAssets[_tokenChain][_tokenAddress] = token;
    }

    function _encodeTransfer(
        Transfer memory _transfer
    ) internal pure returns (bytes memory encoded) {
        require(
            bytes(_transfer.uri).length <= 200,
            "tokenURI must not exceed 200 bytes"
        );

        encoded = abi.encodePacked(
            _transfer.tokenAddress,
            _transfer.tokenChain,
            _transfer.tokenID,
            _transfer.amount,
            _transfer.to,
            _transfer.toChain,
            _transfer.uri
        );
    }

    function _parseTransfer(
        bytes memory _encoded
    ) internal pure returns (Transfer memory transfer) {
        uint index = 0;

        transfer.tokenAddress = _encoded.toAddress(index);
        index += 20;

        transfer.tokenChain = _encoded.toUint16(index);
        index += 2;

        transfer.tokenID = _encoded.toUint256(index);
        index += 32;

        transfer.amount = _encoded.toUint256(index);
        index += 32;

        transfer.to = _encoded.toAddress(index);
        index += 20;

        transfer.toChain = _encoded.toUint16(index);
        index += 2;

        transfer.uri = string(_encoded.slice(index, _encoded.length - index));
    }

    function fee(uint16 _chainId) public view returns (uint256) {
        return chainFee[_chainId];
    }

    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        require(
            operator == address(this),
            "can only bridge tokens via transferNFT method"
        );
        return this.onERC1155Received.selector;
    }

    //----------------------------------------------------------------------------------
    // onlyOwner
    function setFee(uint16 _dstChainId, uint256 _fee) external onlyOwner {
        chainFee[_dstChainId] = _fee;
    }

    function setZkBridge(address _zkBridge) external onlyOwner {
        zkBridge = IZKBridge(_zkBridge);
    }

    function setWrappedAsset(
        uint16 _nativeChainId,
        address _nativeContract,
        address _wrapper
    ) external onlyOwner {
        wrappedAssets[_nativeChainId][_nativeContract] = _wrapper;
        wrappedAssetData[_wrapper] = WrappedAsset(
            _nativeChainId,
            _nativeContract
        );
    }

    function setTrustedRemoteAddress(
        uint16 _remoteChainId,
        address _remoteAddress
    ) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = _remoteAddress;
    }
}