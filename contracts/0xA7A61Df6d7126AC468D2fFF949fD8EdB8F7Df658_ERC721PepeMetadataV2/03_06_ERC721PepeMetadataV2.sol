// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./HexStringsV2.sol";
import "./interfaces/IERC721PepeMetadataV2.sol";
import "./interfaces/IMetadataOverrides.sol";


contract ERC721PepeMetadataV2 is IERC721PepeMetadataV2, Ownable {
    using HexStringsV2 for uint256;

    address public metadataOverridesContract;
    address public pepeContract;
    string public baseURI = "";
    mapping(address => bool) public mcManagers;

    event McManagerAdded(address newMcManager, address owner);
    event McManagerRemoved(address removedMcManager, address owner);

    constructor(string memory baseURI_) {
        baseURI = baseURI_;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setPepeContract(address _pepeContract) external onlyOwner {
        pepeContract = _pepeContract;
    }

    function setMetadataOverridesContract(address _metadataOverridesContract) external onlyOwner {
        metadataOverridesContract = _metadataOverridesContract;
    }

    function overrideMetadata(uint256 hash, string memory uri, string memory reason) external {
        require(msg.sender == owner() || mcManagers[msg.sender], "Only owner or McManager may override metadata");
        IMetadataOverrides(metadataOverridesContract).overrideMetadata(hash, uri, reason);
    }

    function overrideMetadataBulk(uint256[] memory hashes, string[] memory uris, string[] memory reasons) external {
        require(msg.sender == owner() || mcManagers[msg.sender], "Only owner or McManager may override metadata");
        IMetadataOverrides(metadataOverridesContract).overrideMetadataBulk(hashes, uris, reasons);
    }

    function addMcManager(address newMcManager) public onlyOwner {
        emit McManagerAdded(newMcManager, owner());
        mcManagers[newMcManager] = true;
    }

    function removeMcManager(address removedMcManager) public onlyOwner {
        emit McManagerRemoved(removedMcManager, owner());
        mcManagers[removedMcManager] = false;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * https://docs.ipfs.tech/concepts/hashing/
     */
    function tokenURI(uint256 hash) public view returns (string memory) {
        // check for uri override, and return that instead
        string memory metadataOverride = IMetadataOverrides(metadataOverridesContract).metadataOverrides(hash);
        if (bytes(metadataOverride).length != 0) {
            return metadataOverride;
        }

        return string(abi.encodePacked(baseURI, hash.uint2hexstr(), ".json"));
    }
}