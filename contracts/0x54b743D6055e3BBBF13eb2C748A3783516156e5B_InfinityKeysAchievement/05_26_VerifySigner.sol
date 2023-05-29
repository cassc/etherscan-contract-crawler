// SPDX-License-Identifier: MIT
// 2022 Infinity Keys Team
pragma solidity ^0.8.4;

/*************************************************************
* @title: Verify Signer                                      *
* @notice: require a valid ECDSA signature of a standardized *
* message signed by signer before mint approval              *
*************************************************************/

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Authorized.sol";

contract VerifySigner is Authorized {
    using ECDSA for bytes32;
    using Strings for uint256;

    string private secret;
    address private signer;

    /**
    * @dev Check ECDSA for server verification to prevent contract mints.
    */
    function verify( uint256 _tokenID, bytes memory _signature ) internal view returns ( bool ) {
        address signerCheck = getAddressSigner( _tokenID.toString(), _signature );
        return signerCheck == signer;
    }

    /**
    * @dev Return address of signer from ECDSA signature message.
    */
    function getAddressSigner( string memory _tokenID, bytes memory _signature ) private view returns ( address ) {
        bytes32 hash = createHash( _tokenID );
        return hash.toEthSignedMessageHash().recover( _signature );
    }

    /**
    * @dev Create hash of information needed.
    */
    function createHash( string memory _tokenID ) private view returns ( bytes32 ) {
        return keccak256( abi.encodePacked( address(this), msg.sender, _tokenID, secret ) );
    }
    
    /**
    * @dev Set the secret used in hash (onlyOwner)
    */
    function setSecret( string memory _secret ) public onlyOwner {
        secret = _secret;
    }

    /**
    * @dev Set the signer used to sign the message (onlyOwner)
    */
    function setSigner( address _signer ) public onlyOwner {
        signer = _signer;
    }

}