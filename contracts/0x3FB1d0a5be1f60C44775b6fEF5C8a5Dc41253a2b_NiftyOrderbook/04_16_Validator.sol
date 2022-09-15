pragma solidity ^0.8.4;

import "./lib/EIP712.sol";
import "./INiftyOrderbook.sol";

contract Validator is INiftyOrderbook, EIP712 {
    bytes32 constant ORDER_TYPEHASH = keccak256(
        "Order(address maker,address contractAddress,uint256 amount,uint256 price,uint256 maxFee,uint256 expirationTime,uint256 salt)"
    );

    function hashOrder(Order memory order)
        public
        pure
        returns (bytes32 hash)
    {
        /* Per EIP 712. */
        return keccak256(abi.encode(
            ORDER_TYPEHASH,
            order.maker,
            order.contractAddress,
            order.amount,
            order.price,
            order.maxFee,
            order.expirationTime,
            order.salt
        ));
    }

    function hashToSign(bytes32 orderHash)
        internal
        view
        returns (bytes32 hash)
    {
        /* Calculate the string a user must sign. */
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            orderHash
        ));
    }

    function signatureValid(bytes32 orderHash, address maker, bytes memory signature) public view returns (bool isValid) {
        /* Calculate hash which must be signed. */
        bytes32 calculatedHashToSign = hashToSign(orderHash);
        
        uint8 v = uint8(signature[0]);
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(signature, 33))
            s := mload(add(signature, 65))
        }

        if (signature.length > 65 && signature[signature.length-1] == 0x03) { // EthSign byte
            /* (d.1): Old way: order hash signed by maker using the prefixed personal_sign */
            return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",calculatedHashToSign)), v, r, s) == maker;
        }
        /* (d.2): New way: order hash signed by maker using sign_typed_data */
        return ecrecover(calculatedHashToSign, v, r, s) == maker;
    }

}