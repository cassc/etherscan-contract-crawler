import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721AWhitelist is Ownable{

    function recoverWhitelistSigner(bytes32 hash, bytes memory signature) public pure returns(address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(hash, v, r, s);
    }
    function recoverSigner(bytes32 hash, bytes memory signature) public pure returns(address)  {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(hash, v, r, s);
    }

   function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}