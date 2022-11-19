// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Authorizer is Ownable {
    address public authorizer;

    mapping(address => mapping(uint256 => bool)) public usedNonces;

    event AuthorizerChanged(address indexed authorizer);

    function setAuthorizer(address _authorizer) public onlyOwner {
        authorizer = _authorizer;
        emit AuthorizerChanged(_authorizer);
    }

    function recoverAuthorizer(address recipient, uint256 amount, uint256 nonce, 
        uint256 underBlock, uint _type, bytes memory signature) 
        public 
        virtual
        pure
        returns(address)
    {
        bytes32 message = prefixed(keccak256(abi.encodePacked(recipient, amount, nonce, underBlock, _type)));
        return recoverSigner(message, signature);
    }

    function splitSignature(bytes memory sig)
        internal
        virtual
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        virtual
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

     function isNonceUsed(address _address, uint256 _nonce) public view returns(bool) {
        return usedNonces[_address][_nonce];
    }
}