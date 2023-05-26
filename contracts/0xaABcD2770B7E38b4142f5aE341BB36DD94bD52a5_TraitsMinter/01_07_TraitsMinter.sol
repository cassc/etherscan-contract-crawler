// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/ITraits.sol";

/// @title Bulls and Apes Project - Traits Minter
/// @author BAP Dev Team
/// @notice Helper contract to mint traits
contract TraitsMinter is ReentrancyGuard, Ownable {
    using Strings for uint256;

    /// @notice BAP Traits contract
    ITraits public traitsContract;
    /// @notice Address of the signer wallet
    address public secret;

    mapping (bytes => bool) public usedSignatures;

    event TraitsMinted( uint256[] traitsOut, uint256[] traitsOutAmounts, bytes signature, address operator);

    /// @notice Deploys the contract
    /// @param _traits BAP Traits address
    /// @param _secret Signer address
    constructor(
        address _traits,
        address _secret
    ) {
        traitsContract = ITraits(_traits);
        secret = _secret;
    }

    /// @notice Equip or remove traits for the Ape
    /// @param traitsOut Id of traits to be minted
    /// @param timeOut Time out for signature expiration
    /// @param signature Signature to verify above parameters
    /// @dev Mint off chain traits to user
    function mintTraits(
        uint256[] memory traitsOut, 
        uint256[] memory traitsOutAmounts, 
        uint256 timeOut, 
        bytes memory signature
    ) external nonReentrant {
        require(!usedSignatures[signature], "MintTraits: Signature already used");
        require(timeOut > block.timestamp, "MintTraits: Signature expired");
        require(traitsOut.length == traitsOutAmounts.length, "MintTraits: Invalid traits length");

        usedSignatures[signature] = true;

        string memory traitCode; 

        for (uint256 i = 0; i < traitsOut.length; i++) {
            traitCode = string.concat(traitCode, "T", traitsOut[i].toString()); 
            traitCode = string.concat(traitCode, "Q", traitsOutAmounts[i].toString()); 
        }

        require(
            _verifyHashSignature(
                keccak256(
                    abi.encode(
                        timeOut,
                        traitCode,
                        msg.sender
                    )
                ),
                signature
            ), 
            "MintTraits: Signature is invalid"
        );
  
        traitsContract.mintBatch(msg.sender, traitsOut, traitsOutAmounts); 

        emit TraitsMinted(traitsOut, traitsOutAmounts, signature, msg.sender);
    }

    /// @notice Set new contracts addresses for Apes and Traits
    /// @param _traits New address for BAP Traits
    /// @dev Can only be called by the contract owner
    function setContracts(address _traits) external onlyOwner {
        traitsContract = ITraits(_traits);
    }

    /// @notice Change the signer address
    /// @param _secret new signer for encrypted signatures
    /// @dev Can only be called by the contract owner
    function setSecret(address _secret) external onlyOwner {
        secret = _secret;
    }

    function _verifyHashSignature(bytes32 freshHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }
}