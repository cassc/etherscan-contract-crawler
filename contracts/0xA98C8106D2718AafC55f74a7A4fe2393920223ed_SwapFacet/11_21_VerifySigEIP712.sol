// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "../libraries/LibDiamond.sol";
import "../interfaces/Structs.sol";
import {LengthNotMatch} from "../Errors/GenericErrors.sol";

contract VerifySigEIP712 is EIP712("Plexus", "1") {
    bytes32 internal constant DATA_STORAGE_POSITION = keccak256("diamond.standard.sig.storage");

    struct SigData {
        address[] signerList;
        mapping(bytes32 => bool) txHashCheck; //add
    }

    struct Input {
        bytes data;
        uint256 gasFee;
        uint256 transferFee;
        address userAddress;
        bytes32 txHash;
    }

    bytes32 private constant SWAP_TYPEHASH = keccak256("Input(bytes data,uint256 gasFee,uint256 transferFee,address userAddress,bytes32 txHash)");

    function sigDataStorage() internal pure returns (SigData storage s) {
        bytes32 position = DATA_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := position
        }
    }

    function contractOwnerAddress() public view returns (address owner) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        owner = ds.contractOwner;
    }

    function relaySig(Input memory inputData, bytes[] memory signature) public view returns (bool) {
        uint256 CheckCount;
        SigData storage ds = sigDataStorage();
        require(ds.txHashCheck[inputData.txHash] == false, "already passed");
        for (uint256 i = 0; i < signature.length; i++) {
            bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SWAP_TYPEHASH,
                        keccak256(inputData.data),
                        inputData.gasFee,
                        inputData.transferFee,
                        inputData.userAddress,
                        inputData.txHash
                    )
                )
            );
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature[i]);
            address signer = ECDSA.recover(digest, v, r, s);
            if (signer == ds.signerList[i]) {
                CheckCount++;
            }
        }
        if (CheckCount == signature.length) return true;
        else {
            revert LengthNotMatch();
        }
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }
}