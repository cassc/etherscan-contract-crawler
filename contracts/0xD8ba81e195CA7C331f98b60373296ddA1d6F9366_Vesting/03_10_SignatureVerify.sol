pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SignatureVerify {
    address private _systemAddress;

    constructor(address systemAddress_) {
        _systemAddress = systemAddress_;
    }

    function checkClaimRequest(
        address senderAddress,
        address contractAddress,
        uint256 amount,
        bytes calldata signature
    ) internal {
        if (
            !_verify(
                _systemAddress,
                _hash(senderAddress, contractAddress, amount),
                signature
            )
        ) {
            revert("Not auth request");
        }
    }

    function _verify(
        address singerAddress,
        bytes32 hash,
        bytes calldata signature
    ) private pure returns (bool) {
        return singerAddress == ECDSA.recover(hash, signature);
    }

    function _hash(
        address senderAddress,
        address contractAddress,
        uint256 amount
    ) private pure returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(senderAddress, contractAddress, amount)
                )
            );
    }
}