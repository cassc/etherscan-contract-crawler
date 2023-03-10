// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./EIP712Listable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

bytes32 constant ALLOW_MINT_TYPE =
    keccak256("Minter(address wallet)");

bytes32 constant INITIATE_MINT_TYPE =
    keccak256("Minter(string initiateAddress)");

bytes32 constant FREE_MINT_TYPE =
    keccak256("Minter(string elderAddress)");    


abstract contract EIP712Allowlisting is EIP712Listable {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Strings for uint160;
    using Strings for address;
    string constant invalid = "invalid signature";
    function isValid(address recovery, address recip) private view {
        require(recovery == sigKey, invalid);
        require(msg.sender == recip, invalid);
    }
    modifier requiresAllowSig(bytes calldata sig, address recip) {
        require(sigKey != address(0), "allowlist not enabled");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOM_SEP,
                keccak256(abi.encode(ALLOW_MINT_TYPE, recip))
            )
        );
        isValid(digest.recover(sig),recip);
        _;
    }
       
    modifier requiresClaimSig(bytes calldata sig, address recip, uint256[] memory bag) {
        require(sigKey != address(0), "not enabled");
        uint total = uint(uint160(recip));
        for (uint i; i < bag.length; i++) {
            total += bag[i];
        }
   
        string memory bagged = total.toString();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOM_SEP,
                keccak256(abi.encode(FREE_MINT_TYPE,keccak256(abi.encodePacked(bagged))))
            )
        );
        
        isValid(digest.recover(sig),recip);
        _;
    }    
}