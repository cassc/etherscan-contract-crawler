// contracts/Getters.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../interfaces/IERC20Extended.sol";
import "../../interfaces/IWormhole.sol";

import "./State.sol";
import "../../libraries/external/BytesLib.sol";

contract CATERC20Getters is CATERC20State {
    using BytesLib for bytes;

    function isTransferCompleted(bytes32 hash) public view returns (bool) {
        return _state.completedTransfers[hash];
    }

    function wormhole() public view returns (IWormhole) {
        return IWormhole(_state.wormhole);
    }

    function chainId() public view returns (uint16) {
        return _state.provider.chainId;
    }

    function evmChainId() public view returns (uint256) {
        return _state.evmChainId;
    }

    function tokenContracts(uint16 chainId_) public view returns (bytes32) {
        return _state.tokenImplementations[chainId_];
    }

    function finality() public view returns (uint8) {
        return _state.provider.finality;
    }

    function getDecimals() public view returns (uint8) {
        return _state.decimals;
    }

    function maxSupply() public view returns (uint256) {
        return _state.maxSupply;
    }

    function mintedSupply() public view returns (uint256) {
        return _state.mintedSupply;
    }

    function nativeAsset() public view returns (IERC20Extended) {
        return IERC20Extended(_state.nativeAsset);
    }

    function isInitialized() public view returns (bool) {
        return _state.isInitialized;
    }

    function isSignatureUsed(bytes memory signature) public view returns (bool) {
        return _state.signaturesUsed[signature];
    }

    function normalizeAmount(
        uint256 amount,
        uint8 foreignDecimals,
        uint8 localDecimals
    ) internal pure returns (uint256) {
        if (foreignDecimals > localDecimals) {
            amount /= 10 ** (foreignDecimals - localDecimals);
        }
        if (localDecimals > foreignDecimals) {
            amount *= 10 ** (localDecimals - foreignDecimals);
        }
        return amount;
    }

    /*
     * @dev Truncate a 32 byte array to a 20 byte address.
     *      Reverts if the array contains non-0 bytes in the first 12 bytes.
     *
     * @param bytes32 bytes The 32 byte array to be converted.
     */
    function bytesToAddress(bytes32 b) public pure returns (address) {
        require(bytes12(b) == 0, "invalid EVM address");
        return address(uint160(uint256(b)));
    }

    function addressToBytes(address a) public pure returns (bytes32) {
        return bytes32(uint256(uint160(a)));
    }

    function encodeTransfer(
        CATERC20Structs.CrossChainPayload memory transfer
    ) public pure returns (bytes memory encoded) {
        encoded = abi.encodePacked(
            transfer.amount,
            transfer.tokenAddress,
            transfer.tokenChain,
            transfer.toAddress,
            transfer.toChain,
            transfer.tokenDecimals
        );
    }

    function decodeTransfer(
        bytes memory encoded
    ) public pure returns (CATERC20Structs.CrossChainPayload memory transfer) {
        uint index = 0;

        transfer.amount = encoded.toUint256(index);
        index += 32;

        transfer.tokenAddress = encoded.toBytes32(index);
        index += 32;

        transfer.tokenChain = encoded.toUint16(index);
        index += 2;

        transfer.toAddress = encoded.toBytes32(index);
        index += 32;

        transfer.toChain = encoded.toUint16(index);
        index += 2;

        transfer.tokenDecimals = encoded.toUint8(index);
        index += 1;

        require(encoded.length == index, "invalid Transfer");
    }
}