// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./EIP712Listable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

bytes32 constant ALLOW_MINT_TYPE =
    keccak256("Minter(address wallet)");

bytes32 constant BAG_MINT_TYPE =
    keccak256("Minter(string genesisBagAddress)");

bytes32 constant FREE_MINT_TYPE =
    keccak256("Minter(string genesisStakedAddress)");    


abstract contract EIP712Allowlisting is EIP712Listable {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Strings for uint160;
    using Strings for address;

    struct recovered { 
        address receipient;
        bytes signature;
        address recovered;
        address signingKey;
    }

    uint256[] empty;

    function recoverAllowAddress(bytes calldata sig, address recip) public view returns (recovered memory) {
        // bytes32 digest = keccak256(
        //     abi.encodePacked(
        //         "\x19\x01",
        //         DOM_SEP,
        //         keccak256(abi.encode(ALLOW_MINT_TYPE, recip))
        //     )
        // );      
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(ALLOW_MINT_TYPE, recip)));          
        address recoveredAddress = digest.recover(sig);
        
        return recovered(recip, sig, recoveredAddress, sigKey);
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
        address recovery = digest.recover(sig);
        require(recovery == sigKey, "invalid signature");
        require(msg.sender == recip, "invalid signature");
        _;
    }
    struct recoveredBag { 
        address receipient;
        bytes signature;
        address recovered;
        address signingKey;
        string bagging;
        uint256 total;
    }    
    
    function recoverClaimSig(bytes calldata sig, address recip, uint256[] memory bag) public view returns (recoveredBag memory) {        
        return recoverClaimSig(sig, recip, bag, empty);            
    }

    function recoverClaimSig(bytes calldata sig, address recip, uint256[] memory bag, uint256[] memory staked) public view returns (recoveredBag memory) {
        require(sigKey != address(0), "allowlist not enabled");
        uint total = uint(uint160(recip));
        for (uint i; i < bag.length; i++) {
            total += bag[i];
        }
        for (uint i; i < staked.length; i++) {
            total += staked[i];
        }        
        string memory bagged = total.toString();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOM_SEP,
                keccak256(abi.encode(FREE_MINT_TYPE,keccak256(abi.encodePacked(bagged))))
            )
        );
        address recovery = digest.recover(sig);
        return recoveredBag(recip, sig, recovery, sigKey, bagged, total);               
    }
    modifier requiresBagSig(bytes calldata sig, address recip, uint256[] memory bag) {
        require(sigKey != address(0), "allowlist not enabled");
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
        address recovery = digest.recover(sig);
        require(recovery == sigKey, "invalid signature");
        require(msg.sender == recip, "invalid signature");
        _;
    }        
    modifier requiresClaimSig(bytes calldata sig, address recip, uint256[] memory bag, uint256[] memory staked) {
        require(sigKey != address(0), "allowlist not enabled");
        uint total = uint(uint160(recip));
        for (uint i; i < bag.length; i++) {
            total += bag[i];
        }
        for (uint i; i < staked.length; i++) {
            total += staked[i];
        }        
        string memory bagged = total.toString();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOM_SEP,
                keccak256(abi.encode(FREE_MINT_TYPE,keccak256(abi.encodePacked(bagged))))
            )
        );
        address recovery = digest.recover(sig);
        require(recovery == sigKey, "invalid signature");
        require(msg.sender == recip, "invalid signature");
        _;
    }    
}