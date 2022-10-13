pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SigVerify is Ownable {
    using ECDSA for bytes32;
    address signer;

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function isValidData(
        address sender,
        address tokenAddress,
        uint256 send_type,
        address[] memory recipients,
        uint256[] memory values,
        uint256 amount,
        uint256 num,
        bytes memory sig
    ) public view returns (bool) {
        bytes32 message = keccak256(
            abi.encodePacked(
                sender,
                tokenAddress,
                send_type,
                recipients,
                values,
                amount,
                num
            )
        );
        return (recoverSigner(ECDSA.toEthSignedMessageHash(message), sig) == signer);
    }

    function recoverSigner(bytes32 messageHash, bytes memory signedMessage)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        (v, r, s) = splitSignature(signedMessage);
        return ECDSA.recover(messageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }
}