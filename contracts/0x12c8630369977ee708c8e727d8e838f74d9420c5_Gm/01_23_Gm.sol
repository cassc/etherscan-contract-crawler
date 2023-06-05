// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {IBaseERC721Interface, ConfigSettings} from "gwei-slim-nft-contracts/contracts/base/ERC721Base.sol";
import {ERC721Delegated} from "gwei-slim-nft-contracts/contracts/base/ERC721Delegated.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {GmRenderer} from "./GmRenderer.sol";
import {Base64} from "base64-sol/base64.sol";

/**
                                                    
        GGGGGGGGGGGGGMMMMMMMM               MMMMMMMM
     GGG::::::::::::GM:::::::M             M:::::::M
   GG:::::::::::::::GM::::::::M           M::::::::M
  G:::::GGGGGGGG::::GM:::::::::M         M:::::::::M
 G:::::G       GGGGGGM::::::::::M       M::::::::::M
G:::::G              M:::::::::::M     M:::::::::::M
G:::::G              M:::::::M::::M   M::::M:::::::M
G:::::G    GGGGGGGGGGM::::::M M::::M M::::M M::::::M
G:::::G    G::::::::GM::::::M  M::::M::::M  M::::::M
G:::::G    GGGGG::::GM::::::M   M:::::::M   M::::::M
G:::::G        G::::GM::::::M    M:::::M    M::::::M
 G:::::G       G::::GM::::::M     MMMMM     M::::::M
  G:::::GGGGGGGG::::GM::::::M               M::::::M
   GG:::::::::::::::GM::::::M               M::::::M
     GGG::::::GGG:::GM::::::M               M::::::M
        GGGGGG   GGGGMMMMMMMM               MMMMMMMM
                                                    
 */

/// @author twitter.com/brxckinridge
/// @author twitter.com/isiain
/// @notice gm
contract Gm is ERC721Delegated {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private currentTokenId;
    uint256 public immutable maxSupply;
    uint256 public salePrice;
    GmRenderer public renderer;
    mapping(uint256 => bytes32) private mintSeeds;
    mapping(uint256 => bool) private hasHadCoffee;
    event DrankCoffee(uint256 indexed tokenId, address indexed actor);

    constructor(
        address baseFactory,
        address _rendererAddress,
        uint256 _maxSupply
    )
        ERC721Delegated(
            baseFactory,
            "gm",
            "gm",
            ConfigSettings({
                royaltyBps: 1000,
                uriBase: "",
                uriExtension: "",
                hasTransferHook: false
            })
        )
    {
        renderer = GmRenderer(_rendererAddress);
        maxSupply = _maxSupply;
    }

    /// @notice drinks coffee and updates the seed, only able to be called once
    /// @param tokenId The token ID for the token
    function drinkCoffee(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Needs to own");
        require(!hasHadCoffee[tokenId], "Already had coffee");
        hasHadCoffee[tokenId] = true;
        mintSeeds[tokenId] = _generateSeed(tokenId);
        emit DrankCoffee(tokenId, msg.sender);
    }

    /// @notice sets the sale price for Gm
    /// @param newPrice, the new price to mint new gms
    function setSalePrice(uint256 newPrice) public onlyOwner {
        salePrice = newPrice;
    }

    /// @notice returns number of mints left before sell out
    function mintsLeft() external view returns (uint256) {
        return maxSupply - currentTokenId.current();
    }

    /// @notice mints (count) new gms
    /// @param count, the number of gms to mint
    function mint(uint256 count) public payable {
        require(currentTokenId.current() + count <= maxSupply, "Gm: mint would exceed max supply");
        require(salePrice != 0, "Gm: sale not started");
        require(count <= 10, "Gm: cannot mint more than 10 in one transaction");
        require(msg.value == salePrice * count, "Gm: wrong sale price");

        for (uint256 i = 0; i < count; i++) {
            mintSeeds[currentTokenId.current()] = _generateSeed(
                currentTokenId.current()
            );
            _mint(msg.sender, currentTokenId.current());
            currentTokenId.increment();
        }
    }

    /// @notice burns the gm
    /// @param tokenId, the token id of be burned
    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Gm: only approved or owner can burn"
        );
        _burn(tokenId);
    }

    /// @notice withdraws the eth funds from the contract to the owner
    function withdraw() external onlyOwner {
        // No need for gas limit to trusted address.
        AddressUpgradeable.sendValue(payable(_owner()), address(this).balance);
    }

    /// @notice returns the base64 encoded svg
    /// @param data, bytes representing the svg
    function svgBase64Data(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(data)
                )
            );
    }

    /// @notice returns the base64 data uri metadata json
    /// @param tokenId, the token id of the gm
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory json;
        (bytes memory tokenData, bytes memory name, bytes memory bgColor, bytes memory fontColor, bytes memory filter) = renderer.svgRaw(
            mintSeeds[tokenId]
        );

        bytes memory caff;
        if (hasHadCoffee[tokenId]) {
            caff = "Yes";
        } else {
            caff = "No";
        }

        bytes memory attributes = abi.encodePacked('"attributes": [',
            '{"trait_type":"style","value":"',
            name,
            '"},{"trait_type":"background color","value":"',
            bgColor,
            '"},{"trait_type":"font color","value":"',
            fontColor,
            '"},{"trait_type":"caffeinated","value":"',
            caff,
            '"},{"trait_type":"effect","value":"',
            filter,
            '"}]');

        json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"description": "gm-onchain is a collection of 6969 randomly generated, onchain renderings of our favorite crypto phrase. enjoy.",',
                        '"title": "gm ',
                        StringsUpgradeable.toString(tokenId),
                        '", "image": "',
                        svgBase64Data(tokenData),
                        '",',
                        attributes,
                        '}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /// @notice returns the seed for the tokenId
    /// @param tokenId, the token id of the gm
    function seed(uint256 tokenId) external view returns (bytes32) {
        return mintSeeds[tokenId];
    }

    /// @notice generates a pseudo random seed
    /// @param tokenId, the token id of the gm
    function _generateSeed(uint256 tokenId) private view returns (bytes32) {
        return
            keccak256(abi.encodePacked(
                            msg.sender,
                            tx.gasprice,
                            tokenId,
                            block.number,
                            block.timestamp,
                            blockhash(block.number - 1)
                    )
            );
    }
}