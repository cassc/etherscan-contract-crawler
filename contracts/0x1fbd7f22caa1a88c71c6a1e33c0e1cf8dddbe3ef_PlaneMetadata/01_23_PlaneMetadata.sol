// File: contracts/PlaneMetadata.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "./IArtData.sol";
import "./IArtFactory.sol";
import "./IMetadataTraits.sol";
import "./IPlaneMetadata.sol";
import "./IRenderer.sol";
import "./Structs.sol";

contract PlaneMetadata is IPlaneMetadata, ReentrancyGuard, Ownable {
    using Strings for uint;

    address _artAddr;
    address _codeAddr;
    address _htmlAddr;
    address _artFactoryAddr;
    address _traitsAddr;
    address _previewerAddr;
    address _rendererAddr;

    string _externalUri = "https://twitter.com/BlockGenerative";
    string description = "On-chain generative coded art with on-chain trait intelligence. This is a Dynamic NFT where traits and visual representation evolve over time.";
    string name = "Sky";

    bool _revealed;

    function setArtAddr(address addr) external virtual onlyOwner {
        _artAddr = addr;
    }

    function setArtFactoryAddr(address addr) external virtual onlyOwner {
        _artFactoryAddr = addr;
    }

    function setTraitsAddr(address addr) external virtual onlyOwner {
        _traitsAddr = addr;
    }

    function setPreviewerAddr(address addr) external virtual onlyOwner {
        _previewerAddr = addr;
    }

    function setRendererAddr(address addr) external virtual onlyOwner {
        _rendererAddr = addr;
    }

    function setRevealed(bool revealed) external virtual override onlyOwner{
        _revealed = revealed;
    }

    function genMetadata(string memory tokenSeed, uint256 tokenId) external view virtual override returns (string memory) {
        require(address(_artAddr) != address(0), "No art address");
        require(address(_artFactoryAddr) != address(0), "No art factory address");
        require(address(_previewerAddr) != address(0), "No preview address");
        require(address(_traitsAddr) != address(0), "No traits address");

        IArtData artData = IArtData(_artAddr);
        IArtFactory artFactory = IArtFactory(_artFactoryAddr);

        IArtData.ArtProps memory artProps = artData.getProps();
        BaseAttributes memory atts = artFactory.calcAttributes(tokenSeed, tokenId);

        IRenderer previewer = IRenderer(_previewerAddr);
        string memory previewImage = previewer.render(tokenSeed, tokenId, atts, true, artProps);

        string memory render;
        if(address(_rendererAddr) != address(0)) {
            IRenderer renderer = IRenderer(_rendererAddr);
            render = renderer.render(tokenSeed, tokenId, atts, false, artProps);
        }
        else {
            render = previewImage;
        }

        string memory attrOutput;

        if (address(_traitsAddr) != address(0)) {
            IMetadataTraits traits = IMetadataTraits(_traitsAddr);
            attrOutput = traits.getTraits(atts, artData);
        } else {
            attrOutput = "";
        }

        string memory json = Base64.encode(abi.encodePacked(
                abi.encodePacked(
                    '{"name":"', getTokenName(tokenId),
                    '","description":"', getDescription(tokenId),
                    '","attributes":', attrOutput,
                    ',"image":"', previewImage,
                    '","animation_url":"', render
                ),
                abi.encodePacked(
                    '","external_url":"', getExternalUrl(), '"}'
                )) );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function getTokenName(uint256 tokenId) public view virtual returns (string memory) {
        return string.concat(name, " #", tokenId.toString());
    }

    function setName(string memory text) external virtual onlyOwner {
        name = text;
    }

    function getDescription(uint256) public view virtual returns (string memory) {
        return description;
    }

    function setDescription(string memory text) external virtual onlyOwner {
        description = text;
    }

    function getExternalUrl() public view virtual returns (string memory) {
        return _externalUri;
    }

    function setExternalUrl(string memory uri) external virtual onlyOwner {
        _externalUri = uri;
    }

}