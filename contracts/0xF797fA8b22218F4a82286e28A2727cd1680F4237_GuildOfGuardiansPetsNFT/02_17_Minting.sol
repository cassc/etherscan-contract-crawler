pragma solidity >=0.8.0 <0.9.0;

import "hardhat/console.sol";
import "./String.sol";

library Minting {
    function deserializeMintingBlobWithChroma(bytes memory mintingBlob)
        internal
        pure
        returns (
            uint256,
            uint16,
            uint256,
            uint8,
            string memory
        )
    {
        string[] memory idParams = String.split(string(mintingBlob), ":");
        require(idParams.length == 2, "Invalid blob");
        string memory tokenIdString = String.substring(
            idParams[0],
            1,
            bytes(idParams[0]).length - 1
        );
        string memory paramsString = String.substring(
            idParams[1],
            1,
            bytes(idParams[1]).length - 1
        );

        string[] memory paramParts = String.split(paramsString, ",");
        require(paramParts.length == 4, "Invalid param count");

        uint256 tokenId = String.toUint(tokenIdString);
        uint16 proto = uint16(String.toUint(paramParts[0]));
        uint256 serialNumber = uint256(String.toUint(paramParts[1]));
        uint8 chroma = uint8(String.toUint(paramParts[2]));
        string memory tokenURI = paramParts[3];
        return (tokenId, proto, serialNumber, chroma, tokenURI);
    }

    function deserializeMintingBlob(bytes memory mintingBlob)
        internal
        pure
        returns (
            uint256,
            uint16,
            uint256,
            string memory
        )
    {
        string[] memory idParams = String.split(string(mintingBlob), ":");
        require(idParams.length == 2, "Invalid blob");
        string memory tokenIdString = String.substring(
            idParams[0],
            1,
            bytes(idParams[0]).length - 1
        );
        string memory paramsString = String.substring(
            idParams[1],
            1,
            bytes(idParams[1]).length - 1
        );

        string[] memory paramParts = String.split(paramsString, ",");
        require(paramParts.length == 3, "Invalid param count");

        uint256 tokenId = String.toUint(tokenIdString);
        uint16 proto = uint16(String.toUint(paramParts[0]));
        uint256 serialNumber = uint256(String.toUint(paramParts[1]));
        string memory tokenURI = paramParts[2];
        return (tokenId, proto, serialNumber, tokenURI);
    }
}