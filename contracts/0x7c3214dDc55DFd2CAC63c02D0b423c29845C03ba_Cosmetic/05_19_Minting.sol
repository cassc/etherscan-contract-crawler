pragma solidity >=0.6.0 <0.8.0;

import "hardhat/console.sol";
import "./String.sol";


library Minting {

    function deserializeMintingBlob(bytes memory mintingBlob) internal pure returns (uint256, uint16) {
        string[] memory idParams = String.split(string(mintingBlob), ":");
        require(idParams.length == 2, "Invalid blob");
        string memory tokenIdString = String.substring(idParams[0], 1, bytes(idParams[0]).length - 1);
        string memory paramsString = String.substring(idParams[1], 1, bytes(idParams[1]).length - 1);

        uint256 tokenId = String.toUint(tokenIdString);
        uint16 proto = uint16(String.toUint(paramsString));

        return (tokenId, proto);
    }
}