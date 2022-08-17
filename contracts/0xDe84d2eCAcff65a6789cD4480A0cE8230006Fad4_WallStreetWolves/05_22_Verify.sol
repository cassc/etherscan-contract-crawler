// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Delegated.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Verify is Delegated {
    using Strings for uint;
    using ECDSA for bytes32;

    address private signer;
    
    function verify( uint _quantity,  bytes memory _signature ) internal view returns ( bool ) {
        address signerCheck = getAddressSigner( _quantity.toString(), _signature );
        return signerCheck == signer;
    }

    function getAddressSigner( string memory _quantity, bytes memory _signature ) private view returns ( address ) {
        bytes32 hash = createHash( _quantity );
        return hash.toEthSignedMessageHash().recover( _signature );
    }

    function createHash( string memory _quantity ) private view returns ( bytes32 ) {
        return keccak256( abi.encodePacked( address(this), msg.sender, _quantity ) );
    }
    
    function setSigner( address _signer ) public onlyOwner{
        signer = _signer;
    }
}