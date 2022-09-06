pragma solidity 0.4.24;

import "contracts/lib/ERC1271.sol";

contract ERC1271Bytes is ERC1271 {
    /**
     * @dev Default behavior of `isValidSignature(bytes,bytes)`, can be overloaded for custom validation
     * @param _data Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     * @return A bytes4 magic value 0x20c13b0b if the signature check passes, 0x00000000 if not
     *
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes _data, bytes _signature)
        public
        view
        returns (bytes4)
    {
        return isValidSignature(keccak256(_data), _signature);
    }
}