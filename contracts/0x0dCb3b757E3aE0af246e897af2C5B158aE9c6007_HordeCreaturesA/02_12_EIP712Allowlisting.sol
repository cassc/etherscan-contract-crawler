// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./EIP712Listable.sol";

contract EIP712Allowlisting is EIP712Listable {
    using ECDSA for bytes32;

    bytes32 internal constant MINT_TYPE =
        keccak256("Minter(address wallet)");     

    struct recovered { 
        address receipient;
        bytes signature;
        address recovered;
        address signingKey;
    }

    function recoverAddress(bytes calldata sig, address recip) public view returns (recovered memory) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOM_SEP,
                keccak256(abi.encode(MINT_TYPE, recip))
            )
        );        
        address recoveredAddress = digest.recover(sig);
        
        return recovered(recip, sig, recoveredAddress, sigKey);
    }
    modifier requiresSig(bytes calldata sig, address recip) {
        require(sigKey != address(0), "allowlist not enabled");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOM_SEP,
                keccak256(abi.encode(MINT_TYPE, recip))
            )
        );
        address recovery = digest.recover(sig);
        require(recovery == sigKey, "invalid signature");
        _;
    }
}