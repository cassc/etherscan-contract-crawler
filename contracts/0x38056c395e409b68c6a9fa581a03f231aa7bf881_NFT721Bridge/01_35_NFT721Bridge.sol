// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IZKBridge.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/IZKBridgeReceiver.sol";
import "./interfaces/ILayerZeroReceiver.sol";
import "./lzApp/NonblockingLzApp.sol";
import "./token/ZKBridgeErc1155.sol";
import "./token/ZKBridgeErc721.sol";


contract NFT721Bridge is Initializable, ReentrancyGuard, NonblockingLzApp {
    using BytesLib for bytes;

    event TransferNFT(uint64 indexed sequence, address token, uint256 tokenID, uint16 recipientChain, address sender, address recipient);

    event ReceiveNFT(uint64 indexed sequence, address sourceToken, address token, uint256 tokenID, uint16 sourceChain, uint16 sendChain, address recipient);

    struct WrappedAsset {
        uint16 nativeChainId;
        address nativeContract;
    }

    struct Transfer721 {

        // Address of the token.
        address tokenAddress;
        // Chain ID of the token
        uint16 tokenChain;
        // Symbol of the token
        bytes32 symbol;
        // Name of the token
        bytes32 name;
        // TokenID of the token
        uint256 tokenID;
        // URI of the token metadata (UTF-8)
        string uri;
        // Address of the recipient
        address to;
        // Chain ID of the recipient
        uint16 toChain;
    }

    uint16 public chainId;

    // Mapping of wrapped assets (chainID => nativeAddress => wrappedAddress)
    mapping(uint16 => mapping(address => address)) public wrappedAssets;

    // Mapping of wrapped assets data(wrappedAddress => WrappedAsset)
    mapping(address => WrappedAsset) public wrappedAssetData;

    // Mapping of receive chain fee
    mapping(uint16 => uint256) public chainFee;

    mapping(address => bool) public isONFT;

    function initialize(uint16 _chainId, address _endpoint) public initializer {
        __Ownable_init();
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
        chainId = _chainId;
    }

    function transferNFT(address _token, uint256 _tokenId, uint16 _recipientChain, address _recipient, bytes calldata _adapterParams) public payable nonReentrant returns (uint64 sequence) {
        require(msg.value >= chainFee[_recipientChain], "Insufficient Fee");

        (Transfer721 memory transfer, bytes memory payload) = _getPayload(_token, _tokenId, _recipientChain, _recipient);

        IERC721(_token).safeTransferFrom(msg.sender, address(this), _tokenId);
        if (wrappedAssetData[_token].nativeChainId != 0 || isONFT[_token]) {
            ZKBridgeErc721(_token).zkBridgeBurn(_tokenId);
        }

        uint256 lzFee = msg.value - chainFee[_recipientChain];
        sequence = _lzSend(transfer.toChain, payload, payable(msg.sender), msg.sender, _adapterParams, lzFee);
        emit TransferNFT(sequence, _token, _tokenId, _recipientChain, msg.sender, _recipient);
    }

    function _getPayload(address _token, uint256 _tokenId, uint16 _recipientChain, address _recipient) internal view returns (Transfer721 memory transfer, bytes memory payload) {
        uint16 tokenChain = chainId;
        address tokenAddress = _token;

        WrappedAsset memory wrappedAsset = wrappedAssetData[_token];
        if (!isONFT[_token] && wrappedAsset.nativeChainId != 0) {
            tokenChain = wrappedAsset.nativeChainId;
            tokenAddress = wrappedAsset.nativeContract;
        } else {
            // Verify that the correct interfaces are implemented
            require(ERC165(_token).supportsInterface(type(IERC721).interfaceId), "must support the ERC721 interface");
            require(ERC165(_token).supportsInterface(type(IERC721Metadata).interfaceId), "must support the ERC721-Metadata extension");
        }
        string memory symbolString = IERC721Metadata(_token).symbol();
        string memory nameString = IERC721Metadata(_token).name();
        string memory uriString = IERC721Metadata(_token).tokenURI(_tokenId);

        bytes32 symbol;
        bytes32 name;
        assembly {
            symbol := mload(add(symbolString, 32))
            name := mload(add(nameString, 32))
        }

        transfer = Transfer721(tokenAddress, tokenChain, symbol, name, _tokenId, uriString, _recipient, _recipientChain);
        payload = _encodeTransfer(transfer);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _sequence, bytes memory _payload) internal override {
        Transfer721 memory transfer = _parseTransfer(_payload);
        require(transfer.toChain == chainId, "invalid target chain");

        address transferToken;
        if (transfer.tokenChain == chainId) {
            transferToken = transfer.tokenAddress;
            if (isONFT[transferToken]) {
                ZKBridgeErc721(transferToken).zkBridgeMint(transfer.to, transfer.tokenID, transfer.uri);
            } else {
                IERC721(transferToken).safeTransferFrom(address(this), transfer.to, transfer.tokenID);
            }
        } else {
            address wrapped = wrappedAssets[transfer.tokenChain][transfer.tokenAddress];
            // If the wrapped asset does not exist yet, create it
            if (wrapped == address(0)) {
                wrapped = _createWrapped(transfer.tokenChain, transfer.tokenAddress, transfer.name, transfer.symbol);
            }
            transferToken = wrapped;
            // mint wrapped asset
            ZKBridgeErc721(wrapped).zkBridgeMint(transfer.to, transfer.tokenID, transfer.uri);
        }
        emit ReceiveNFT(_sequence, transfer.tokenAddress, transferToken, transfer.tokenID, transfer.tokenChain, _srcChainId, transfer.to);
    }

    function _encodeTransfer(Transfer721 memory _transfer) internal pure returns (bytes memory encoded) {
        // There is a global limit on 200 bytes of tokenURI in ZkBridge due to Solana
        require(bytes(_transfer.uri).length <= 200, "tokenURI must not exceed 200 bytes");
        encoded = abi.encodePacked(
            _transfer.tokenAddress,
            _transfer.tokenChain,
            _transfer.symbol,
            _transfer.name,
            _transfer.tokenID,
            _transfer.to,
            _transfer.toChain,
            _transfer.uri
        );
    }


    // Creates a wrapped asset using AssetMeta
    function _createWrapped(uint16 _tokenChain, address _tokenAddress, bytes32 _name, bytes32 _symbol) internal returns (address token) {
        require(_tokenChain != chainId, "can only wrap tokens from foreign chains");
        require(wrappedAssets[_tokenChain][_tokenAddress] == address(0), "wrapped asset already exists");
        token = address(new ZKBridgeErc721(_bytes32ToString(_name), _bytes32ToString(_symbol)));
        wrappedAssetData[token] = WrappedAsset(_tokenChain, _tokenAddress);
        wrappedAssets[_tokenChain][_tokenAddress] = token;
    }

    function _parseTransfer(bytes memory _encoded) public pure returns (Transfer721 memory transfer) {
        uint index = 0;

        transfer.tokenAddress = _encoded.toAddress(index);
        index += 20;

        transfer.tokenChain = _encoded.toUint16(index);
        index += 2;

        transfer.symbol = _encoded.toBytes32(index);
        index += 32;

        transfer.name = _encoded.toBytes32(index);
        index += 32;

        transfer.tokenID = _encoded.toUint256(index);
        index += 32;

        transfer.to = _encoded.toAddress(index);
        index += 20;

        transfer.toChain = _encoded.toUint16(index);
        index += 2;

        transfer.uri = string(_encoded.slice(index, _encoded.length - index));
    }


    function _bytes32ToString(bytes32 input) internal pure returns (string memory) {
        uint256 i;
        while (i < 32 && input[i] != 0) {
            i++;
        }
        bytes memory array = new bytes(i);
        for (uint c = 0; c < i; c++) {
            array[c] = input[c];
        }
        return string(array);
    }

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) external view returns (bytes4){
        require(operator == address(this), "can only bridge tokens via transferNFT method");
        return type(IERC721Receiver).interfaceId;
    }

    //----------------------------------------------------------------------------------
    // onlyOwner
    function setFee(uint16 _dstChainId, uint256 _fee) public onlyOwner {
        chainFee[_dstChainId] = _fee;
    }

    function setLzEndpoint(address _lzEndpoint) public onlyOwner {
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    function setWrappedAsset(uint16 _nativeChainId, address _nativeContract, address _wrapper) external onlyOwner {
        wrappedAssets[_nativeChainId][_nativeContract] = _wrapper;
        wrappedAssetData[_wrapper] = WrappedAsset(_nativeChainId, _nativeContract);
    }

    function setONFT(address _token, bool _isONFT) external onlyOwner {
        isONFT[_token] = _isONFT;
    }

    function estimateFee(address _token, uint256 _tokenId, uint16 _recipientChain, address _recipient, bytes calldata _adapterParams) external view returns (uint256 fee){
        (, bytes memory payload) = _getPayload(_token, _tokenId, _recipientChain, _recipient);
        (fee,) = lzEndpoint.estimateFees(_recipientChain, address(this), payload, false, _adapterParams);
        fee += chainFee[_recipientChain];
    }
}