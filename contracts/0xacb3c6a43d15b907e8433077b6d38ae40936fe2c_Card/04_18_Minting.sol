pragma solidity >=0.6.0 <0.8.0;

import "hardhat/console.sol";
import "./String.sol";


library Minting {

    function deserializeMintingBlob(bytes memory mintingBlob) internal pure returns (uint256, uint16, uint8) {
        string[] memory idParams = String.split(string(mintingBlob), ":");
        require(idParams.length == 2, "Invalid blob");
        string memory tokenIdString = String.substring(idParams[0], 1, bytes(idParams[0]).length - 1);
        string memory paramsString = String.substring(idParams[1], 1, bytes(idParams[1]).length - 1);

        string[] memory paramParts = String.split(paramsString, ",");
        require(paramParts.length == 2, "Invalid param count");

        uint256 tokenId = String.toUint(tokenIdString);
        uint16 proto = uint16(String.toUint(paramParts[0]));
        uint8 quality = uint8(String.toUint(paramParts[1]));

        return (tokenId, proto, quality);
    }
}