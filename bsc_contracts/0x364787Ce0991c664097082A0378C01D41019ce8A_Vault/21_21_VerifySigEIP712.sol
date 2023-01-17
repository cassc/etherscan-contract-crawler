// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VerifySigEIP712 is EIP712("Plexus", "1"), Ownable {
    address[] public ownerList;
    struct Input {
        address fromTokenAddress;
        address toTokenAddress;
        uint256 amount; // ToChain넘어와서 브릿지가 볼트로 보내줄때 그 수량. ( 수루료 빠지기 전 )
        uint256 gasFee; // 가스비를 확인해서 그만큼의 token수량
        address userAddress;
        bytes32 txHash;
        uint256 minOut;
    }
    bytes32 private constant SWAP_TYPEHASH =
        keccak256(
            "Input(address fromTokenAddress,address toTokenAddress,uint256 amount,uint256 gasFee,address userAddress,bytes32 txHash,uint256 minOut)"
        );

    function setSigner(address[] memory _owner) public onlyOwner {
        for (uint256 i = 0; i < _owner.length; i++) {
            ownerList.push(_owner[i]);
        }
    }

    function relaySig(Input memory _swapData, bytes[] memory signature) public view returns (bool) {
        uint256 CheckCount;
        Input memory inputData = _swapData;
        for (uint256 i = 0; i < signature.length; i++) {
            bytes32 digest = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        SWAP_TYPEHASH,
                        inputData.fromTokenAddress,
                        inputData.toTokenAddress,
                        inputData.amount,
                        inputData.gasFee,
                        inputData.userAddress,
                        inputData.txHash,
                        inputData.minOut
                    )
                )
            );
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature[i]);
            address signer = ECDSA.recover(digest, v, r, s);
            if (signer == ownerList[i]) {
                CheckCount++;
            }
        }
        if (CheckCount == signature.length) return true;
        else {
            revert("not match");
        }
    }

    // 시그니쳐 넣으면 r s v 찢어주는 함수
    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
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