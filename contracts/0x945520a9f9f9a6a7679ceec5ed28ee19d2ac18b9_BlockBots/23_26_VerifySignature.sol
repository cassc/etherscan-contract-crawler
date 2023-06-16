pragma solidity >=0.8.0;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract VerifySignature {
    using ECDSA for bytes32;
    mapping(bytes32 => bool) private _claimedHashes;

    function isHashClaimed(bytes32 _hash) public view returns (bool) {
        return _claimedHashes[_hash];
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return _messageHash.toEthSignedMessageHash();
    }

    function _setMessageHashClaimed(
        bytes32 _messageHash,
        address _signer,
        bytes memory _signature
    ) internal {
        require(!isHashClaimed(_messageHash), "cannot claim again");
        require(
            verify(getEthSignedMessageHash(_messageHash), _signer, _signature),
            "signature not verified"
        );
        _claimedHashes[_messageHash] = true;
    }

    function verify(
        bytes32 _ethSignedMessageHash,
        address _signer,
        bytes memory _signature
    ) public pure returns (bool) {
        return _ethSignedMessageHash.recover(_signature) == _signer;
    }
}