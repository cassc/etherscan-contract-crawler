// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PfpRegistry is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC721Upgradeable
{
    uint256 public NAME_PRICE;
    uint256 public METADATA_PRICE;
    mapping(string => string) private _names;
    mapping(string => string) private _metadata;
    mapping(string => bool) private _taken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();

        NAME_PRICE = 0;
        METADATA_PRICE = 0;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setNamePrice(uint256 namePrice) external onlyOwner {
        NAME_PRICE = namePrice;
    }

    function setMetadataPrice(uint256 metadataPrice) external onlyOwner {
        METADATA_PRICE = metadataPrice;
    }

    function setName(
        address contractAddress,
        uint256 tokenId,
        string memory name
    ) external payable {
        require(msg.value == NAME_PRICE, "Invalid amount of ETH sent.");
        require(_taken[name] != true, "This name is already taken.");
        require(validName(name), "This name is not valid.");
        require(
            ERC721Upgradeable(contractAddress).ownerOf(tokenId) == msg.sender,
            "Sender is not the owner of this token."
        );

        string memory tokenKey = getTokenKey(contractAddress, tokenId);

        _taken[_names[tokenKey]] = false;
        _names[tokenKey] = name;
        _taken[name] = true;
    }

    function setMetadata(
        address contractAddress,
        uint256 tokenId,
        string memory metadataUri
    ) external payable {
        require(msg.value == METADATA_PRICE, "Invalid amount of ETH sent.");
        require(validUri(metadataUri), "This url is not valid.");
        require(
            ERC721Upgradeable(contractAddress).ownerOf(tokenId) == msg.sender,
            "Sender is not the owner of this token."
        );

        _metadata[getTokenKey(contractAddress, tokenId)] = metadataUri;
    }

    function getName(address contractAddress, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return _names[getTokenKey(contractAddress, tokenId)];
    }

    function getMetadata(address contractAddress, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return _metadata[getTokenKey(contractAddress, tokenId)];
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getTokenKey(address contractAddress, uint256 tokenId)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    contractAddress,
                    "|",
                    Strings.toString(tokenId)
                )
            );
    }

    function validUri(string memory str) private pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length >= 0) return true;
        return false;
    }

    function validName(string memory str) private pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length > 25) return false;

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char >= 0xC0 && char <= 0xDD) && //À-Ý
                !(char >= 0xE0 && char <= 0xFF) && //à-ÿ
                !(char == 0x20) && // space
                !(char == 0x2D) // -
            ) return false;
        }
        return true;
    }
}