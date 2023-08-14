// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MetadataOverrides is Ownable {
    mapping(string => string) public metadataOverrides;
    address public metadataContract;

    event MetadataOverridden(string indexed tokenHash, string newUri, string reason);

    constructor(address _metadataContract) {
        metadataContract = _metadataContract;
    }

    function overrideMetadata(string memory hash, string memory uri, string memory reason) external {
        require(msg.sender == metadataContract, "Only metadata contract can override metadata");
        metadataOverrides[hash] = uri;
        emit MetadataOverridden(hash, uri, reason);
    }

    function overrideMetadataBulk(string[] memory hashes, string[] memory uris, string[] memory reasons) external {
        require(msg.sender == metadataContract, "Only metadata contract can override metadata");
        require(hashes.length == uris.length && hashes.length == reasons.length, "Arrays are different lengths");
        for (uint256 i = 0; i < hashes.length; i++) {
            metadataOverrides[hashes[i]] = uris[i];
            emit MetadataOverridden(hashes[i], uris[i], reasons[i]);
        }
    }

    function setMetadataContract(address _metadataContract) external onlyOwner {
        metadataContract = _metadataContract;
    }
}