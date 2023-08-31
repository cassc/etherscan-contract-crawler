// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/interfaces/IERC721Metadata.sol";
import "openzeppelin-contracts/contracts/utils/Base64.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

import "./AccessControlled.sol";
import "./IAddressProvider.sol";
import "./IMetadataProvider.sol";

contract MetadataProvider is AccessControlled, IMetadataProvider {
    using Strings for uint256;

    string public imageBaseUrl;

    constructor(address accesssController_) AccessControlled(accesssController_) {}

    function tokenURI(uint256 tokenId, address replicanContract, bool validity, bytes memory)
        public
        view
        returns (string memory)
    {
        IERC721Metadata replican = IERC721Metadata(replicanContract);
        string memory name = replican.name();
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "',
            name,
            " #",
            tokenId.toString(),
            '",',
            '"image": "',
            _getImageUrl(validity),
            '",',
            '"attributes": [',
            _stateAttribute(validity),
            "]",
            "}"
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
    }

    function _getImageUrl(bool validity) private view returns (bytes memory) {
        if (validity) {
            return abi.encodePacked(imageBaseUrl, "secure");
        } else {
            return abi.encodePacked(imageBaseUrl, "insecure");
        }
    }

    function _stateAttribute(bool validity) private pure returns (bytes memory) {
        bytes memory attribute = abi.encodePacked('{"trait_type": "State",');
        string memory value;
        if (validity) {
            value = "Secure";
        } else {
            value = "Insecure";
        }
        attribute = abi.encodePacked(attribute, '"value" : "', value, '"}');
        return attribute;
    }

    function setImageBaseUrl(string calldata imageBaseUrl_) public onlyMetadataManager {
        imageBaseUrl = imageBaseUrl_;
    }
}