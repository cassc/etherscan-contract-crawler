// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console2.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/utils/Base64.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./interfaces/IBlueishMetadata.sol";
import "./interfaces/IBlueishRenderer.sol";

/// @title blueishOnChainMetadata
/// @author blueish.eth
/// @notice This contract provides metadata for a basic on-chain rendered ERC721
/// @dev This contract provides metadata for a basic on-chain rendered ERC721

contract BlueishOnChainMetadata is IBlueishMetadata, Ownable {
    IBlueishRenderer public renderer;

    constructor(address _renderer) {
        renderer = IBlueishRenderer(_renderer);
    }

    function contractURI() public pure override returns (string memory) {
          string memory baseURL = "data:application/json;base64,";

        string memory json = string(
            abi.encodePacked(
                '{"name": "blueishNFT", "description": "blueishNFT is a beginner level template for end to end Solidity smart contract development and on-chain art", "external_link":"https://github.com/blueishdoteth/blueishNFT","image":"https://gateway.pinata.cloud/ipfs/QmYGiiTiY4aoRXem3HbQqbwQrASwkarGjeu2xsnGUvKyxr"}'
            )
        );

        string memory jsonBase64EncodedMetadata = Base64.encode(bytes(json));
        return string(abi.encodePacked(baseURL, jsonBase64EncodedMetadata));
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory baseURL = "data:application/json;base64,";
        string memory svg = renderer.render(id);
        string memory encodedSVG = Base64.encode(bytes(svg));

        string memory imgURI = string(
            abi.encodePacked("data:image/svg+xml;base64,", encodedSVG)
        );

        string memory json = string(
            abi.encodePacked(
                '{"name": "blueishNFT", "description": "blueishNFT is a beginner level template for end to end Solidity smart contract development and on-chain art", "image":"',
                imgURI,
                '"}'
            )
        );
        string memory jsonBase64EncodedMetadata = Base64.encode(bytes(json));
        return string(abi.encodePacked(baseURL, jsonBase64EncodedMetadata));
    }

    function setRenderer(address _renderer) public onlyOwner {
        renderer = IBlueishRenderer(_renderer);
    }
}