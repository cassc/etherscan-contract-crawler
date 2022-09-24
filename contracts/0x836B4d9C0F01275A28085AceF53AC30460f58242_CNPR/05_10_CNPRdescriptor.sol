// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interface/ICNPRdescriptor.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 *  @title CnprDescriptor contract for CNPR tokenURI.
 *  @dev Ensure that when gas prices become lower in the future, they can be easily transitioned to on-chain.
 */
contract CNPRdescriptor is ICNPRdescriptor, Ownable {
    // The baseURI of metadata
    string public baseURI;

    // The Extension of URI
    string public baseExtension = ".json";

    /**
     *  @notice Given a token ID, construct a token URI for the CNPR.
     *  @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *  @param _tokenId The token id.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return dataURI(_tokenId);
    }

    /**
     *  @notice Given a token ID , construct a data URI for the CNPR.
     *  @param _tokenId The token id.
     *  @return The data URI for CNPR.
     */
    function dataURI(uint256 _tokenId) public view returns (string memory) {
        return string(abi.encodePacked(_tokenURI(_tokenId), baseExtension));
    }

    /**
     *  @dev Return the token URI.
     *  @param _tokenId The token id.
     *  @return The token URI for CNPR.
     */
    function _tokenURI(uint256 _tokenId) internal view returns (string memory) {
        string memory baseURI_ = _baseURI();
        return
            bytes(baseURI_).length != 0
                ? string(abi.encodePacked(baseURI_, _toString(_tokenId)))
                : "";
    }

    /**
     *  @dev Return the URI of the base.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    /**
     *  @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory ptr)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }

    /**
     *  @notice Set the base URI for all token IDs.
     *  @dev Only callable by the owner.
     *  @param baseURI_ The baseURI of the token.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     *  @notice Set the base URI extension for all token IDs.
     *  @dev Only callable by the owner.
     *  @param _baseExtension The base extension of the token.
     */
    function setBaseExtension(string memory _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }
}