// contracts/Bridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../libraries/external/BytesLib.sol";

import "./NFTBridgeGetters.sol";
import "./NFTBridgeSetters.sol";
import "./NFTBridgeStructs.sol";
import "./NFTBridgeGovernance.sol";

import "./token/NFT.sol";
import "./token/NFTImplementation.sol";
import "../interfaces/IZKBridgeReceiver.sol";

contract NFTBridge is NFTBridgeGovernance, IZKBridgeReceiver {
    using BytesLib for bytes;
    event TransferNFT(uint64 indexed sequence, address token, uint256 tokenID, uint16 recipientChain, address sender, address recipient);

    event ReceiveNFT(uint64 indexed sequence, address sourceToken, address token, uint256 tokenID, uint16 sourceChain, uint16 sendChain, address recipient);

    // Initiate a Transfer
    function transferNFT(address token, uint256 tokenID, uint16 recipientChain, bytes32 recipient) public payable returns (uint64 sequence) {
        // determine token parameters
        uint16 tokenChain;
        bytes32 tokenAddress;
        if (isWrappedAsset(token)) {
            tokenChain = NFTImplementation(token).chainId();
            tokenAddress = NFTImplementation(token).nativeContract();
        } else {
            tokenChain = chainId();
            tokenAddress = bytes32(uint256(uint160(token)));
            // Verify that the correct interfaces are implemented
            require(ERC165(token).supportsInterface(type(IERC721).interfaceId), "must support the ERC721 interface");
            require(ERC165(token).supportsInterface(type(IERC721Metadata).interfaceId), "must support the ERC721-Metadata extension");
        }

        string memory symbolString;
        string memory nameString;
        string memory uriString;
        {
            (,bytes memory queriedSymbol) = token.staticcall(abi.encodeWithSignature("symbol()"));
            (,bytes memory queriedName) = token.staticcall(abi.encodeWithSignature("name()"));
            symbolString = abi.decode(queriedSymbol, (string));
            nameString = abi.decode(queriedName, (string));
            (,bytes memory queriedURI) = token.staticcall(abi.encodeWithSignature("tokenURI(uint256)", tokenID));
            uriString = abi.decode(queriedURI, (string));
        }

        bytes32 symbol;
        bytes32 name;
        assembly {
        // first 32 bytes hold string length
        // mload then loads the next word, i.e. the first 32 bytes of the strings
        // NOTE: this means that we might end up with an
        // invalid utf8 string (e.g. if we slice an emoji in half).  The VAA
        // payload specification doesn't require that these are valid utf8
        // strings, and it's cheaper to do any validation off-chain for
        // presentation purposes
            symbol := mload(add(symbolString, 32))
            name := mload(add(nameString, 32))
        }

        IERC721(token).safeTransferFrom(msg.sender, address(this), tokenID);
        if (tokenChain != chainId()) {
            NFTImplementation(token).burn(tokenID);
        }

        sequence = logTransfer(NFTBridgeStructs.Transfer({
        tokenAddress : tokenAddress,
        tokenChain : tokenChain,
        name : name,
        symbol : symbol,
        tokenID : tokenID,
        uri : uriString,
        to : recipient,
        toChain : recipientChain
        }), msg.value);

        emit TransferNFT(sequence, token, tokenID, recipientChain, msg.sender, _truncateAddress(recipient));
    }


    function transferNFTBatch(address[] memory tokenList, uint256[] memory tokenIDList, uint16 recipientChain, bytes32 recipient) public payable returns (uint64 sequence)  {
        require(tokenList.length == tokenIDList.length, "length error");

        bytes32[] memory tokenAddressList = new bytes32[](tokenList.length);
        uint16[] memory tokenChainList = new uint16[](tokenList.length);
        bytes32[] memory nameList = new bytes32[](tokenList.length);
        bytes32[] memory symbolList = new bytes32[](tokenList.length);
        string[] memory uriStringList = new string[](tokenList.length);
        uint256[] memory tokenIDLists = new uint256[](tokenList.length);

        for (uint256 i; i < tokenList.length; i++) {
            address token = tokenList[i];
            uint256 tokenID = tokenIDList[i];
            uint16 tokenChain;
            bytes32 tokenAddress;
            if (isWrappedAsset(token)) {
                tokenChain = NFTImplementation(token).chainId();
                tokenAddress = NFTImplementation(token).nativeContract();
            } else {
                tokenChain = chainId();
                tokenAddress = bytes32(uint256(uint160(token)));
                // Verify that the correct interfaces are implemented
                require(ERC165(token).supportsInterface(type(IERC721).interfaceId), "must support the ERC721 interface");
                require(ERC165(token).supportsInterface(type(IERC721Metadata).interfaceId), "must support the ERC721-Metadata extension");
            }
            tokenAddressList[i] = tokenAddress;

            string memory symbolString;
            string memory nameString;
            string memory uriString;
            {
                (,bytes memory queriedSymbol) = token.staticcall(abi.encodeWithSignature("symbol()"));
                (,bytes memory queriedName) = token.staticcall(abi.encodeWithSignature("name()"));
                symbolString = abi.decode(queriedSymbol, (string));
                nameString = abi.decode(queriedName, (string));
                (,bytes memory queriedURI) = token.staticcall(abi.encodeWithSignature("tokenURI(uint256)", tokenID));
                uriString = abi.decode(queriedURI, (string));
            }

            bytes32 symbol;
            bytes32 name;
            assembly {
            // first 32 bytes hold string length
            // mload then loads the next word, i.e. the first 32 bytes of the strings
            // NOTE: this means that we might end up with an
            // invalid utf8 string (e.g. if we slice an emoji in half).  The VAA
            // payload specification doesn't require that these are valid utf8
            // strings, and it's cheaper to do any validation off-chain for
            // presentation purposes
                symbol := mload(add(symbolString, 32))
                name := mload(add(nameString, 32))
            }

            IERC721(token).safeTransferFrom(msg.sender, address(this), tokenID);
            if (tokenChain != chainId()) {
                NFTImplementation(token).burn(tokenID);
            }

            tokenChainList[i] = tokenChain;
            nameList[i] = name;
            symbolList[i] = symbol;
            uriStringList[i] = uriString;
            tokenIDLists[i] = tokenID;
        }

        sequence = logTransferBatch(NFTBridgeStructs.TransferBatch({
        tokenAddress : tokenAddressList,
        tokenChain : tokenChainList,
        name : nameList,
        symbol : symbolList,
        tokenID : tokenIDLists,
        uri : uriStringList,
        to : recipient,
        toChain : recipientChain
        }), msg.value);

        for (uint256 i = 0; i < tokenList.length; i++) {
            emit TransferNFT(sequence, tokenList[i], tokenIDList[i], recipientChain, msg.sender, _truncateAddress(recipient));
        }
    }

    function logTransfer(NFTBridgeStructs.Transfer memory transfer, uint256 callValue) internal returns (uint64 sequence) {
        bytes memory encoded = encodeTransfer(transfer);
        address dstContractAddress = bridgeContracts(transfer.toChain);
        sequence = zkBridge().send{value : callValue}(transfer.toChain, dstContractAddress, encoded);
    }

    function logTransferBatch(NFTBridgeStructs.TransferBatch memory transfer, uint256 callValue) internal returns (uint64 sequence) {
        for (uint256 i = 0; i < transfer.uri.length; i++) {
            require(bytes(transfer.uri[i]).length <= 200, "tokenURI must not exceed 200 bytes");
        }
        bytes memory encoded = abi.encode(
            transfer.tokenAddress,
            transfer.tokenChain,
            transfer.symbol,
            transfer.name,
            transfer.tokenID,
            transfer.uri,
            transfer.to,
            transfer.toChain
        );
        address dstAddress = bridgeContracts(transfer.toChain);
        sequence = zkBridge().send{value : callValue}(transfer.toChain, dstAddress, encoded);
    }

    function zkReceive(uint16 srcChainId, address srcAddress, uint64 sequence, bytes calldata payload) external override {
        require(msg.sender == address(zkBridge()), "Not From ZKBridgeEntrypoint");
        require(bridgeContracts(srcChainId) == srcAddress, "invalid emitter");

        uint8 payloadID = payload.toUint8(0);
        if (payloadID == 1) {
            _completeTransfer(srcChainId, sequence, payload);
        } else {
            _completeTransferBatch(srcChainId, sequence, payload);
        }

    }

    function _completeTransfer(uint16 srcChainId, uint64 sequence, bytes calldata payload) internal {
        NFTBridgeStructs.Transfer memory transfer = parseTransfer(payload);
        require(transfer.toChain == chainId(), "invalid target chain");

        IERC721 transferToken;
        if (transfer.tokenChain == chainId()) {
            transferToken = IERC721(_truncateAddress(transfer.tokenAddress));
        } else {
            address wrapped = wrappedAsset(transfer.tokenChain, transfer.tokenAddress);
            // If the wrapped asset does not exist yet, create it
            if (wrapped == address(0)) {
                wrapped = _createWrapped(transfer.tokenChain, transfer.tokenAddress, transfer.name, transfer.symbol);
            }
            transferToken = IERC721(wrapped);
        }
        // transfer bridged NFT to recipient
        address transferRecipient = _truncateAddress(transfer.to);

        if (transfer.tokenChain != chainId()) {
            // mint wrapped asset
            NFTImplementation(address(transferToken)).mint(transferRecipient, transfer.tokenID, transfer.uri);
        } else {
            transferToken.safeTransferFrom(address(this), transferRecipient, transfer.tokenID);
        }

        emit ReceiveNFT(sequence, _truncateAddress(transfer.tokenAddress), address(transferToken), transfer.tokenID, transfer.tokenChain, srcChainId, transferRecipient);
    }

    function _completeTransferBatch(uint16 srcChainId, uint64 sequence, bytes calldata payload) internal {
        NFTBridgeStructs.TransferBatch memory transfer = parseTransferBatch(payload);
        require(transfer.toChain == chainId(), "invalid target chain");

        for (uint256 i = 0; i < transfer.tokenAddress.length; i++) {
            IERC721 transferToken;
            if (transfer.tokenChain[i] == chainId()) {
                transferToken = IERC721(_truncateAddress(transfer.tokenAddress[i]));
            } else {
                address wrapped = wrappedAsset(transfer.tokenChain[i], transfer.tokenAddress[i]);

                // If the wrapped asset does not exist yet, create it
                if (wrapped == address(0)) {
                    wrapped = _createWrapped(transfer.tokenChain[i], transfer.tokenAddress[i], transfer.name[i], transfer.symbol[i]);
                }

                transferToken = IERC721(wrapped);
            }

            // transfer bridged NFT to recipient
            address transferRecipient = _truncateAddress(transfer.to);

            if (transfer.tokenChain[i] != chainId()) {
                // mint wrapped asset
                NFTImplementation(address(transferToken)).mint(transferRecipient, transfer.tokenID[i], transfer.uri[i]);
            } else {
                transferToken.safeTransferFrom(address(this), transferRecipient, transfer.tokenID[i]);
            }
            emit ReceiveNFT(sequence, _truncateAddress(transfer.tokenAddress[i]), address(transferToken), transfer.tokenID[i], transfer.tokenChain[i], srcChainId, transferRecipient);
        }

    }

    // Creates a wrapped asset using AssetMeta
    function _createWrapped(uint16 tokenChain, bytes32 tokenAddress, bytes32 name, bytes32 symbol) internal returns (address token) {
        require(tokenChain != chainId(), "can only wrap tokens from foreign chains");
        require(wrappedAsset(tokenChain, tokenAddress) == address(0), "wrapped asset already exists");

        // initialize the NFTImplementation
        bytes memory initialisationArgs = abi.encodeWithSelector(
            NFTImplementation.initialize.selector,
            bytes32ToString(name),
            bytes32ToString(symbol),
            address(this),
            tokenChain,
            tokenAddress
        );

        // initialize the BeaconProxy
        bytes memory constructorArgs = abi.encode(address(this), initialisationArgs);

        // deployment code
        bytes memory bytecode = abi.encodePacked(type(BridgeNFT).creationCode, constructorArgs);

        bytes32 salt = keccak256(abi.encodePacked(tokenChain, tokenAddress));

        assembly {
            token := create2(0, add(bytecode, 0x20), mload(bytecode), salt)

            if iszero(extcodesize(token)) {
                revert(0, 0)
            }
        }

        _setWrappedAsset(tokenChain, tokenAddress, token);
    }


    function encodeTransfer(NFTBridgeStructs.Transfer memory transfer) internal pure returns (bytes memory encoded) {
        // There is a global limit on 200 bytes of tokenURI in ZkBridge due to Solana
        require(bytes(transfer.uri).length <= 200, "tokenURI must not exceed 200 bytes");

        encoded = abi.encodePacked(
            uint8(1),
            transfer.tokenAddress,
            transfer.tokenChain,
            transfer.symbol,
            transfer.name,
            transfer.tokenID,
            uint8(bytes(transfer.uri).length),
            transfer.uri,
            transfer.to,
            transfer.toChain
        );
    }

    function parseTransfer(bytes memory encoded) internal pure returns (NFTBridgeStructs.Transfer memory transfer) {
        uint index = 0;

        uint8 payloadID = encoded.toUint8(index);
        index += 1;

        require(payloadID == 1, "invalid Transfer");

        transfer.tokenAddress = encoded.toBytes32(index);
        index += 32;

        transfer.tokenChain = encoded.toUint16(index);
        index += 2;

        transfer.symbol = encoded.toBytes32(index);
        index += 32;

        transfer.name = encoded.toBytes32(index);
        index += 32;

        transfer.tokenID = encoded.toUint256(index);
        index += 32;

        // Ignore length due to malformatted payload
        index += 1;
        transfer.uri = string(encoded.slice(index, encoded.length - index - 34));

        // From here we read backwards due malformatted package
        index = encoded.length;

        index -= 2;
        transfer.toChain = encoded.toUint16(index);

        index -= 32;
        transfer.to = encoded.toBytes32(index);

        //require(encoded.length == index, "invalid Transfer");
    }

    function parseTransferBatch(bytes memory encoded) internal pure returns (NFTBridgeStructs.TransferBatch memory transfer) {
        (transfer.tokenAddress,
        transfer.tokenChain,
        transfer.symbol,
        transfer.name,
        transfer.tokenID,
        transfer.uri,
        transfer.to,
        transfer.toChain) = abi.decode(encoded, (bytes32[], uint16[], bytes32[], bytes32[], uint256[], string[], bytes32, uint16));
    }

    /*
     * @dev Truncate a 32 byte array to a 20 byte address.
     *      Reverts if the array contains non-0 bytes in the first 12 bytes.
     *
     * @param bytes32 bytes The 32 byte array to be converted.
     */
    function _truncateAddress(bytes32 b) internal pure returns (address) {
        require(bytes12(b) == 0, "invalid EVM address");
        return address(uint160(uint256(b)));
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

    function bytes32ToString(bytes32 input) internal pure returns (string memory) {
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
}